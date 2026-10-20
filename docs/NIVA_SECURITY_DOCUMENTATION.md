# NIVA Security & Access Control Documentation

This document provides a thorough analysis of the security architecture, access controls, data validation policies, and defensive hardening measures implemented across the NIVA application.

---

## Security Philosophy & Core Principles

1. **Principle of Least Privilege**: Users can access only their own private data and public community discovery listings. Internal moderation reports, administrative roles, and private user credentials are strictly locked down.
2. **Zero-Trust Client Operations**: The client application is never trusted to perform privileged mutations (such as calculating or altering its own `trustScore`, changing account roles, or bypassing connection validation).
3. **Immutability of Historical Records**: Delivered messages, submitted reviews, and moderation reports are permanent and immutable.
4. **Defense in Depth**: Client-side form constraints, repository sanitization, and server-side Firestore Security Rules validate inputs simultaneously.
5. **Zero Secrets Exposure**: Keystore passwords, service accounts, and private credentials are excluded from the repository.

---

## 1. Firebase Authentication Hardening

* **Email & Password Security**:
  * Passwords must be at least 6 characters and are verified locally for matching confirmation prior to dispatch.
  * Passwords are encrypted in transit via TLS and hashed on Google Cloud infrastructure. Passwords never touch Firestore documents.
* **Display Name Sanitization**:
  * User names are trimmed and capped to 60 characters to prevent UI layout distortion or buffer manipulation.
* **Password Reset Rate Limiting**:
  * Password reset uses Firebase Authentication's built-in token expiration and rate-limiting infrastructure.
* **Authentication State Stream**:
  * `AuthGate` listens to `FirebaseAuth.instance.authStateChanges()` to dynamically route unauthenticated users away from private screens.

---

## 2. Firestore Security Rules Matrix

The table below outlines the access policy enforced on Google Cloud Firestore servers via `firestore.rules`:

| Collection | Read Permission | Create Permission | Update Permission | Delete Permission |
| :--- | :--- | :--- | :--- | :--- |
| `/users/{userId}` | Authenticated users | `auth.uid == userId`<br>(no email, trust=100, role='member') | Owner only<br>(immutable: trust, role, createdAt) | **DENIED** |
| `/needs/{needId}` | Authenticated users | `auth.uid == data.userId`<br>(title <= 120, desc <= 1000) | Author only<br>(immutable: userId, createdAt) | **DENIED** |
| `/connection_requests/{requestId}` | Participants only (`fromUserId` or `toUserId`) | `auth.uid == data.fromUserId`<br>(no self-request, status='pending') | Recipient only (`toUserId`)<br>(only when status='pending') | **DENIED** |
| `/chats/{chatId}` | Participants only (`participantIds`) | Participant in array<br>(exactly 2 distinct users) | Participants only<br>(immutable: participantIds, createdAt) | **DENIED** |
| `/messages/{messageId}` | Participants only (`senderId` or `receiverId`) | Sender (`auth.uid == senderId`)<br>(both users in chat, text <= 2000) | **DENIED** | **DENIED** |
| `/notifications/{notificationId}` | Recipient only (`recipientId`) | Sender (`auth.uid == senderId`)<br>(no self-notification, type whitelist) | Recipient only<br>(strictly `isRead` field only) | Recipient only |
| `/reviews/{reviewId}` | Authenticated users | Reviewer (`auth.uid == reviewerId`)<br>(no self-review, rating 1-5) | **DENIED** | **DENIED** |
| `/blocked_users/{blockId}` | Blocker only (`blockerId`) | Blocker only (`auth.uid == blockerId`)<br>(no self-blocking) | **DENIED** | Blocker only |
| `/reports/{reportId}` | **DENIED TO ALL USERS** | Reporter (`auth.uid == reporterId`)<br>(no self-report, reason whitelisted) | **DENIED** | **DENIED** |

---

## 3. Detailed Security Mechanisms

### A. Ownership Verification
Every user write operation asserts `request.auth != null` and validates that the record's user ID matches `request.auth.uid`. Spoofing another user's identity to create needs, send requests, or post messages is rejected at the database engine level.

### B. Chat & Message Participant Validation
* A message can ONLY be created if:
  1. `request.auth.uid == request.resource.data.senderId`
  2. `senderId != receiverId`
  3. The `chatId` points to an existing `/chats` document: `exists(/databases/$(database)/documents/chats/$(request.resource.data.chatId))`
  4. Both `senderId` and `receiverId` exist in the parent chat's `participantIds` array:
     ```javascript
     request.auth.uid in get(/databases/$(database)/documents/chats/$(request.resource.data.chatId)).data.participantIds
     && request.resource.data.senderId in get(/databases/$(database)/documents/chats/$(request.resource.data.chatId)).data.participantIds
     && request.resource.data.receiverId in get(/databases/$(database)/documents/chats/$(request.resource.data.chatId)).data.participantIds
     ```
* Messages cannot be intercepted or read by any user outside of `participantIds`.

### C. TrustScore Protection & Zero-Client Manipulation
* In previous iterations or naive implementations, clients might attempt to update user `trustScore` directly upon submitting reviews.
* In NIVA's hardened architecture:
  * `/users/{userId}` update rules strictly require `request.resource.data.trustScore == resource.data.trustScore`.
  * Clients **cannot** alter `trustScore`.
  * `ReviewRepository.submitReview()` does NOT perform client-side profile mutations.
  * Trust scores are managed solely through authenticated server functions or administrative moderation.

### D. Moderation Report Write-Only Policy
* `/reports` collection is strictly **write-only** for regular users (`allow read: if false;`).
* A user can submit a report, but cannot query or read reports filed by other users or about themselves.
* Reports use deterministic document IDs (`${reporterId}_${reportedUserId}_${referenceId}`) which eliminates the need for read-before-write permission checks in client repositories.

### E. Block Enforcement
* Blocking a user creates a `/blocked_users/${blockerId}_${blockedId}` record.
* Client repositories (`MatchingService`, `SearchService`, and `ChatRepository`) inspect this collection to exclude blocked users from discovery lists and candidate matching pools.
* In `ConversationScreen`, if a block status is detected, the message composer is disabled and replaced with a prominent safety alert.

### F. Input Sanitization & Boundary Constraints
* **Titles**: 1–120 characters. Empty titles or oversized titles are rejected.
* **Descriptions**: Max 1000 characters for needs/capabilities; max 500 characters for reports.
* **Messages**: 1–2000 characters.
* **Ratings**: Integer strictly constrained to `rating >= 1 && rating <= 5`.
* **Whitelisted Enums**: Statuses (`active`, `completed`, `cancelled`), Intent types (`need`, `help`), and Report reasons (`spam`, `harassment`, `inappropriate`, `scam`, `other`) are strictly whitelisted in Firestore rules.

### G. Server Timestamps & Immutability
* All temporal tracking uses `FieldValue.serverTimestamp()` (`request.time` in security rules). This prevents clients from spoofing timestamps, artificially boosting listing recency, or falsifying delivery order.
* Immutable fields (such as `createdAt`, `userId`, `participantIds`) are guarded by rule assertions checking `request.resource.data.field == resource.data.field`.

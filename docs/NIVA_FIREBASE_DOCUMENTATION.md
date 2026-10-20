# NIVA Firebase & Firestore Architecture Documentation

This document specifies the complete Cloud Firestore data architecture, collection schemas, access control policies, and indexing rules for the NIVA application. Every rule and field constraint has been verified directly against `firestore.rules` and the production repository implementations.

---

## Architecture Diagram

```
+--------------------------------------------------------------+
|                     NIVA Flutter Client                      |
+--------------------------------------------------------------+
           |                                       |
    [Firebase Auth]                         [Cloud Firestore]
           |                                       |
  - Email/Password Auth                 +----------+----------+
  - Auth State Streams                  |                     |
  - Token Management             One-Shot Reads        Real-Time Streams
                                (Explore, Home,        (Active Messages,
                                 Chat List)             Notifications)
                                        |                     |
                                +-------v---------------------v-------+
                                |      Firestore Security Rules       |
                                |  - Ownership Verification           |
                                |  - Participant Validation           |
                                |  - Field Length & Type Enforcement  |
                                |  - Write-Only Reports               |
                                |  - Protected TrustScore             |
                                +-------------------------------------+
```

---

## Firestore Collections Specification

### 1. `users` Collection

* **Path**: `/users/{userId}`
* **Purpose**: Stores public user profile data, verification status, capability tags, and community trust score.
* **Document ID**: Matches Firebase Auth UID (`request.auth.uid`).

#### Field Schema

| Field Name | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `userId` | string | Yes | Unique identifier matching Firebase Auth UID. |
| `name` | string | Yes | Community display name (1–60 chars). |
| `headline` | string | No | Short professional or personal tagline. |
| `bio` | string | No | Detailed user biography. |
| `skills` | list[string] | No | List of capability and expertise keywords. |
| `location` | string | No | Geographical location or "Remote". |
| `trustScore` | integer | Yes | Community trust metric (default: 100). |
| `role` | string | Yes | Account role (`'member'`, `'admin'`). Defaults to `'member'`. |
| `createdAt` | Timestamp | Yes | Server timestamp of account initialization. |
| `updatedAt` | Timestamp | No | Server timestamp of profile updates. |

#### Access Control Rules (`firestore.rules`)
* **Read**: Any authenticated user (`request.auth != null`).
* **Create**: Only the authenticated user where `request.auth.uid == userId`. Must initialize with `trustScore: 100`, `role: 'member'`, `createdAt: request.time`, and must NOT contain private email (`!('email' in request.resource.data)`).
* **Update**: Only the account owner (`request.auth.uid == userId`). `trustScore`, `role`, and `createdAt` are strictly IMMUTABLE by the client. Private email cannot be added.
* **Delete**: Denied (`allow delete: if false`).

---

### 2. `needs` Collection

* **Path**: `/needs/{needId}`
* **Purpose**: Primary marketplace listings representing active needs ("I Need") or offered capabilities ("I Can Help").

#### Field Schema

| Field Name | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `needId` | string | Yes | Auto-generated document ID. |
| `userId` | string | Yes | Author's Firebase Auth UID. |
| `authorName` | string | No | Cached author display name for fast list rendering. |
| `type` | string | Yes | Intent classification: `'need'` or `'help'`. |
| `title` | string | Yes | Listing title (1–120 characters). |
| `description` | string | No | Detailed description (max 1000 characters). |
| `category` | string | Yes | Category classification (e.g., Services, Education, Technology). |
| `skills` | list[string] | No | Associated skill tags for matching. |
| `location` | string | No | Location constraint (e.g., "Remote", "Bengaluru"). |
| `budget` | string | No | Budget or compensation note (e.g., "Paid", "Volunteer"). |
| `urgency` | string | Yes | Urgency level: `'high'`, `'medium'`, `'flexible'`. |
| `availability` | string | No | Availability description (e.g., "Available today"). |
| `status` | string | Yes | Listing status: `'active'`, `'completed'`, `'cancelled'`. |
| `createdAt` | Timestamp | Yes | Server timestamp of creation. |
| `updatedAt` | Timestamp | No | Server timestamp of last update. |

#### Access Control Rules (`firestore.rules`)
* **Read**: Any authenticated user (`request.auth != null`).
* **Create**: Authenticated author (`request.resource.data.userId == request.auth.uid`). Title must be 1–120 chars; description <= 1000 chars; type in `['need', 'help']`; status in `['active', 'completed', 'cancelled']`.
* **Update**: Author only (`resource.data.userId == request.auth.uid`). `userId` and `createdAt` are immutable; `type` must remain unchanged; title and status validation enforced.
* **Delete**: Denied by default (`allow delete: if false`). Status transitions to `'cancelled'` are used instead.

---

### 3. `connection_requests` Collection

* **Path**: `/connection_requests/{requestId}`
* **Purpose**: Manages 1-to-1 connection invitations initiated between users.

#### Field Schema

| Field Name | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `requestId` | string | Yes | Unique request ID. |
| `fromUserId` | string | Yes | Sender's Firebase Auth UID. |
| `toUserId` | string | Yes | Recipient's Firebase Auth UID. |
| `needId` | string | Yes | Associated need document ID. |
| `status` | string | Yes | Request state: `'pending'`, `'accepted'`, `'declined'`. |
| `createdAt` | Timestamp | Yes | Server timestamp of invitation dispatch. |
| `updatedAt` | Timestamp | No | Server timestamp of response. |

#### Access Control Rules (`firestore.rules`)
* **Read**: Only the sender or recipient (`request.auth.uid in [resource.data.fromUserId, resource.data.toUserId]`).
* **Create**: Authenticated sender (`request.resource.data.fromUserId == request.auth.uid`). Cannot request oneself (`fromUserId != toUserId`). Initial status must be `'pending'`.
* **Update**: Only the recipient (`resource.data.toUserId == request.auth.uid`). Allowed only when existing status is `'pending'`. Core fields (`fromUserId`, `toUserId`, `needId`, `createdAt`) are immutable.
* **Delete**: Denied (`allow delete: if false`).

---

### 4. `chats` Collection

* **Path**: `/chats/{chatId}`
* **Purpose**: Top-level directory of active 1-to-1 chat conversations.
* **Document ID**: Deterministic canonical ID (`[user1, user2]..sort().join('_')`).

#### Field Schema

| Field Name | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `id` | string | Yes | Canonical deterministic chat ID. |
| `participantIds` | list[string] | Yes | Array containing exactly both participant UIDs. |
| `needId` | string | No | Reference to associated need. |
| `connectionRequestId`| string | No | Reference to accepted connection request. |
| `lastMessage` | string | No | Snippet of the latest delivered message. |
| `lastMessageAt` | Timestamp | No | Server timestamp of latest message. |
| `createdAt` | Timestamp | Yes | Creation timestamp. |
| `updatedAt` | Timestamp | No | Last conversation activity timestamp. |

#### Access Control Rules (`firestore.rules`)
* **Read**: Only participants (`request.auth.uid in resource.data.participantIds`).
* **Create**: Authenticated participant (`request.auth.uid in request.resource.data.participantIds`). `participantIds` must contain exactly 2 distinct user IDs.
* **Update**: Only participants. `participantIds` and `createdAt` are immutable.
* **Delete**: Denied.

---

### 5. `messages` Collection

* **Path**: `/messages/{messageId}`
* **Purpose**: Stores individual messages delivered in conversations.

#### Field Schema

| Field Name | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `id` | string | Yes | Unique auto-generated message ID. |
| `chatId` | string | Yes | Reference to parent canonical chat ID. |
| `senderId` | string | Yes | Sender's Firebase Auth UID. |
| `receiverId` | string | Yes | Recipient's Firebase Auth UID. |
| `text` | string | Yes | Text content (1–2000 characters). |
| `createdAt` | Timestamp | Yes | Server timestamp of delivery. |

#### Access Control Rules (`firestore.rules`)
* **Read**: Only participants (`request.auth.uid in [resource.data.senderId, resource.data.receiverId]`).
* **Create**: Authenticated sender (`request.resource.data.senderId == request.auth.uid`). Cannot send to oneself (`senderId != receiverId`). Sender and receiver must both belong to the referenced chat (`chatId` exists in `/chats`, and both users are in `participantIds`). Text must be 1–2000 characters.
* **Update / Delete**: Denied (`allow update, delete: if false`). Messages are immutable once delivered.

---

### 6. `notifications` Collection

* **Path**: `/notifications/{notificationId}`
* **Purpose**: In-app notifications for connection invitations, acceptances, and chat messages.

#### Field Schema

| Field Name | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `id` | string | Yes | Unique notification ID. |
| `recipientId` | string | Yes | Recipient's Firebase Auth UID. |
| `senderId` | string | Yes | Initiator's Firebase Auth UID. |
| `type` | string | Yes | Notification type: `'connection_request'`, `'connection_accepted'`, `'new_message'`. |
| `title` | string | No | Brief notification title (max 80 chars). |
| `body` | string | No | Descriptive body text (max 200 chars). |
| `referenceId` | string | Yes | ID of referenced item (e.g., requestId, chatId). |
| `isRead` | bool | Yes | Read state flag (defaults to `false`). |
| `createdAt` | Timestamp | Yes | Creation timestamp. |

#### Access Control Rules (`firestore.rules`)
* **Read**: Only the recipient (`request.auth.uid == resource.data.recipientId`).
* **Create**: Authenticated sender (`request.resource.data.senderId == request.auth.uid`). Cannot notify oneself. Type must be whitelisted. `isRead` must be `false`. Title <= 80 chars; body <= 200 chars.
* **Update**: Recipient only. Update restricted strictly to mutating `isRead`: `request.resource.data.diff(resource.data).affectedKeys().hasOnly(['isRead'])`.
* **Delete**: Recipient can dismiss/delete their own notifications (`request.auth.uid == resource.data.recipientId`).

---

### 7. `reviews` Collection

* **Path**: `/reviews/{reviewId}`
* **Purpose**: Verified post-collaboration reviews and star ratings.

#### Field Schema

| Field Name | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `reviewId` | string | Yes | Unique review ID. |
| `reviewerId` | string | Yes | Reviewer's Firebase Auth UID. |
| `revieweeId` | string | Yes | Reviewed user's Firebase Auth UID. |
| `needId` | string | Yes | ID of need that was collaborated on. |
| `connectionRequestId`| string | Yes | ID of connection request authorizing this review. |
| `rating` | integer | Yes | Rating value from 1 to 5. |
| `reviewText` | string | No | Qualitative feedback (max 1000 chars). |
| `createdAt` | Timestamp | Yes | Creation timestamp. |

#### Access Control Rules (`firestore.rules`)
* **Read**: Any authenticated user (`request.auth != null`).
* **Create**: Authenticated reviewer (`request.resource.data.reviewerId == request.auth.uid`). Cannot review oneself (`reviewerId != revieweeId`). Must reference an existing connection request and need. `rating` must be an integer between 1 and 5. Text <= 1000 chars.
* **Update / Delete**: Denied (`allow update, delete: if false`). Reviews are immutable.

---

### 8. `blocked_users` Collection

* **Path**: `/blocked_users/{blockId}`
* **Purpose**: Records active communication blocks between users.
* **Document ID**: Deterministic format `${blockerId}_${blockedId}`.

#### Field Schema

| Field Name | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `blockId` | string | Yes | Deterministic ID `${blockerId}_${blockedId}`. |
| `blockerId` | string | Yes | User initiating the block. |
| `blockedId` | string | Yes | User being blocked. |
| `createdAt` | Timestamp | Yes | Timestamp block was established. |

#### Access Control Rules (`firestore.rules`)
* **Read**: Blocker only (`request.auth.uid == resource.data.blockerId`).
* **Create**: Blocker only (`request.resource.data.blockerId == request.auth.uid`). Cannot block oneself.
* **Update**: Denied.
* **Delete**: Blocker can unblock (`request.auth.uid == resource.data.blockerId`).

---

### 9. `reports` Collection

* **Path**: `/reports/{reportId}`
* **Purpose**: Trust & Safety moderation violation reports.
* **Document ID**: Deterministic format `${reporterId}_${reportedUserId}_${refId}`.

#### Field Schema

| Field Name | Type | Required | Description |
| :--- | :---: | :---: | :--- |
| `reportId` | string | Yes | Deterministic composite ID. |
| `reporterId` | string | Yes | Reporting user's Firebase Auth UID. |
| `reportedUserId`| string | Yes | Accused user's Firebase Auth UID. |
| `reason` | string | Yes | Violation reason: `'spam'`, `'harassment'`, `'inappropriate'`, `'scam'`, `'other'`. |
| `description` | string | No | Optional incident description (max 500 chars). |
| `referenceId` | string | No | Associated need, chat, or request ID. |
| `status` | string | Yes | Moderation triage status (must initialize to `'submitted'`). |
| `createdAt` | Timestamp | Yes | Creation timestamp. |

#### Access Control Rules (`firestore.rules`)
* **Read**: **DENIED to all users** (`allow read: if false`). Managed strictly by admin SDK or Firebase Console.
* **Create**: Authenticated reporter (`request.resource.data.reporterId == request.auth.uid`). Cannot report oneself. Reason must be in whitelist. Description <= 500 chars. Status must be `'submitted'`.
* **Update / Delete**: **DENIED** (`allow update, delete: if false`). Reports are write-only.

---

## Indexing & Query Optimization

1. **Composite Indexes**:
   * `needs`: `where('type', '==', 'help')` + `where('status', '==', 'active')` + `orderBy('createdAt', 'desc')`
   * `chats`: `where('participantIds', 'array-contains', userId)` + `orderBy('updatedAt', 'desc')`
   * `notifications`: `where('recipientId', '==', userId)` + `orderBy('createdAt', 'desc')`
2. **Fallback Query Support**:
   * In `ChatRepository` and `SearchService`, if a composite index is building or absent, queries automatically fall back to single-field filtered queries and execute in-memory sorting, ensuring zero user-facing crash scenarios.
3. **Offline Persistence**:
   * Cloud Firestore offline persistence is enabled by default in the FlutterFire SDK, providing cached reads for immediate app rendering when offline.

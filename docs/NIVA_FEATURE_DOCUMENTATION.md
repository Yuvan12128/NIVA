# NIVA Detailed Feature Documentation

This document provides a comprehensive technical breakdown of every feature implemented in the NIVA application. Every feature, flow, and Firestore schema documented here is verified directly against the production codebase and `firestore.rules`.

---

## Table of Implemented Features

1. [Dual-Facet Need & Capability Publication](#1-dual-facet-need--capability-publication)
2. [Algorithmic Candidate Matching (V1 Rule Engine)](#2-algorithmic-candidate-matching-v1-rule-engine)
3. [Universal Exploration & Debounced Search](#3-universal-exploration--debounced-search)
4. [Multi-Criteria Discovery Filtering](#4-multi-criteria-discovery-filtering)
5. [1-to-1 Connection Request Lifecycle](#5-1-to-1-connection-request-lifecycle)
6. [Real-Time Private Messaging System](#6-real-time-private-messaging-system)
7. [Activity & In-App Notification System](#7-activity--in-app-notification-system)
8. [Verified Post-Collaboration Review System](#8-verified-post-collaboration-review-system)
9. [Trust & Safety Moderation (Report System)](#9-trust--safety-moderation-report-system)
10. [Mutual Block & Protection System](#10-mutual-block--protection-system)
11. [Zero-Vanity Utility User Profile](#11-zero-vanity-utility-user-profile)
12. [Authentication & Profile Initialization Flow](#12-authentication--profile-initialization-flow)

---

### 1. Dual-Facet Need & Capability Publication

#### What it does
Allows users to publish either an active requirement (*"I Need"*) or a capability/skill they offer to the community (*"I Can Help"*). Once published, these items become searchable in Explore and candidates in the Matching Engine.

#### Why it exists
Traditional platforms separate gig services from job boards. NIVA unifies both directions into a single two-way discovery interface where people can both ask for assistance and offer their own skills.

#### User Flow
1. User taps the central "+" floating action button on `MainNavigationShell`.
2. `CreateNeedSheet` slides up presenting the intent selector ("I Have a Need" vs "I Can Help").
3. User selects intent, fills in title, description, category, skills, location, urgency, and budget.
4. User taps "Publish".
5. Document is written to Firestore; a success confirmation screen displays with a direct trigger to view matches.

#### Important UI Components
* `CreateNeedSheet` (`lib/features/navigation/presentation/widgets/create_need_sheet.dart`)
* `NivaButton` with built-in loading states
* Category selector Dropdown and quick example inspiration chips

#### Backend & Firestore Interaction
* **Repository**: `NeedRepository` (`lib/features/needs/data/need_repository.dart`)
* **Collection**: `/needs/{needId}`
* **Document Structure**:
```json
{
  "needId": "string (doc id)",
  "userId": "string (author uid)",
  "authorName": "string",
  "type": "string ('need' | 'help')",
  "title": "string (1-120 chars)",
  "description": "string (max 1000 chars)",
  "category": "string (Education | Technology | Creative | Hardware | Career | Communities | Services | General)",
  "skills": ["string"],
  "location": "string (e.g. 'Remote', 'Chennai')",
  "budget": "string? (e.g. 'Paid', 'Volunteer')",
  "urgency": "string ('high' | 'medium' | 'flexible')",
  "availability": "string? (e.g. 'Available today', 'Flexible')",
  "status": "string ('active' | 'completed' | 'cancelled')",
  "createdAt": "Timestamp (serverTimestamp)",
  "updatedAt": "Timestamp? (serverTimestamp)"
}
```

#### Security Considerations
* Firestore Security Rules verify:
  * User is authenticated (`request.auth != null`).
  * `userId` strictly matches `request.auth.uid`.
  * `type in ['need', 'help']`.
  * `title` is non-empty and `<= 120` characters.
  * `description` is `<= 1000` characters.
  * `status` is whitelisted (`'active'`, `'completed'`, `'cancelled'`).
  * Updates are restricted strictly to the original author.

#### Performance Considerations
* Bounded reads (max 20 per fetch); uses client-side form validation before triggering Firestore writes.

---

### 2. Algorithmic Candidate Matching (V1 Rule Engine)

#### What it does
Evaluates an active need and ranks potential "I Can Help" profiles using a deterministic multi-factor scoring formula (0–100%).

#### Why it exists
Eliminates manual hunting and endless scrolling by providing instant, scored recommendations tailored to the specific skills, urgency, and category of the user's need.

#### User Flow
1. User views an active need card in `RecentNeedsSection` or after creating a need.
2. User taps "Find Match".
3. `MatchingSheet` opens, queries active candidate profiles from Firestore, executes scoring, and presents ranked results.
4. User taps "Connect" to dispatch an immediate 1-to-1 connection request.

#### Important UI Components
* `MatchingSheet` (`lib/features/matching/presentation/widgets/matching_sheet.dart`)
* Match percentage indicator pill (e.g., `95% Match`)
* Matched skill chips and Trust Score badge

#### Scoring Breakdown
* **Skill Relevance**: 40% weight (Jaccard similarity between need skills and helper capabilities)
* **Location Relevance**: 20% weight (exact match = 100%, Remote fallback = 80%)
* **Availability / Urgency**: 15% weight
* **Category Relevance**: 15% weight
* **Trust Score**: 10% weight (proportional to helper's trust score)

#### Backend & Firestore Interaction
* **Service**: `MatchingService` (`lib/features/matching/data/matching_service.dart`)
* Queries active help documents from `/needs` (`where('type', '==', 'help')`, `where('status', '==', 'active')`, `limit: 20`).
* Queries `/blocked_users` to exclude any blocked individuals from results.

#### Security Considerations
* Matching never exposes private emails or internal tokens.
* Author cannot match with their own posts or with blocked users.

#### Performance Considerations
* Queries are capped to 20 candidate documents; matching calculation executes in-memory in `O(N)` time with microsecond latency.

---

### 3. Universal Exploration & Debounced Search

#### What it does
Provides a responsive discovery portal allowing users to search across People, Services, Communities, Opportunities, and Information.

#### Why it exists
Serves as the general discovery catalog for users who want to browse or explore opportunities beyond algorithmic matching.

#### User Flow
1. User navigates to Explore tab.
2. Types query into search bar; results filter live with a 300ms debounce.
3. User selects category tabs or suggestions (e.g., "Java tutor", "Laptop repair").
4. Discovery cards update instantly.
5. User taps "Connect" or "Match".

#### Important UI Components
* `ExploreScreen` (`lib/features/explore/presentation/explore_screen.dart`)
* `NivaSearchBar` (`lib/core/widgets/niva_search_bar.dart`)
* Quick Search suggestion chips and Trending Topic pills

#### Backend & Firestore Interaction
* **Service**: `SearchService` (`lib/features/explore/data/search_service.dart`)
* Queries `/needs` and `/users` collections.
* When offline, gracefully falls back to `seedDiscoveries` constant dataset.

#### Security Considerations
* Prevents NoSQL query injection by strictly sanitizing and lowercasing client queries.
* Hides blocked users and self-profiles from search cards.

#### Performance Considerations
* 300ms timer debounces keystrokes to prevent dispatching network queries on every letter typed.

---

### 4. Multi-Criteria Discovery Filtering

#### What it does
Allows users to refine search results using category filters, urgency ratings, location constraints (Remote vs In-Person), and a minimum Trust Score threshold slider.

#### Why it exists
Enables high-intent discovery by filtering out unverified candidates or non-local options when in-person assistance is required.

#### User Flow
1. User taps the Filter button on the search bar in `ExploreScreen`.
2. `FilterBottomSheet` slides up with interactive ChoiceChips and a Trust Score slider (20–100).
3. User modifies criteria and taps "Apply Filters".
4. Explore results update immediately according to the new filter state.

#### Important UI Components
* `FilterBottomSheet` (`lib/features/explore/presentation/widgets/filter_bottom_sheet.dart`)
* Minimum Trust Score Slider with real-time numeric readout
* ChoiceChip selectors for Urgency, Category, and Location

#### Backend & Firestore Interaction
* **Model**: `SearchFilter` (`lib/features/explore/data/search_filter_model.dart`)
* Filters are evaluated client-side across the fetched candidate set to avoid complex composite Firestore indexes.

#### Security Considerations
* Filter parameters are strongly typed and validated against immutable enum values.

#### Performance Considerations
* Built inside a `ConstrainedBox(maxWidth: 540)` ensuring clean presentation on all screen sizes with zero relayout penalties.

---

### 5. 1-to-1 Connection Request Lifecycle

#### What it does
Governs the connection lifecycle: creating requests, notifying recipients, accepting or declining connections, and automatically initializing private chat channels upon acceptance.

#### Why it exists
Prevents unwanted messaging or harassment by requiring mutual consent before opening a private messaging channel between two users.

#### User Flow
1. User A taps "Connect" on a discovery card or matching candidate.
2. Connection confirmation modal appears; user confirms.
3. Request document is created in `/connection_requests`.
4. User B receives an in-app notification in `NotificationsScreen`.
5. User B accepts: request status updates to `'accepted'`, and a unique 1-to-1 `/chats` document is initialized.

#### Important UI Components
* `NotificationsScreen` connection request card with Accept and Decline buttons
* Connect Confirmation Dialog

#### Backend & Firestore Interaction
* **Repository**: `ConnectionRequestRepository` (`lib/features/connect/data/connection_request_repository.dart`)
* **Collection**: `/connection_requests/{requestId}`
* **Document Structure**:
```json
{
  "requestId": "string",
  "fromUserId": "string (requester uid)",
  "toUserId": "string (recipient uid)",
  "needId": "string (associated need)",
  "status": "string ('pending' | 'accepted' | 'declined')",
  "createdAt": "Timestamp (serverTimestamp)",
  "updatedAt": "Timestamp? (serverTimestamp)"
}
```

#### Security Considerations
* Prevents self-connection (`fromUserId != toUserId`).
* Duplicate prevention: queries existing pending requests before creating new ones.
* Only `toUserId` can update the status to `'accepted'` or `'declined'`.
* Status update strictly requires current status to be `'pending'`.
* Core fields (`fromUserId`, `toUserId`, `needId`, `createdAt`) are immutable.

#### Performance Considerations
* Bounded queries with deterministic lookups.

---

### 6. Real-Time Private Messaging System

#### What it does
Provides end-to-end 1-to-1 messaging between connected users with deterministic chat channel IDs, real-time message stream listeners, and reverse scroll history.

#### Why it exists
Enables collaborators to discuss details, coordinate assistance, and exchange project specifications safely within the platform.

#### User Flow
1. User taps a conversation from `ChatScreen` or taps "Open Chat" from an accepted connection notification.
2. `ConversationScreen` opens, attaching a real-time listener to `/messages` for this conversation.
3. User types a message and taps Send.
4. Message is written to `/messages` and the parent `/chats/{chatId}` document's `lastMessage` and `updatedAt` are updated.

#### Important UI Components
* `ConversationScreen` (`lib/features/chat/presentation/conversation_screen.dart`)
* `ChatScreen` conversations directory (`lib/features/chat/presentation/chat_screen.dart`)
* Message bubble layout (`ListView.builder(reverse: true)`) with timestamps

#### Backend & Firestore Interaction
* **Repository**: `ChatRepository` (`lib/features/chat/data/chat_repository.dart`)
* **Collections**:
  * `/chats/{chatId}`
  * `/messages/{messageId}`
* **Document Structures**:
```json
// /chats/{chatId}
{
  "id": "string (e.g. 'userA_userB' sorted deterministically)",
  "participantIds": ["string", "string"],
  "needId": "string",
  "connectionRequestId": "string",
  "lastMessage": "string",
  "lastMessageAt": "Timestamp",
  "createdAt": "Timestamp",
  "updatedAt": "Timestamp"
}

// /messages/{messageId}
{
  "id": "string",
  "chatId": "string",
  "senderId": "string",
  "receiverId": "string",
  "text": "string (1-2000 chars)",
  "createdAt": "Timestamp (serverTimestamp)"
}
```

#### Security Considerations
* Deterministic canonical chat ID (`[user1, user2]..sort().join('_')`) prevents duplicate parallel chat channels.
* Security rules verify:
  * Only participants listed in `chat.participantIds` can read messages.
  * Message sender matches `request.auth.uid`.
  * Sender and receiver are distinct users.
  * Message text is non-empty and `<= 2000` characters.
  * Messages are strictly immutable once created.
  * If a block exists between the two users, sending messages is rejected.

#### Performance Considerations
* Real-time listener is strictly attached ONLY to the active conversation while `ConversationScreen` is mounted. Disposed immediately on screen pop.
* Query limit enforced (`limit: 40`).
* The chat list (`ChatScreen`) uses a one-shot read with pull-to-refresh rather than a persistent global listener, saving mobile battery and data.

---

### 7. Activity & In-App Notification System

#### What it does
Provides real-time notifications for incoming connection requests, accepted connections, and incoming messages.

#### Why it exists
Ensures users are immediately informed of responses to their needs or offers without requiring external push services when inside the app.

#### User Flow
1. When another user sends a request or accepts a connection, a notification document is written.
2. User's `NotificationsScreen` streams these updates.
3. Unread notification badges appear on `HomeHeader`.
4. User taps a notification to mark it read and navigate to the associated chat or request.

#### Important UI Components
* `NotificationsScreen` (`lib/features/notifications/presentation/notifications_screen.dart`)
* Bell badge icon on `HomeHeader`
* Relative time ago formatting (`Just now`, `5m ago`, `2h ago`)

#### Backend & Firestore Interaction
* **Repository**: `NotificationRepository` (`lib/features/notifications/data/notification_repository.dart`)
* **Collection**: `/notifications/{notificationId}`
* **Document Structure**:
```json
{
  "id": "string",
  "recipientId": "string",
  "senderId": "string",
  "type": "string ('connection_request' | 'connection_accepted' | 'new_message')",
  "title": "string (<= 80 chars)",
  "body": "string (<= 200 chars)",
  "referenceId": "string",
  "isRead": "bool",
  "createdAt": "Timestamp (serverTimestamp)"
}
```

#### Security Considerations
* Only `recipientId` can read their own notifications.
* Only the recipient can update the `isRead` boolean field.
* Security rules restrict updates strictly to the `isRead` field using `.affectedKeys().hasOnly(['isRead'])`.

#### Performance Considerations
* Real-time stream is scoped to the screen lifecycle and limited to 30 documents. Duplicate unread notifications for the same reference item and type are prevented before writing.

---

### 8. Verified Post-Collaboration Review System

#### What it does
Allows users to rate (1–5 stars) and review completed collaborations. Reviews contribute to platform safety and community accountability.

#### Why it exists
Establishes a verifiable reputation layer that discourages malicious behavior, spam, and unfulfilled commitments.

#### User Flow
1. Collaborators complete an interaction in `ConversationScreen`.
2. User selects "Review Connection" from the top menu.
3. `ReviewSheet` opens.
4. User selects 1–5 stars, writes constructive review text, and taps "Submit Review".
5. Review is saved to Firestore.

#### Important UI Components
* `ReviewSheet` (`lib/features/reviews/presentation/widgets/review_sheet.dart`)
* Interactive 5-star rating bar with descriptive text labels

#### Backend & Firestore Interaction
* **Repository**: `ReviewRepository` (`lib/features/reviews/data/review_repository.dart`)
* **Collection**: `/reviews/{reviewId}`
* **Document Structure**:
```json
{
  "reviewId": "string",
  "reviewerId": "string",
  "revieweeId": "string",
  "needId": "string",
  "connectionRequestId": "string",
  "rating": "int (1-5)",
  "reviewText": "string? (max 1000 chars)",
  "createdAt": "Timestamp (serverTimestamp)"
}
```

#### Security Considerations
* Reviews cannot be self-directed (`reviewerId != revieweeId`).
* Must link to an existing need and connection request.
* `rating` must be an integer between 1 and 5.
* Reviews are immutable once written; users cannot modify or delete submitted reviews.
* Crucial Security Hardening: Client-side code does NOT directly mutate user `trustScore`—protecting the platform against client-side score manipulation. Trust scoring is evaluated by trusted backend rules or server functions.

#### Performance Considerations
* Modal bottom sheet with constrained height and keyboard-aware inset padding.

---

### 9. Trust & Safety Moderation (Report System)

#### What it does
Provides a secure moderation reporting mechanism to report users for spam, harassment, inappropriate content, scams, or rule violations.

#### Why it exists
Protects the community against abusive actors and gives users immediate recourse when encountering unacceptable behavior.

#### User Flow
1. User taps "Report User" from the `ConversationScreen` safety menu or Profile.
2. `ReportSheet` opens.
3. User selects the violation reason (Spam, Harassment, Inappropriate, Scam, Other).
4. User enters optional description (max 500 characters) and submits.
5. Report is written to Firestore; user is offered an option to immediately block the reported user.

#### Important UI Components
* `ReportSheet` (`lib/features/safety/presentation/widgets/report_sheet.dart`)
* Radio group for violation reasons
* Confidentiality notice banner

#### Backend & Firestore Interaction
* **Repository**: `SafetyRepository` (`lib/features/safety/data/safety_repository.dart`)
* **Collection**: `/reports/{reportId}`
* **Document Structure**:
```json
{
  "reportId": "string (deterministic: reporterId_reportedUserId_refId)",
  "reporterId": "string",
  "reportedUserId": "string",
  "reason": "string ('spam' | 'harassment' | 'inappropriate' | 'scam' | 'other')",
  "description": "string? (max 500 chars)",
  "referenceId": "string",
  "status": "string ('submitted')",
  "createdAt": "Timestamp (serverTimestamp)"
}
```

#### Security Considerations
* **Write-Only Collection**: Users can create reports, but CANNOT read, update, or delete any reports (`allow read, update, delete: if false;`).
* Deterministic ID format (`reporterId_reportedUserId_refId`) prevents pre-read query requirements, eliminating permission-denied errors during submission.
* Cannot report oneself.
* Status must initialize to `'submitted'`.
* Description is constrained to `<= 500` characters.

#### Performance Considerations
* Direct write with deterministic ID requires zero prior read round trips.

---

### 10. Mutual Block & Protection System

#### What it does
Allows users to block malicious or unwanted contacts. Once blocked, all communication, discovery cards, matching results, and chat messages between the two users are instantly severed.

#### Why it exists
Guarantees user autonomy and privacy against persistent harassers or unwanted contacts.

#### User Flow
1. In `ConversationScreen`, user selects "Block User".
2. Block confirmation dialog appears explaining the consequences.
3. User confirms.
4. Block record is written to Firestore; user is returned to the chat list.

#### Important UI Components
* Block Confirmation Dialog (`lib/features/chat/presentation/conversation_screen.dart:73`)
* Blocked status notification banner

#### Backend & Firestore Interaction
* **Repository**: `SafetyRepository` (`lib/features/safety/data/safety_repository.dart`)
* **Collection**: `/blocked_users/{blockId}`
* **Document Structure**:
```json
{
  "blockId": "string (deterministic: blockerId_blockedId)",
  "blockerId": "string",
  "blockedId": "string",
  "createdAt": "Timestamp (serverTimestamp)"
}
```

#### Security Considerations
* Deterministic block ID (`${blockerId}_${blockedId}`).
* Only `blockerId` can read or create their blocks.
* Cannot block oneself.
* `MatchingService`, `SearchService`, and `ChatRepository` check block status before exposing profiles or permitting messages.

#### Performance Considerations
* Deterministic ID check (`_firestore.collection('blocked_users').doc(id).get()`) enables single-document lookup in `O(1)` time without scanning entire collections.

---

### 11. Zero-Vanity Utility User Profile

#### What it does
Presents user identity focused purely on utility and trust: displays what the user needs, what they can help with, and their verified Trust Score.

#### Why it exists
NIVA rejects social media vanity patterns (no follower counts, no likes, no popularity metrics). Instead, user profiles answer two questions: *"What does this person need?"* and *"What can this person help with?"*.

#### User Flow
1. User taps the Profile tab in the bottom navigation bar.
2. `ProfileScreen` loads the user's verified Trust Score badge (100/100 Verified Member), active need listings, capability chips, and reviews.
3. User can trigger Edit Profile, review safety options, or securely sign out.

#### Important UI Components
* `ProfileScreen` (`lib/features/profile/presentation/profile_screen.dart`)
* Trust Score Card with verified shield badge
* Capability chips and active need list items

#### Backend & Firestore Interaction
* **Repository**: `UserRepository` (`lib/features/user/data/user_repository.dart`)
* Reads from `/users/{userId}`.

#### Security Considerations
* Sensitive contact details (e.g., email address) are excluded from the public profile document.
* Profile updates enforce immutability of `trustScore`, `role`, and `createdAt`.

#### Performance Considerations
* Constrained layout (`maxWidth: 580`) ensures optimal typography hierarchy across all screen widths.

---

### 12. Authentication & Profile Initialization Flow

#### What it does
Manages user authentication state, email/password login, account registration with automatic profile bootstrap, password recovery, and secure sign out.

#### Why it exists
Provides the identity foundation required to enforce ownership checks, access control rules, and trust ratings.

#### User Flow
1. App opens `AuthGate` (`lib/features/auth/presentation/auth_gate.dart`).
2. If unauthenticated, displays `LoginScreen`.
3. If user registers via `SignUpScreen`:
   - Creates Firebase Auth credential.
   - Sets display name.
   - Bootstraps Firestore profile at `/users/{userId}` with `trustScore: 100` and `role: 'member'`.
4. `AuthGate` detects authenticated user stream and renders `MainNavigationShell`.

#### Important UI Components
* `AuthGate`
* `LoginScreen`
* `SignUpScreen`

#### Backend & Firestore Interaction
* **Service**: `AuthService` (`lib/features/auth/data/auth_service.dart`)
* Firebase Auth SDK (`signInWithEmailAndPassword`, `createUserWithEmailAndPassword`, `signOut`, `sendPasswordResetEmail`).
* Writes to `/users/{userId}` upon signup.

#### Security Considerations
* Client passwords are never transmitted to Firestore or stored locally; handled exclusively by Firebase Authentication.
* Inputs sanitized before sending to Firebase.
* Profile creation verifies `request.auth.uid == userId`.

#### Performance Considerations
* `AuthGate` listens to `authStateChanges()` stream efficiently, rendering the correct view with zero flicker.

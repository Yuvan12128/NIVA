# NIVA — Master Project Documentation

> **Complete Comprehensive Engineering & Architecture Manual for the NIVA Mobile Application**

---

## Executive Summary
**NIVA** is an intent-first, universal need-to-solution discovery mobile application built with **Flutter 3** and backed by **Google Cloud Firestore** and **Firebase Authentication**. NIVA breaks away from traditional social media engagement models by eliminating vanity metrics (likes, followers, public comment threads) in favor of a clean, dual-facet utility model: **"I Need"** and **"I Can Help"**.

---

## 1. Project Overview
NIVA connects people with specific, active needs (mentorship, hardware repair, software development, creative guidance, local services) directly to capable helpers, communities, and opportunities. Through an algorithmic candidate matching engine, consent-driven 1-to-1 connection workflows, and verified post-collaboration reviews, NIVA delivers a safe, high-signal, distraction-free collaboration ecosystem.

---

## 2. Problem Statement
Modern platforms are poorly suited for direct, intentional peer collaboration:
* **Social Media (LinkedIn, X, Instagram)**: Optimizes for passive entertainment, advertising revenue, virality, and superficial vanity metrics. Genuine, time-sensitive needs are rapidly buried beneath feed algorithms.
* **Gig Marketplaces (Upwork, Fiverr)**: Require complex contractual overhead, charge steep transaction commissions (10–20%), and are poorly suited for casual mentorship, peer learning, or community aid.
* **Online Forums (Reddit, Discord)**: Suffer from disorganized message noise, unverified user reputations, and lack structured matching or mutual consent workflows.

---

## 3. Solution
NIVA provides an intent-driven platform featuring:
* **Two-Way Intent Exchange**: Symmetric modeling of needs and capabilities.
* **5-Factor Algorithmic Matching**: Instantly ranks helpers based on skills, location, urgency, category, and community trust.
* **Consent-Protected Messaging**: 1-to-1 private chat is unlocked only upon mutual acceptance of an explicit connection request.
* **Verified Reputation & Trust**: Built-in 1–5 star reviews and verified Trust Scores (default 100).
* **Zero Social Vanity**: Completely eliminates follower counts, popularity contests, and vanity badges.

---

## 4. Objectives
* Build a responsive, 60 FPS mobile application optimized for Android and cross-platform devices.
* Maintain rigorous security with ownership verification, participant isolation, write-only moderation, and zero client-side privilege escalation.
* Provide clean offline fallback resilience and responsive layout compatibility from 320px ultra-compact phones to 800px 10-inch tablets.

---

## 5. Target Users
* **Learners & Students**: Finding tutors, career mentors, and academic project partners.
* **Developers & Makers**: Finding code reviewers, system architects, and technical contributors.
* **Local Specialists**: Offering repair services, photography, tutoring, or advice.
* **Community Collaborators**: Connecting on open-source initiatives and mutual aid efforts.

---

## 6. Features
* **Logo Reveal Splash**: Smooth animated brand introduction with graceful transition.
* **Firebase Authentication Gate**: Email/password authentication, registration, password recovery.
* **Home Dashboard**: Categorized navigation, recommended discovery carousels, and active needs feed.
* **Explore Marketplace**: Debounced universal search (300ms) with keyword suggestion chips and trending topics.
* **Multi-Criteria Filter Sheet**: Category, urgency, location (Remote / In-Person), and Trust Score threshold slider.
* **Dual-Facet Creation Sheet**: Publish requests ("I Need") or capabilities ("I Can Help").
* **Matching Engine**: Real-time algorithmic compatibility scoring with percentage breakdown.
* **Connection Lifecycle**: Consent-based connection invitations, notification alerts, accept/decline actions.
* **Real-Time Private Chat**: 1-to-1 messaging with reverse-scrolling history, delivery status, and timestamps.
* **In-App Notifications**: Real-time activity center for connection requests, acceptances, and messages.
* **Verified Reviews**: 1–5 star post-collaboration ratings and qualitative feedback.
* **Trust & Safety Moderation**: Write-only reporting and instant mutual blocking.
* **Utility Profile**: Clean personal showcase displaying what the user needs, what they can help with, and their verified Trust badge.

---

## 7. User Flow

```mermaid
flowchart LR
    A[Launch App] --> B[Auth Gate]
    B --> C[Home Dashboard]
    C --> D[Explore & Search]
    C --> E[Create Need / Help]
    E --> F[Algorithmic Matching]
    F --> G[Connection Request]
    D --> G
    G --> H[Notifications Activity]
    H --> I[Accept Connection]
    I --> J[1-to-1 Private Chat]
    J --> K[Review / Report / Block]
```

---

## 8. UI/UX Design System
* **Color Palette**:
  * Primary Accent: NIVA Purple (`#6C5CE7`)
  * Surface Background: Soft Neutral (`#F8F9FE`)
  * Card Surfaces: Pure White (`#FFFFFF`) with subtle border lines (`#E2E8F0`)
  * Category Accents: Vibrant semantic color codings for People, Services, Communities, Opportunities, and Info.
* **Typography**: Clean modern sans-serif scale with strict typographic hierarchy.
* **Responsive Layouts**: Capped maximum container widths (540px–580px) ensuring desktop and tablet elegance alongside compact mobile density.

---

## 9. Architecture
NIVA implements a **Modular Feature-Driven Architecture**:

```
[Presentation Layer]
  - UI Screens (HomeScreen, ExploreScreen, ChatScreen, etc.)
  - Modal Bottom Sheets (CreateNeedSheet, MatchingSheet, FilterBottomSheet)
  - Reusable Widgets (NivaSearchBar, NivaButton, NivaAvatar)
         |
         v
[Repository / Service Layer]
  - AuthService, NeedRepository, MatchingService, ChatRepository,
    ConnectionRequestRepository, NotificationRepository, SafetyRepository
         |
         v
[Data & Cloud Layer]
  - Firebase Authentication SDK
  - Cloud Firestore SDK
  - Client-side Seed Fallbacks
```

---

## 10. Technology Stack
* **Language**: Dart 3.13.3
* **Framework**: Flutter 3.47.4 (Channel stable)
* **Backend**: Google Cloud Firestore & Firebase Authentication
* **Code Quality**: `flutter_lints` with clean analysis passing (0 issues)
* **Platforms**: Android (API 21+), Web, Linux Desktop, iOS

---

## 11. Firebase Architecture
Client connects directly to Firebase SDKs with security enforced at the Firestore Security Rules level:
* **Authentication**: Token verification, password hashing, user session tracking.
* **Cloud Firestore**: Real-time listeners for active conversations and notifications; bounded one-shot queries for catalogs and list screens.

---

## 12. Firestore Collections & Schema
1. `/users/{userId}`: Profile details, capability keywords, trustScore (100 base), role (`member`).
2. `/needs/{needId}`: Intent items (`type: 'need' | 'help'`), skill tags, category, urgency, location, budget.
3. `/connection_requests/{requestId}`: 1-to-1 invitations (`status: 'pending' | 'accepted' | 'declined'`).
4. `/chats/{chatId}`: Canonical conversation metadata with deterministic ID format `userA_userB`.
5. `/messages/{messageId}`: Immutable chat messages (1–2000 chars, senderId, receiverId).
6. `/notifications/{notificationId}`: Recipient-scoped activity items with `isRead` flag.
7. `/reviews/{reviewId}`: Verified 1–5 star reviews linked to needs and connection requests.
8. `/blocked_users/{blockId}`: Mutual block records with deterministic ID format `blocker_blocked`.
9. `/reports/{reportId}`: Write-only moderation reports with deterministic ID format `reporter_reported_ref`.

---

## 13. Security & Access Control
* **Ownership Verification**: All write operations require `request.auth.uid == data.userId`.
* **Chat Participant Isolation**: Reading and sending messages is restricted strictly to users in `chat.participantIds`.
* **Write-Only Reports**: Moderation reports cannot be read or modified by regular users.
* **TrustScore Guarding**: Client-side code cannot mutate `trustScore`—enforced both in client repositories and server security rules.
* **Input Validation**: Titles <= 120 chars, descriptions <= 1000 chars, reports <= 500 chars, messages <= 2000 chars.
* **Zero Secrets**: No API keys, passwords, or credentials stored in source control.

---

## 14. Matching Engine
The V1 Matching Engine calculates compatibility across 5 distinct dimensions:
* **Skill Match (40%)**: Jaccard index between required and offered capabilities.
* **Location Match (20%)**: Geographical proximity or Remote compatibility.
* **Availability Match (15%)**: Turnaround and availability alignment.
* **Category Match (15%)**: Categorical intent alignment.
* **Trust Score (10%)**: Helper reliability weighting.

---

## 15. Connections Workflow
1. Requester taps "Connect" on an item.
2. Connection request document is created in `/connection_requests` with status `'pending'`.
3. Recipient receives notification in `NotificationsScreen`.
4. Recipient accepts: status becomes `'accepted'`, and `/chats/{userA_userB}` is created.

---

## 16. Chat System
* **Deterministic ID Generation**: Alphabetically sorted participant UIDs prevent duplicate parallel chats.
* **Scoped Real-Time Listener**: Active listener exists only while `ConversationScreen` is open.
* **Reverse Scrolling**: `ListView.builder(reverse: true)` optimizes message rendering and keyboard interaction.

---

## 17. Notification System
* Streams real-time alerts for incoming requests, accepted connections, and messages.
* Restricts write permissions to prevent redundant unread duplicates.
* Recipient can dismiss or mark notifications as read.

---

## 18. Reviews & Trust
* Post-collaboration review with 1–5 stars and constructive qualitative commentary.
* Reviews are permanent and immutable.
* Client-side trust score manipulation is prevented.

---

## 19. Search & Filters
* Debounced universal search (300ms) prevents excessive database reads.
* Filter bottom sheet provides Category, Urgency, Location, and Trust Score slider constraints.
* Offline seed fallback (`SearchService.seedDiscoveries`) enables full UI evaluation even when disconnected.

---

## 20. Safety & Moderation
* Users can report abusive content across 5 violation categories.
* Users can block malicious contacts, instantly severing messaging, discovery, and matching access.

---

## 21. Performance & Low-End Android Optimization
* **Bounded Reads**: Every query enforces a hard `limit` clause (10–40 items).
* **Memory Management**: Controllers and listeners are cleanly disposed in `dispose()`.
* **Const Constructors**: Widgets declare `const` constructors where possible to prevent redundant subtree rebuilds.
* **Ultra-Compact Support**: Verified down to 320px screen width without layout overflows.

---

## 22. Automated Testing Coverage
* **190 Automated Tests Passing** (0 failed, 0 skipped).
* **8 Device Form Factors Verified**: 320px, 360px, 375px, 390px, 412px, 430px, 600px, 800px.
* **Static Analysis**: `flutter analyze` reports 0 issues.
* **Build Verification**: Gradle dry-run configuration successful.

---

## 23. Screen Inventory Summary

| ID | Name | File | Auth | Firebase | Screenshot |
| :--- | :--- | :--- | :---: | :---: | :---: |
| SCR-01 | Splash / Logo | `lib/features/splash/presentation/logo_reveal_screen.dart` | No | No | `01_splash.png` |
| SCR-02 | Login | `lib/features/auth/presentation/login_screen.dart` | No | Yes | `02_login.png` |
| SCR-03 | Sign Up | `lib/features/auth/presentation/signup_screen.dart` | No | Yes | `03_signup.png` |
| SCR-04 | Home Dashboard | `lib/features/navigation/presentation/main_navigation_shell.dart` | Yes | Yes | `04_home.png` |
| SCR-05 | Explore | `lib/features/explore/presentation/explore_screen.dart` | Yes | Yes | `05_explore.png` |
| SCR-06 | Filter Sheet | `lib/features/explore/presentation/widgets/filter_bottom_sheet.dart` | Yes | Client | `06_filter.png` |
| SCR-07 | Create Need/Help | `lib/features/navigation/presentation/widgets/create_need_sheet.dart` | Yes | Yes | `07_create_need.png` |
| SCR-08 | Matching Sheet | `lib/features/matching/presentation/widgets/matching_sheet.dart` | Yes | Yes | `08_matching.png` |
| SCR-09 | Chat Directory | `lib/features/chat/presentation/chat_screen.dart` | Yes | Yes | `09_chat_list.png` |
| SCR-10 | Conversation | `lib/features/chat/presentation/conversation_screen.dart` | Yes | Yes | `10_conversation.png` |
| SCR-11 | Notifications | `lib/features/notifications/presentation/notifications_screen.dart` | Yes | Yes | `11_notifications.png` |
| SCR-12 | Profile | `lib/features/profile/presentation/profile_screen.dart` | Yes | Yes | `12_profile.png` |
| SCR-13 | Review Sheet | `lib/features/reviews/presentation/widgets/review_sheet.dart` | Yes | Yes | `13_review.png` |
| SCR-14 | Report Sheet | `lib/features/safety/presentation/widgets/report_sheet.dart` | Yes | Yes | `14_report.png` |

---

## 24. Production UI Screenshots

### 01. Splash / Logo Screen
![01_splash](screenshots/01_splash.png)

### 02. Login Screen
![02_login](screenshots/02_login.png)

### 03. Sign Up Screen
![03_signup](screenshots/03_signup.png)

### 04. Home Screen / Navigation Shell
![04_home](screenshots/04_home.png)

### 05. Explore Screen
![05_explore](screenshots/05_explore.png)

### 06. Filter Bottom Sheet
![06_filter](screenshots/06_filter.png)

### 07. Create Need / Help Sheet
![07_create_need](screenshots/07_create_need.png)

### 08. Matching Sheet
![08_matching](screenshots/08_matching.png)

### 09. Chat Directory Screen
![09_chat_list](screenshots/09_chat_list.png)

### 10. Conversation Screen
![10_conversation](screenshots/10_conversation.png)

### 11. Notifications Screen
![11_notifications](screenshots/11_notifications.png)

### 12. Profile Screen
![12_profile](screenshots/12_profile.png)

### 13. Review Sheet
![13_review](screenshots/13_review.png)

### 14. Report Sheet
![14_report](screenshots/14_report.png)

---

## 25. Limitations
* Background push notifications currently require active foreground execution (Firebase Cloud Messaging APNs/FCM tokens can be wired for background waking).
* Chat attachments are currently limited to text messages; media file uploads require Cloud Storage bucket rules.

---

## 26. Future Scope
* **Geographical Proximity Engine**: Real-time distance calculation using GeoFirestore.
* **Automated Trust Recalculation**: Serverless Cloud Functions triggered by review submissions to update rolling averages.
* **Multimedia Exchange**: Image and document attachments in private chats.
* **Firebase App Check**: Activation of Play Integrity on Android and reCAPTCHA Enterprise on Web.

---

## 27. Conclusion
The NIVA codebase is structurally sound, rigorously tested, secure, and production-ready. Every documented feature and UI component exists directly within the Flutter codebase, providing a reliable, scalable foundation for intentional community collaboration.

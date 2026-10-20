# NIVA Screen Documentation

This document provides a detailed breakdown of every screen, bottom sheet, and modal in the actual NIVA application, accompanied by clean rendered UI screenshots captured at standard modern mobile resolution (390 x 844).

---

## Table of Contents
1. [01. Splash / Logo Screen](#01-splash--logo-screen)
2. [02. Login Screen](#02-login-screen)
3. [03. Sign Up Screen](#03-sign-up-screen)
4. [04. Home Screen / Navigation Shell](#04-home-screen--navigation-shell)
5. [05. Explore Screen](#05-explore-screen)
6. [06. Filter Bottom Sheet](#06-filter-bottom-sheet)
7. [07. Create Need / Help Sheet](#07-create-need--help-sheet)
8. [08. Matching Sheet](#08-matching-sheet)
9. [09. Chat List Screen](#09-chat-list-screen)
10. [10. Conversation Screen](#10-conversation-screen)
11. [11. Notifications Screen](#11-notifications-screen)
12. [12. Profile Screen](#12-profile-screen)
13. [13. Review Sheet](#13-review-sheet)
14. [14. Report Sheet](#14-report-sheet)

---

### 01. Splash / Logo Screen

![Splash Screen](screenshots/01_splash.png)

* **Screenshot**: `screenshots/01_splash.png`
* **File Path**: `lib/features/splash/presentation/logo_reveal_screen.dart`
* **Purpose**: Serves as the high-impact brand entrance upon app launch. Displays the animated NIVA badge and tagline while Flutter core bindings and Firebase services initialize.
* **UI Components**:
  * Smooth fade-in logo icon with rounded squircle geometry and brand gradient (`#6C5CE7` to `#A29BFE`).
  * Bold stylized typography with subtle letter-spacing.
  * Tagline label: *"Connect Intent. Discover Solutions."*
  * Dark/light theme adaptive canvas with zero UI clutter.
* **User Actions**:
  * Passive viewing: Transitions automatically into `AuthGate` upon completion of the animation curve or authentication state resolution.
* **Backend**: None (pure client-side transition).
* **Firestore**: None.
* **Security**: No user data loaded on this screen; safe from information leakage.
* **Performance**: Lightweight single-ticker animation with auto-disposing `AnimationController`. Renders at a stable 60 FPS.

---

### 02. Login Screen

![Login Screen](screenshots/02_login.png)

* **Screenshot**: `screenshots/02_login.png`
* **File Path**: `lib/features/auth/presentation/login_screen.dart`
* **Purpose**: Allows registered community members to authenticate using email and password, or request a password reset email.
* **UI Components**:
  * NIVA brand mark and welcoming title: *"Welcome Back"*.
  * Clean text input fields for Email and Password with inline format validation.
  * Password visibility toggle (`obscureText` toggle).
  * *"Forgot Password?"* text button triggering inline password reset email delivery.
  * High-contrast primary action button (`NivaButton` with loading state indicator).
  * Navigation link redirecting to the Registration screen.
* **User Actions**:
  * Enter credentials and submit sign-in.
  * Request password reset link.
  * Switch to Sign Up flow.
* **Backend**: Firebase Authentication (`signInWithEmailAndPassword`, `sendPasswordResetEmail`).
* **Firestore**: No direct Firestore reads prior to authentication.
* **Security**: Enforces email format validation, sanitizes input whitespace, hides passwords, and handles Firebase auth error codes securely without leaking existing account enumerations.
* **Performance**: Controllers are disposed in `dispose()`; zero unnecessary widget rebuilds.

---

### 03. Sign Up Screen

![Sign Up Screen](screenshots/03_signup.png)

* **Screenshot**: `screenshots/03_signup.png`
* **File Path**: `lib/features/auth/presentation/signup_screen.dart`
* **Purpose**: Onboards new users by establishing their cryptographic authentication identity and initializing their public community profile.
* **UI Components**:
  * Header title: *"Join NIVA"*, subtitle: *"Start discovering real connections"*.
  * Input fields: Full Name, Email Address, Password, Confirm Password.
  * Terms & Privacy agreement acknowledgment checkbox.
  * Submit button: *"Create Account"* with progress spinner during async creation.
  * Login redirection link.
* **User Actions**:
  * Input registration details and accept terms.
  * Submit registration form.
  * Redirect to Login screen if account exists.
* **Backend**: Firebase Authentication (`createUserWithEmailAndPassword`, `updateDisplayName`).
* **Firestore**: Writes initial profile document to `/users/{userId}` with default base `trustScore: 100`, `role: 'member'`, and `createdAt: serverTimestamp()`.
* **Security**: Enforces strict password length (>6 chars), match verification, and sanitizes display names. Excludes private emails from public profile documents per Firestore rules.
* **Performance**: Input validation occurs locally before dispatching network requests, minimizing round trips.

---

### 04. Home Screen / Navigation Shell

![Home Screen](screenshots/04_home.png)

* **Screenshot**: `screenshots/04_home.png`
* **File Path**: `lib/features/navigation/presentation/main_navigation_shell.dart`, `lib/features/home/presentation/home_screen.dart`
* **Purpose**: Primary dashboard providing a quick pulse on community activity, personalized recommendations, category shortcuts, and access to all app destinations via bottom navigation.
* **UI Components**:
  * Top `HomeHeader` displaying user avatar, personalized greeting (*"Hello, Arun"*), and notification bell badge.
  * Read-only search trigger bar: *"What do you need today?"*.
  * Interactive `CategoryGrid` with icons for People, Services, Communities, Opportunities, Information, and *"I Can Help"*.
  * `RecommendedSection` horizontal carousel with category badges.
  * `RecentNeedsSection` vertical list showing active requests with urgency pills.
  * Bottom Navigation Bar with Home, Explore, Center "+" FAB, Chats, and Profile destinations.
* **User Actions**:
  * Tap search bar to open `ExploreScreen`.
  * Tap category chip to filter discovery.
  * Tap center "+" button to open `CreateNeedSheet`.
  * Tap notification bell to navigate to `NotificationsScreen`.
  * Switch tabs using bottom navigation.
* **Backend**: Firebase Authentication (`currentUser`), Cloud Firestore.
* **Firestore**: Reads from `/needs` (`where('status', '==', 'active')`, `limit: 10`), with offline seed fallback when disconnected.
* **Security**: Only authenticated users can access the shell; reads are bounded by query limits.
* **Performance**: Utilizes `IndexedStack` to preserve state across tab switches with zero widget recreation overhead.

---

### 05. Explore Screen

![Explore Screen](screenshots/05_explore.png)

* **Screenshot**: `screenshots/05_explore.png`
* **File Path**: `lib/features/explore/presentation/explore_screen.dart`
* **Purpose**: Universal discovery marketplace for finding People, Services, Communities, Opportunities, and Information.
* **UI Components**:
  * `NivaSearchBar` with debounced input (300ms) and Filter button.
  * Horizontal scrollable Category selector (All, People, Services, Information, Opportunities, Communities).
  * Quick Search suggestion chips (e.g., *"Java tutor"*, *"Laptop repair"*, *"React developer"*).
  * Trending Topics section (e.g., `#MachineLearning`, `#CareerMentorship`).
  * Discovery Result Cards with author avatar, Trust Score badge (e.g., `100 Trust`), category pill, skills tags, and actionable *"Connect"* button.
* **User Actions**:
  * Type in search bar to execute debounced multi-field search.
  * Tap category chip to restrict discovery domain.
  * Tap filter button to open `FilterBottomSheet`.
  * Tap *"Connect"* on a discovery card to trigger connect confirmation dialog and send a 1-to-1 connection request.
* **Backend**: Cloud Firestore via `SearchService` and `ConnectionRequestRepository`.
* **Firestore**: Bounded candidate queries on `/needs` and `/users`, client-side keyword and ranking evaluation.
* **Security**: Excludes self-items and items from blocked users. Connect requests validate recipient existence and prevent redundant spam requests.
* **Performance**: 300ms input debounce prevents query thrashing; bounded query limit (default 20 candidates).

---

### 06. Filter Bottom Sheet

![Filter Bottom Sheet](screenshots/06_filter.png)

* **Screenshot**: `screenshots/06_filter.png`
* **File Path**: `lib/features/explore/presentation/widgets/filter_bottom_sheet.dart`
* **Purpose**: Enables users to narrow down exploration results by category, urgency, location type, and minimum trust score.
* **UI Components**:
  * Modal header with drag handle and title: *"Filter Discoveries"*.
  * Category ChoiceChips (All, People, Services, Communities, Opportunities, Information).
  * Urgency Selector chips (All, Flexible, Medium, High).
  * Location Type toggle (All, Remote Only, In-Person Only).
  * Minimum Trust Score Slider with live numeric score readout (20 to 100).
  * Dual footer actions: *"Reset Filters"* (secondary) and *"Apply Filters"* (primary).
* **User Actions**:
  * Select desired criteria and adjust trust threshold.
  * Reset to clear all filters.
  * Apply to immediately re-filter the `ExploreScreen` dataset.
* **Backend**: Local state management via `SearchFilter` immutable model.
* **Firestore**: Client-side query criteria passed to `SearchService`.
* **Security**: Prevents injection of invalid filter values; strictly typed enum fields.
* **Performance**: Uses `ConstrainedBox` with max width constraint (540px) ensuring consistent layout across phones and tablets.

---

### 07. Create Need / Help Sheet

![Create Need Sheet](screenshots/07_create_need.png)

* **Screenshot**: `screenshots/07_create_need.png`
* **File Path**: `lib/features/navigation/presentation/widgets/create_need_sheet.dart`
* **Purpose**: Core intent publication modal for both facets of NIVA: requesting help (*"I Need"*) or offering capabilities (*"I Can Help"*).
* **UI Components**:
  * Modal header with drag handle and close button.
  * Intent selection cards:
    * *"I Have a Need"*: For requesting mentors, services, tools, or advice.
    * *"I Can Help"*: For publishing capabilities, mentorship, and skills.
  * Dynamic form inputs for title, description, category dropdown, comma-separated skill tags, location, budget, and urgency.
  * One-tap example chips (e.g., *"I need a Java tutor"*, *"I can teach React"*).
  * Primary submit button with async loading spinner.
  * Success confirmation step with immediate transition to matching.
* **User Actions**:
  * Choose between "Need" or "Help".
  * Populate form fields or pick quick inspiration chip.
  * Submit intent to Firestore.
* **Backend**: Cloud Firestore via `NeedRepository`.
* **Firestore**: Writes new document to `/needs/{needId}` with `createdAt: serverTimestamp()`.
* **Security**: Enforces title length limits (1–120 chars), description limits (<=1000 chars), category whitelisting, and strict author `userId` verification matching `request.auth.uid`.
* **Performance**: Keyboard inset handling via `viewInsets.bottom` padding prevents UI squishing or overflow.

---

### 08. Matching Sheet

![Matching Sheet](screenshots/08_matching.png)

* **Screenshot**: `screenshots/08_matching.png`
* **File Path**: `lib/features/matching/presentation/widgets/matching_sheet.dart`
* **Purpose**: Presents real-time algorithmic candidate matches for an active need, ranked using multi-factor scoring.
* **UI Components**:
  * Header displaying need title and total match candidate count.
  * Match Result Cards featuring:
    * Helper avatar and display name.
    * Match percentage badge (e.g., `95% Match`).
    * Matched skill chips highlighting overlapping capabilities.
    * Location and availability indicators.
    * Helper Trust Score pill (e.g., `100 Trust`).
    * Action button: *"Connect"* (or *"Request Sent"* if already pending).
  * Close secondary button.
* **User Actions**:
  * Review candidate scores and matched capabilities.
  * Tap *"Connect"* to dispatch a 1-to-1 connection request directly to the candidate.
* **Backend**: `MatchingService` V1 rule-based engine and `ConnectionRequestRepository`.
* **Firestore**: Queries active `/needs` where `type == 'help'` (limit 20), filters blocked users, and checks `/connection_requests`.
* **Security**: Excludes blocked users and own user ID from matching pool; ensures connection requests cannot be duplicated.
* **Performance**: Scored in-memory with bounded reads to minimize database load.

---

### 09. Chat List Screen

![Chat List Screen](screenshots/09_chat_list.png)

* **Screenshot**: `screenshots/09_chat_list.png`
* **File Path**: `lib/features/chat/presentation/chat_screen.dart`
* **Purpose**: Directory displaying all active 1-to-1 conversations established through accepted connection requests.
* **UI Components**:
  * Top AppBar with screen title: *"Chats"*.
  * List of active conversation cards showing:
    * Peer user avatar and display name.
    * Snippet of the latest message delivered.
    * Relative time badge (e.g., *"15m ago"*, *"3h ago"*).
    * Unread message indicator dot.
  * Empty state placeholder (*"No active conversations yet"*) when no chats exist.
  * Pull-to-refresh mechanism.
* **User Actions**:
  * Tap on any conversation to open `ConversationScreen`.
  * Pull down to refresh chat list.
* **Backend**: Cloud Firestore via `ChatRepository`.
* **Firestore**: One-shot bounded query on `/chats` (`where('participantIds', 'array-contains', userId)`, `limit: 20`).
* **Security**: Only returns chats where `request.auth.uid` is in `participantIds`.
* **Performance**: Does not attach persistent listeners to the entire directory; performs bounded one-shot read with pull-to-refresh, conserving mobile battery and network quota.

---

### 10. Conversation Screen

![Conversation Screen](screenshots/10_conversation.png)

* **Screenshot**: `screenshots/10_conversation.png`
* **File Path**: `lib/features/chat/presentation/conversation_screen.dart`
* **Purpose**: Real-time private 1-to-1 messaging interface for connected collaborators.
* **UI Components**:
  * Custom AppBar with back navigation, peer avatar, peer name, and status indicator.
  * Top safety actions menu:
    * *"Review Connection"* (opens `ReviewSheet`).
    * *"Report User"* (opens `ReportSheet`).
    * *"Block User"* (triggers block confirmation dialog).
  * Reverse-scrolling message list (`ListView.builder(reverse: true)`).
  * Outgoing message bubbles (colored brand purple `#6C5CE7`, right-aligned) and incoming bubbles (light surface `#F4F5FB`, left-aligned).
  * Message timestamps and delivery indicators.
  * Bottom message composer with multi-line text field and send icon button.
* **User Actions**:
  * Type and send text messages.
  * Scroll through historical messages.
  * Submit review, report peer, or block peer from the menu.
* **Backend**: Cloud Firestore via `ChatRepository`.
* **Firestore**: Real-time listener strictly attached to `/messages` where `chatId == activeChatId` (`limit: 40`), updates `/chats/{chatId}` metadata upon message delivery.
* **Security**: Firestore security rules verify `request.auth.uid in chat.participantIds`, message sender matches auth UID, text is non-empty and <= 2000 chars. Blocks immediately disable messaging.
* **Performance**: Real-time stream is strictly bound to this screen lifecycle (`initState` -> `dispose`), ensuring zero background listener memory leaks.

---

### 11. Notifications Screen

![Notifications Screen](screenshots/11_notifications.png)

* **Screenshot**: `screenshots/11_notifications.png`
* **File Path**: `lib/features/notifications/presentation/notifications_screen.dart`
* **Purpose**: Centralized activity hub alerting users to incoming connection requests, accepted connections, and system updates.
* **UI Components**:
  * AppBar: *"Activity"*, with *"Mark all as read"* action.
  * Notification cards classified by type:
    * `connection_request`: Displays requester info with Accept and Decline buttons.
    * `connection_accepted`: Direct link to start messaging.
    * `new_message`: Direct link to open conversation.
  * Type-specific colored icon indicators.
  * Relative timestamp labels (e.g., *"10m ago"*, *"2h ago"*).
  * Unread blue indicator badge.
  * Empty state placeholder when all notifications are cleared.
* **User Actions**:
  * Accept or decline connection requests.
  * Tap notification to navigate to relevant chat.
  * Mark notifications as read.
* **Backend**: Cloud Firestore via `NotificationRepository` and `ConnectionRequestRepository`.
* **Firestore**: Real-time stream on `/notifications` where `recipientId == currentUserId` (`limit: 30`).
* **Security**: Security rules enforce that only the designated `recipientId` can read or update `isRead` status.
* **Performance**: Real-time stream automatically canceled in `dispose()`; bounded read limit.

---

### 12. Profile Screen

![Profile Screen](screenshots/12_profile.png)

* **Screenshot**: `screenshots/12_profile.png`
* **File Path**: `lib/features/profile/presentation/profile_screen.dart`
* **Purpose**: User identity showcase intentionally designed around utility rather than social vanity: displays what the user needs, what they can help with, and their verified Trust Score.
* **UI Components**:
  * Profile header: Large avatar, display name, email/headline.
  * Verified Trust Score Card (e.g., `100/100 Verified Member`) with shield icon.
  * *"What I Need"* section listing active requests with urgency indicators.
  * *"What I Can Help With"* section listing capability chips (e.g., `Java`, `React`, `Flutter`, `Laptop repair`).
  * *"Recent Reviews"* section displaying verified community feedback.
  * Settings & Safety buttons: *"Edit Profile"*, *"Safety & Blocked Users"*, *"Privacy Policy"*, and *"Sign Out"*.
* **User Actions**:
  * Review personal capabilities and needs.
  * Access Settings or safety tools.
  * Sign out of account via confirmation dialog.
* **Backend**: Firebase Authentication and Cloud Firestore via `UserRepository`.
* **Firestore**: Reads profile data from `/users/{userId}`, active needs from `/needs`.
* **Security**: Strict zero-vanity policy: no follower counts, like counts, or public engagement metrics. Email address protected from public queries.
* **Performance**: Responsive container (`maxWidth: 580px`) centers and formats content elegantly on both phones and tablets.

---

### 13. Review Sheet

![Review Sheet](screenshots/13_review.png)

* **Screenshot**: `screenshots/13_review.png`
* **File Path**: `lib/features/reviews/presentation/widgets/review_sheet.dart`
* **Purpose**: Post-collaboration review modal allowing community members to submit constructive feedback and star ratings following a completed interaction.
* **UI Components**:
  * Modal header with drag handle and peer's name (*"Review Priya Sundaram"*).
  * Interactive 5-star rating bar with qualitative feedback labels (*"Poor"*, *"Fair"*, *"Good"*, *"Very Good"*, *"Excellent"*).
  * Text area for written review feedback.
  * Verification notice: *"Reviews are verified and contribute to community safety."*
  * Submit review button with progress indicator.
  * Success confirmation view with auto-dismiss.
* **User Actions**:
  * Select 1–5 stars.
  * Write constructive review text.
  * Submit review to Firestore.
* **Backend**: Cloud Firestore via `ReviewRepository`.
* **Firestore**: Writes review document to `/reviews/{reviewId}`.
* **Security**: Firestore rules enforce that reviewer cannot review themselves, review must link to an existing need/connection, rating must be an integer between 1 and 5, and review text is capped at 1000 characters. Client-side code does not directly mutate `trustScore`—this is reserved for trusted backend processes.
* **Performance**: Modal bottom sheet with constrained height and keyboard-aware inset padding.

---

### 14. Report Sheet

![Report Sheet](screenshots/14_report.png)

* **Screenshot**: `screenshots/14_report.png`
* **File Path**: `lib/features/safety/presentation/widgets/report_sheet.dart`
* **Purpose**: Essential safety and moderation interface allowing users to flag abusive behavior, spam, scams, or community guidelines violations.
* **UI Components**:
  * Modal header with red shield alert icon and title: *"Report User"*.
  * Peer identification: *"Reporting Priya Sundaram"*.
  * Violation Reason radio selection:
    * `spam`: Unsolicited advertising or automated messages.
    * `harassment`: Abusive language, intimidation, or hate speech.
    * `inappropriate`: Explicit or unacceptable content.
    * `scam`: Fraudulent offers or deceptive requests.
    * `other`: Other violations.
  * Optional descriptive details text area (max 500 characters).
  * Privacy notice: *"Reports are reviewed by the moderation team. The reported user will not be notified of who reported them."*
  * Submit Report button.
  * Success view with immediate option to block user.
* **User Actions**:
  * Choose violation category.
  * Enter optional details.
  * Submit report.
* **Backend**: Cloud Firestore via `SafetyRepository`.
* **Firestore**: Creates report document in `/reports/{reportId}` using deterministic ID format `reporterId_reportedUserId_refId`.
* **Security**: Write-only collection for users (`allow read: if false; allow delete: if false;`). Users cannot read other reports, modify existing reports, or report themselves. Enforces reason whitelisting and 500-character description limit.
* **Performance**: Direct deterministic document write requires zero prior query reads, optimizing network usage and Firestore billable operations.

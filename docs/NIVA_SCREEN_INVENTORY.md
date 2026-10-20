# NIVA Screen & UI Component Inventory

This document details every user-visible screen, navigation shell, modal bottom sheet, and major UI component in the NIVA application. Every item listed here exists directly in the production Flutter codebase.

---

## Screen Inventory Table

| Screen ID | Screen Name | File Path | Purpose | Entry Point | Main Actions | Auth Required | Firebase Used | Screenshot Reference |
| :--- | :--- | :--- | :--- | :--- | :--- | :---: | :---: | :---: |
| **SCR-01** | **Splash / Logo Screen** | `lib/features/splash/presentation/logo_reveal_screen.dart` | Animated brand reveal and initialization splash | App startup (`AuthGate`) | Auto-transitions to Auth or Home after reveal animation | No | No | `screenshots/01_splash.png` |
| **SCR-02** | **Login Screen** | `lib/features/auth/presentation/login_screen.dart` | User sign-in and password recovery | `AuthGate` (unauthenticated) | Sign In with email/password, Forgot Password reset link, Navigate to Sign Up | No | Firebase Auth | `screenshots/02_login.png` |
| **SCR-03** | **Sign Up Screen** | `lib/features/auth/presentation/signup_screen.dart` | New account registration | Login screen link (`onNavigateToSignUp`) | Create account with Full Name, Email, Password, Accept Terms | No | Firebase Auth & Firestore (`users`) | `screenshots/03_signup.png` |
| **SCR-04** | **Home Screen / Navigation Shell** | `lib/features/navigation/presentation/main_navigation_shell.dart`<br>`lib/features/home/presentation/home_screen.dart` | Primary application dashboard with discovery feed | Root authenticated shell (`AuthGate`) | Search bar trigger, category selection, recommended carousels, recent needs feed, bottom navigation tab switching, create modal trigger | Yes | Firestore (`needs`, `users`) | `screenshots/04_home.png` |
| **SCR-05** | **Explore Screen** | `lib/features/explore/presentation/explore_screen.dart` | Universal search & discovery hub for People, Services, Communities, Opportunities, Info | Bottom Nav Tab 1 ("Explore") / Home search bar | Live debounced search, category filtering, quick search hints, trending topics, discovery cards, Connect button, Match button | Yes | Firestore (`needs`, `users`) | `screenshots/05_explore.png` |
| **SCR-06** | **Filter Bottom Sheet** | `lib/features/explore/presentation/widgets/filter_bottom_sheet.dart` | Search refinement modal bottom sheet | Filter icon in `ExploreScreen` search bar | Filter by Category, Urgency level, Location (Remote / In-Person), Minimum Trust Score slider, Reset, Apply | Yes | Client-side filter state | `screenshots/06_filter.png` |
| **SCR-07** | **Create Need / Help Sheet** | `lib/features/navigation/presentation/widgets/create_need_sheet.dart` | Dual-facet intent publication modal | Central "+" action button on Bottom Navigation Bar | Select "I Need" vs "I Can Help", enter need/help description, tags, budget, urgency, publish to Firestore | Yes | Firestore (`needs`) | `screenshots/07_create_need.png` |
| **SCR-08** | **Matching Sheet** | `lib/features/matching/presentation/widgets/matching_sheet.dart` | Instant algorithmic candidate ranking sheet | "Find Match" action on any active Need card | View ranked candidates (score %, matched skills, distance/location, trust score), send 1-to-1 Connect Request | Yes | Firestore (`needs`, `connection_requests`, `users`) | `screenshots/08_matching.png` |
| **SCR-09** | **Chat List Screen** | `lib/features/chat/presentation/chat_screen.dart` | Conversations directory displaying active 1-to-1 chats | Bottom Nav Tab 2 ("Chats") | View recent conversation items, unread indicators, pull-to-refresh, open conversation | Yes | Firestore (`chats`) | `screenshots/09_chat_list.png` |
| **SCR-10** | **Conversation Screen** | `lib/features/chat/presentation/conversation_screen.dart` | Real-time 1-to-1 private chat interface | Tapping conversation in `ChatScreen` or accepting connection | Real-time chat messaging, reverse scroll history, send message, safety menu (Review, Report, Block User) | Yes | Firestore (`chats`, `messages`, `blocked_users`) | `screenshots/10_conversation.png` |
| **SCR-11** | **Notifications Screen** | `lib/features/notifications/presentation/notifications_screen.dart` | Activity feed for connection requests and alerts | Bell icon on `HomeHeader` or `ExploreScreen` | View connection requests, accept/decline requests, tap to open chat, mark all read | Yes | Firestore (`notifications`, `connection_requests`) | `screenshots/11_notifications.png` |
| **SCR-12** | **Profile Screen** | `lib/features/profile/presentation/profile_screen.dart` | User profile, trust badge, needs, and capabilities | Bottom Nav Tab 3 ("Profile") / Avatar in Home | View user info, verified Trust Score badge (100/100), active needs, help capabilities, reviews, Edit Profile trigger, Sign Out | Yes | Firebase Auth, Firestore (`users`, `needs`, `reviews`) | `screenshots/12_profile.png` |
| **SCR-13** | **Review Sheet** | `lib/features/reviews/presentation/widgets/review_sheet.dart` | Post-collaboration verified trust review modal | Safety menu in `ConversationScreen` / connection completion | Star rating selection (1–5 stars), write constructive feedback, submit verified review | Yes | Firestore (`reviews`) | `screenshots/13_review.png` |
| **SCR-14** | **Report Sheet** | `lib/features/safety/presentation/widgets/report_sheet.dart` | Trust & Safety user moderation modal | Safety menu in `ConversationScreen` / Profile options | Select violation reason (Spam, Harassment, Inappropriate, Scam, Other), input description, submit report | Yes | Firestore (`reports`) | `screenshots/14_report.png` |

---

## Modals & System Dialogs Summary

In addition to full-screen destinations and persistent sheets, the application includes three contextual confirmation dialogs:
1. **Connect Confirmation Dialog** (`lib/features/explore/presentation/explore_screen.dart:241`): Prompts user confirmation prior to sending a 1-to-1 connection request from an Explore discovery card.
2. **Block Confirmation Dialog** (`lib/features/chat/presentation/conversation_screen.dart:73`): Prompts confirmation to immediately terminate mutual communication and hide content.
3. **Sign Out Confirmation Dialog** (`lib/features/profile/presentation/profile_screen.dart:627`): Prevents accidental logouts with a destructive action verification modal.

# ASCEND: Project Documentation

ASCEND is a gamified, RPG-style productivity application built with Flutter, Firebase, and Riverpod. It leverages AI (OpenAI) to generate personalized daily quests, implements strict penalty systems for inactivity, and uses a cinematic progression tier to turn daily habits into an engaging game loop.

---

## 1. Core Architecture & Tech Stack

- **Frontend Framework**: Flutter
- **State Management**: Riverpod (Notifier/StateNotifier patterns)
- **Backend Services**: Firebase (Authentication, Cloud Firestore)
- **AI Integration**: OpenAI API (`gpt-4o` model)
- **Payments**: Stripe (`flutter_stripe`)
- **Growth/Sharing**: `screenshot` & `share_plus` for dynamic image generation and sharing.

---

## 2. Key Features

### Gamified RPG Progression
Users earn XP by completing tasks. As XP accumulates, users rank up through predefined tiers: **E -> D -> C -> B -> A -> S -> Monarch**. The app tracks 5 core stats (Strength, Intelligence, Discipline, Wealth, Charisma) which dictate the types of quests generated.

### AI Daily Quest Scheduler (`AiSchedulerService`)
The app utilizes GPT-4o to analyze a player's core stats, current rank, and past failed tasks to procedurally generate personalized daily quests. The AI balances task categories and assigns XP rewards dynamically.

### Penalty Engine & Catch-Up Routine
ASCEND actively tracks player activity. If a user fails to log in for one or more complete calendar days, the `PenaltyEngine` executes a strict Catch-Up routine:
- **Streak Break**: The user's active streak is immediately shattered to 0.
- **XP Drain**: Deducts 15 XP multiplied by the number of days missed (clamped to a minimum of 0 XP).
- **System Recovery Quest**: Injects a mandatory "System Recovery: Re-ignition Quest" (5 XP) to force the user back into the feedback loop.

### Cinematic Rank Evolutions
When an XP milestone is breached, the `CinematicRankUpOverlay` is triggered. This overlays the dashboard with a deep black, blurred glassmorphism effect, showcasing a glowing gold Rank Up banner that forces the user to "Claim Evolution" before proceeding.

### Premium Monk Mode (Stripe Paywall)
Certain features, like `MonkModeView`, are blocked by a `PremiumGate`. Non-premium users are redirected to the `SubscriptionView` to purchase a premium status via Stripe.

### Viral Sharing Loop
The `ExportUtility` leverages `screenshot` to programmatically capture a hidden `PlayerProgressCard` widget. This visually striking stat card can be exported instantly to social media via `share_plus` to encourage organic app growth.

---

## 3. Directory Structure & File Breakdown

### `lib/models/`
- **`player_profile.dart`**: The core data object for a user. Holds `uid`, `username`, `currentRank`, `totalXp`, `streakCount`, `coreStats`, `isPremium`, and `updatedAt`. Supports JSON/Map serialization for Firestore.
- **`task_model.dart`**: Represents a quest. Contains `id`, `title`, `description`, `category`, `isMandatory`, `isCompleted`, `xpReward`, and `createdAt`.

### `lib/providers/` (State Management)
- **`player_profile_provider.dart`**: Manages the user's active profile state. Contains the `addXP` logic that evaluates rank thresholds and triggers the `RankOverlayNotifier` if an evolution occurs.
- **`task_provider.dart`**: Fetches, caches, and toggles the completion status of the daily quests.
- **`rank_overlay_provider.dart`**: A global boolean state toggle (`isDisplayingRankUp`) and string tracker (`newRankTitle`) used by the cinematic overlay.
- **`daily_popup_provider.dart`**: State flag to ensure the "SYSTEM ACTIVATED" popup only triggers once per session.
- **`auth_provider.dart`**: Exposes the current Firebase Auth user state.

### `lib/repositories/` (Data Layer)
- **`auth_repository.dart`**: Abstraction over `FirebaseAuth` for sign-ins, sign-outs, and session handling.
- **`task_repository.dart`**: Abstraction over `FirebaseFirestore` (`FirebaseFirestore.instance`) to query and batch-write tasks and user profiles.

### `lib/services/` (Business Logic)
- **`ai_scheduler_service.dart`**: Handles the HTTP request to OpenAI's completion API. Formats the user's profile into an RPG prompt and safely parses the JSON response into `TaskModel` lists. Also contains `generateRecoveryQuest` for fast local task generation.
- **`penalty_engine.dart`**: Evaluates the time delta between `DateTime.now()` and `profile.updatedAt` normalized to midnight. Processes XP deductions, handles streak resets, and batch-saves data securely.
- **`payment_service.dart`**: Communicates with the Stripe API to handle intent creation and payment sheet presentation.

### `lib/views/` (UI Pages)
- **`dashboard_view.dart`**: The central hub. Uses a `Stack` to render the primary dashboard (XP bars, Stat Grids, Quest Lists) beneath the `CinematicRankUpOverlay`. Triggers the daily popup on initial load.
- **`monk_mode_view.dart`**: A premium-only focus view.
- **`subscription_view.dart`**: The Stripe checkout UI.

### `lib/widgets/` (Reusable UI Components)
- **`cinematic_rank_up_overlay.dart`**: A full-screen `ConsumerWidget` that listens to `rankOverlayProvider`. Uses `BackdropFilter` and `ShaderMask` for high-end glowing animations.
- **`premium_gate.dart`**: A wrapper widget that checks the user's `isPremium` status before rendering its child, otherwise rerouting to the paywall.
- **`player_progress_card.dart`**: An off-screen optimized card design used strictly by the `ExportUtility` to generate sharing images.

### `lib/utils/`
- **`export_utility.dart`**: Contains the `exportProgressCard` logic that binds the `PlayerProgressCard` to a `ScreenshotController` and pipes the resulting Uint8List into the native OS share sheet.

---

## 4. Workflows

### Authentication & Initialization
1. App launches, `FirebaseAuth` resolves user.
2. `DashboardView` mounts. `PenaltyEngine` intercepts the load via `verifyLastLoginCheckIn` to calculate missed days and apply penalties if needed.
3. The "SYSTEM ACTIVATED" dialog displays via `daily_popup_provider`.
4. `AiSchedulerService` queries OpenAI if the daily task list is empty for the new day.

### Quest Completion & Ranking Up
1. User checks a task in `DashboardView`.
2. `task_provider` marks `isCompleted = true` in Firestore.
3. `player_profile_provider.addXP(task.xpReward)` is called.
4. If XP crosses a threshold (e.g., 499 -> 500), `currentRank` increments (e.g., D -> C).
5. `addXP` synchronously updates `rankOverlayProvider.showOverlay('C')`.
6. `CinematicRankUpOverlay` instantly renders the blurred rank-up screen over the UI.

### Inactivity Penalty (Catch-Up Routine)
1. User logs in after a 3-day absence.
2. `PenaltyEngine` calculates `daysMissed = 2` (excluding the current day).
3. `xpPenalty` = `15 * 2` = 30 XP. Total XP is deducted, clamped at 0.
4. Streak is reset to 0.
5. "System Recovery: Re-ignition Quest" is generated.
6. Changes are atomically pushed via `FirebaseFirestore.instance.batch()`.

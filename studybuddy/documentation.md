# StudyBuddy Application: Technical Documentation

## 1. Introduction

### 1.1. Purpose and Scope

StudyBuddy is a comprehensive, cross-platform mobile application developed using the Flutter framework. It is designed to serve as a digital assistant for students, helping them to organize their academic activities, manage their time effectively, and maintain focus during study sessions. The application provides a suite of tools including a note-taking system, a task manager, a daily planner, and a Pomodoro-style focus timer.

### 1.2. Target Audience

The primary audience for StudyBuddy is students at any level of education (high school, college, or university) who are looking for a single, integrated tool to manage their study-related information and improve their productivity.

### 1.3. Key Objectives

- To provide a centralized platform for managing notes, tasks, and schedules.
- To enhance student productivity through a built-in focus timer.
- To offer a simple, intuitive, and visually appealing user interface.
- To ensure data persistence and availability through a robust local storage solution.

## 2. System Architecture

### 2.1. Framework: Flutter

The application is built using Flutter, Google's UI toolkit for building natively compiled applications for mobile, web, and desktop from a single codebase. This choice allows for rapid development and a consistent user experience across both Android and iOS platforms.

### 2.2. State Management

The application employs a localized state management approach using Flutter's built-in `StatefulWidget` and the `setState()` method. For more complex scenarios involving animations, `AnimationController` and `TickerProviderStateMixin` are used to manage UI updates efficiently. This approach was chosen for its simplicity and sufficiency for the current scope of the application.

### 2.3. Local Storage: Hive

For on-device data persistence, StudyBuddy utilizes **Hive**, a lightweight and fast key-value database written in pure Dart. Hive was selected for several key advantages:

- **Performance:** It is significantly faster than other local storage options like `sqflite` or `shared_preferences` for most use cases.
- **Simplicity:** Its key-value nature makes it easy to store and retrieve Dart objects without writing complex SQL queries.
- **Native Dart:** Being a pure Dart solution, it integrates seamlessly into the Flutter environment without platform-specific dependencies.

The application uses three separate Hive "boxes" (analogous to tables) to logically segregate data:
- `notesBox`: For all user-generated content like notes, to-do items, and planner entries.
- `focusBox`: For storing focus session history, timer settings, and statistics.
- `profileBox`: For persisting user profile information.

## 3. Project Structure

The project follows a standard Flutter application structure, with the core logic residing in the `lib/` directory.

- `lib/`:
  - `main.dart`: The entry point of the application. It initializes Hive, registers the necessary type adapters, and opens the database boxes before running the app.
  - `assets/`: Contains static assets such as images (`.gif`) used for animations and branding.
  - `models/`:
    - `note_data.dart`: Defines the `NoteData` class, which is the primary data model used for storage in Hive. It includes a `TypeAdapter` for serialization.
    - `note_database.dart`: A service class that abstracts the interaction with the `notesBox`, providing methods for CRUD (Create, Read, Update, Delete) operations.
  - `screens/`: Contains the UI logic for each distinct view in the application (e.g., `homepage.dart`, `notes.dart`).
  - `shared/`: Contains reusable UI components (`TaskBar`, `PageTitle`) and constants (`AppPalette`) that are used across multiple screens to maintain a consistent look and feel.

## 4. Core Features (Detailed)

### 4.1. Splash Screen (`splash_screen.dart`)

- **Functionality:** This is the initial screen displayed on app launch. It features a fade and slide animation for the app's logo.
- **Implementation:** It uses an `AnimationController` to drive the animations. A `Timer` is set to control the duration of the splash screen, after which it navigates to the `Homepage` with a custom `PageRouteBuilder` for a smooth fade transition.

### 4.2. Homepage (`homepage.dart`)

- **Functionality:** The central dashboard of the application. It provides a dynamic and personalized overview of the user's study-related data.
- **Implementation:**
    - **Dynamic Greeting & Stats:** It fetches data from the `focusBox` and `profileBox` to display a personalized greeting, the current focus streak (consecutive days with focus sessions), and the total focus time for the current day.
    - **To-Do List:** It reads from the `notesBox` and filters for entries with a specific prefix (`__studybuddy_home_todo__::`). These entries are decoded to extract the task details and completion status. The list is sorted to show incomplete tasks first. Users can add, edit, and mark tasks as complete through a modal bottom sheet.
    - **Planner Preview:** It filters `notesBox` for planner entries (`__planner__::`) that fall within the next seven days. These are sorted by date and displayed to give the user a glimpse of their upcoming schedule.

### 4.3. Notes Management (`notes.dart`)

- **Functionality:** A dedicated section for creating, viewing, editing, and deleting general-purpose notes.
- **Implementation:**
    - **CRUD Operations:** It uses the `NoteDatabase` service to interact with the `notesBox`.
    - **UI:** Notes are displayed in a `GridView`. Tapping a note opens a detailed view, and a floating action button opens a dialog for creating a new note. The note editor allows users to set a title, content, and a custom block color for visual organization.
    - **Data Filtering:** This screen specifically filters out any entries that are identified as to-do or planner items by checking for their unique content prefixes.

### 4.4. Focus Timer (`focus.dart`)

- **Functionality:** A Pomodoro-style timer to help users manage study and break intervals.
- **Implementation:**
    - **Timer Logic:** A `Timer.periodic` is used to decrement the remaining time. The state (`_isRunning`, `_isPaused`, `_remainingSeconds`) is managed within the `_FocusMainState`.
    - **Customization:** Users can set custom durations for study and break periods through a settings dialog.
    - **State Persistence:** The timer's state (including remaining time and running status) is saved to the `focusBox` whenever the app is paused or closed. Upon reopening, it restores this state, allowing the timer to continue seamlessly, even accounting for the time elapsed while the app was inactive.
    - **Session Logging:** At the end of each study session, a record is saved to `focusBox`, including the start time, end time, duration, and completion status (`Completed` or `Stopped Early`). This data is used to calculate statistics like focus streaks and total study time.

### 4.5. Planner (`planner_board.dart`)

- **Functionality:** A comprehensive view of all scheduled tasks and events.
- **Implementation:**
    - **Tabbed View:** The `PlannerBoard` is the core UI, which is used by `PlannerTodayScreen`, `PlannerTomorrowScreen`, and `PlannerAllScreen`. It filters and displays planner entries based on the selected tab ('today', 'tomorrow', or 'all').
    - **Event Management:** Users can create new planner entries, specifying a title, location, details, and a precise date and time using native date and time pickers. Existing entries can be edited or deleted.
    - **Data Encoding:** Planner entries are stored in the `notesBox` with a `__planner__::` prefix and a custom payload format in the `content` field to store location and details.

### 4.6. Profile Management (`profile.dart`)

- **Functionality:** Allows users to view and manage their personal information.
- **Implementation:**
    - **Data Binding:** The screen reads and writes to the `profileBox` to manage user data like name, student ID, email, etc.
    - **Image Handling:** It uses the `image_picker` package to allow users to select a photo from their device's gallery. The selected image is converted to a Base64 string and stored in the `profileBox`. When displayed, the Base64 string is decoded back into an image.
    - **Edit Mode:** The UI toggles between a read-only view and an editable form, allowing for seamless updates to profile information.

## 5. Data Models and Database Schema

### 5.1. `NoteData` Model

This is the canonical object stored in the `notesBox`.

- `title`: `String` - The title of the note/task/event.
- `content`: `String` - The main body. A special prefix-based schema is used to differentiate data types:
    - **(no prefix)**: A standard note.
    - `__studybuddy_home_todo__::details||isDone`: A to-do task.
    - `__planner__::location||details`: A planner entry.
- `date`: `String` - The creation or event date, typically in ISO 8601 format for planner entries.
- `blockColorValue`: `int` - The ARGB integer value for the note's color.

### 5.2. Hive Box Schemas

- **`notesBox` (`Box<NoteData>`):** Stores `NoteData` objects. The key is an auto-incrementing integer managed by Hive.
- **`focusBox` (`Box<dynamic>`):** A key-value store for various focus-related data.
  - `studyHours`, `studyMinutes`, `studySeconds`: `int`
  - `breakHours`, `breakMinutes`, `breakSeconds`: `int`
  - `focusSessions`: `List<Map<String, dynamic>>` - A list of all completed sessions.
  - `isRunning`, `isPaused`: `bool` - For timer state restoration.
  - `remainingSeconds`: `int`
- **`profileBox` (`Box<dynamic>`):** A key-value store for profile fields.
  - `name`, `role`, `studentId`, etc.: `String`
  - `profilePhotoBase64`: `String` - The Base64-encoded profile image.


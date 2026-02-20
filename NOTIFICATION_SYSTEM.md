# Rental App Notification System

## Overview
We have implemented a robust, cross-platform notification system that works seamlessly on **Web**, **Android**, and **iOS**. This system handles notifications in all app states: Foreground, Background, and Terminated.

## Key Features Built

### 1. Unified Notification Service
- **File**: `lib/core/services/notification_service.dart`
- **Function**: A singleton service that initializes monitoring, requests permissions, and routes incoming messages to the correct display logic.
- **Global Access**: Uses a `navigatorKey` to inject notifications on top of any screen without needing context to be passed around.

### 2. "Top of Page" In-App Overlay (Foreground)
- **Behavior**: When the app is **OPEN** and you look at it.
- **Visual**: A beautiful, custom-designed notification card slides down from the top of the screen.
- **Style**: Matches your app's theme (colors, shadows, rounded corners).
- **Interaction**: Automatically dismisses after 4 seconds or can be tapped.
- **Platform**: Works on **BOTH** Web and Mobile.

### 3. Background Notifications (Web)
- **File**: `web/firebase-messaging-sw.js`
- **Behavior**: When the tab is **CLOSED** or **HIDDEN**.
- **Visual**: Standard browser system notification (e.g., Chrome toaster).
- **Mechanism**: A Service Worker runs in the browser background to catch incoming FCM messages even when the website isn't active.

### 4. Background Notifications (Mobile)
- **Behavior**: When the app is minimized or closed.
- **Visual**: Standard Native System Tray notification.
- **Mechanism**: Uses `flutter_local_notifications` to ensure compatibility with Android 13+ permissions and native behaviors.

---

## Notification Examples (What to Expect)

### Scenario A: App is Open (Foreground)
* You are browsing the "Rentals" page.
* **Event**: A backend trigger sends "Your Order #123 is Confirmed".
* **Result**: A **Grey/Themed Card** slides down from the very top of the app content with the title "Your Order #123 is Confirmed". It fades out after 4 seconds.

### Scenario B: App is in Background (Web)
* You have the Rental App tab open but you are looking at YouTube in another tab.
* **Event**: A backend trigger sends "New Item Available".
* **Result**: A **Chrome/Browser Notification** appears in the corner of your computer screen (outside the browser window). Clicking it opens/focuses the Rental App tab.

### Scenario C: App is Closed (Mobile)
* You are on your phone's home screen.
* **Event**: A backend trigger sends "Rental Request Received".
* **Result**: A **System Push Notification** appears in your lock screen or notification shade. Tapping it opens the app.

## Integration Details
- **Permissions**: The app automatically requests user permission (`POST_NOTIFICATIONS` on Android, Browser permission on Web) on the first launch.
- **FCM Token**: The unique device token is printed in the console on startup, which you use to target specific devices for testing in the Firebase Console.

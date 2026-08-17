# Eklavya.AI

Eklavya.AI is a learning app that helps users set goals, stay consistent, and complete tasks with AI-guided support.

This README is for a mentor or tester who wants to install the APK and check the app manually on a phone.

## How to install the APK

1. Download the APK file on the phone.
2. Open the APK file from your downloads or file manager.
3. If Android asks for permission to install apps from this source, allow it.
4. Tap Install.
5. Open the app after installation.

## Sign in

Use the test account shared with you.

If the app asks for login details, enter the provided email and password.

## If notifications were blocked

Sometimes Android shows the notification popup only once. If it was missed, follow these steps:

1. Open Android Settings.
2. Go to Apps.
3. Select Eklavya.AI.
4. Tap Notifications.
5. Turn notifications on.

This is useful if the mentor wants to see app reminders and updates after the app is installed.

## What the app is supposed to do

### Home
- Shows the user's progress
- Shows streak and XP updates
- Shows the next task to complete
- Lets the user open notifications and profile

### Goals
- Shows the user's learning goals
- Lets the user open a goal roadmap
- Lets the user archive old roads or remove a roadmap if needed

### Guru
- This is the roadmap generation chat
- The user can describe a goal and ask for a plan
- The app creates a structured learning roadmap from that input

### Coach
- This is for asking learning questions
- It helps explain a concept, task, or resource
- It is meant to support the user's learning while working through the roadmap

### Analytics
- Shows progress and performance information
- Helps the user track milestones and consistency

### Notifications
- Shows reminders and updates
- A user can open the bell icon from the home screen and view notifications from inside the app

## What to test as a mentor

Please check the following on the phone:

1. App opens successfully.
2. Login works with the provided account.
3. Home screen loads correctly.
4. Goals screen opens and shows active roadmaps.
5. Guru can generate or continue a roadmap.
6. Coach can answer a question.
7. A task can be started and completed.
8. XP and progress update after task completion.
9. Notifications open from the bell icon.
10. App continues to work with internet access.

## Important note

This APK is meant for testing on Android phones. The backend is already hosted, so the app should work from anywhere with internet access as long as the APK was built with the correct production backend URL.

## For Play Store later

This is a production-style APK for testing, not the final Google Play upload.

For the Play Store version, the app will need:
- a signed Android App Bundle
- a final version number
- proper app listing details
- screenshots and app icon
- privacy policy and store data disclosure

That part is separate from installing the APK for mentor testing.

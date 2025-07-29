# Budgeteer Setup Instructions

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: "Budgeteer" (or your preferred name)
4. Disable Google Analytics (optional for this project)
5. Click "Create project"

### 2. Add iOS App to Firebase

1. In your Firebase project, click the iOS icon (</>) to add an iOS app
2. Enter your iOS bundle ID (find this in Xcode: Target → General → Bundle Identifier)
   - Should be something like: `com.yourname.budgeteer`
3. Enter App Nickname: "Budgeteer"
4. App Store ID: Leave blank for now
5. Click "Register app"

### 3. Download Configuration File

1. Download the `GoogleService-Info.plist` file
2. **IMPORTANT**: Drag this file into your Xcode project
   - Select your project in Xcode
   - Drag the file into the project navigator
   - Make sure "Copy items if needed" is checked
   - Make sure your target is selected
   - Click "Finish"

### 4. Configure Authentication

1. In Firebase Console, go to "Authentication" → "Sign-in method"
2. Click on "Email/Password"
3. Enable the first option (Email/Password)
4. Click "Save"

### 5. Configure Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location closest to you
5. Click "Done"

### 6. Set up Security Rules (Optional but Recommended)

In Firestore → Rules, replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Users can only access their own expenses
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
      allow create: if request.auth != null &&
        request.auth.uid == request.resource.data.userId;
    }
  }
}
```

## Xcode Setup

### 1. Add Firebase SDK via Swift Package Manager

1. In Xcode, go to File → Add Package Dependencies
2. Enter this URL: `https://github.com/firebase/firebase-ios-sdk`
3. Click "Add Package"
4. Select these libraries (check the boxes):
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseFirestoreSwift
5. Click "Add Package"

### 2. Update Info.plist (if needed)

If you encounter any URL scheme issues, you may need to add URL schemes to your Info.plist. This is usually automatic, but if you have issues:

1. Open Info.plist
2. Add a new URL scheme with your REVERSED_CLIENT_ID from GoogleService-Info.plist

### 3. Test Your Setup

1. Build and run the app
2. Try creating a new account
3. Check Firebase Console → Authentication to see if the user was created
4. Add an expense and check Firestore to see if data is being saved

## Project Structure (Already Created)

```
budgeteer/
├── Views/
│   ├── LoginView.swift ✅
│   ├── SignupView.swift ✅
│   ├── DashboardView.swift ✅
│   ├── AddExpenseView.swift ✅
│   ├── ExpenseListView.swift ✅
│   └── SettingsView.swift ✅
├── Models/
│   ├── User.swift ✅
│   └── Expense.swift ✅
├── Services/
│   └── FirebaseService.swift ✅
├── ContentView.swift ✅
└── budgeteerApp.swift ✅
```

## Features Implemented ✅

### Authentication

- ✅ Email/Password login and signup
- ✅ Beautiful gradient-based UI
- ✅ Form validation and error handling
- ✅ Automatic authentication state management

### Dashboard

- ✅ Welcome header with user info
- ✅ Monthly budget vs spent progress bar
- ✅ Beautiful pie chart for category breakdown
- ✅ Recent expenses list
- ✅ Floating add expense button

### Add Expense

- ✅ Clean, card-based form design
- ✅ Category selection with icons and colors
- ✅ Success animation
- ✅ Beautiful gradient buttons

### Expense List

- ✅ Grouped by date
- ✅ Search functionality
- ✅ Category filtering
- ✅ Swipe to delete
- ✅ Beautiful list design

### Settings

- ✅ User profile section
- ✅ Budget management
- ✅ Spending statistics
- ✅ Sign out functionality

### Data Models

- ✅ User model with Firebase integration
- ✅ Expense model with categories
- ✅ Real-time data synchronization

## Categories with Icons

1. Food & Dining
2. Transportation
3. Shopping
4. Entertainment
5. Bills & Utilities
6. Healthcare
7. Travel
8. Other

## Design Features

- ✅ Beautiful gradient backgrounds
- ✅ Card-based layouts
- ✅ Smooth animations
- ✅ SF Symbols icons
- ✅ Color-coded categories
- ✅ Modern iOS design patterns
- ✅ Dark mode support (automatic)

## Troubleshooting

### Build Errors

1. Make sure `GoogleService-Info.plist` is added to your Xcode project
2. Check that Firebase packages are properly added
3. Clean build folder: Product → Clean Build Folder

### Authentication Issues

1. Check that Email/Password is enabled in Firebase Console
2. Verify your bundle ID matches between Xcode and Firebase

### Firestore Issues

1. Make sure Firestore is created in your Firebase project
2. Check security rules allow read/write for authenticated users

### Chart Display Issues

1. Make sure your iOS deployment target is 16.0 or higher
2. The Charts framework requires iOS 16+

## Next Steps (Optional Enhancements)

- Add expense editing functionality
- Implement data export features
- Add spending notifications
- Create budget alerts
- Add more chart types
- Implement expense categories customization

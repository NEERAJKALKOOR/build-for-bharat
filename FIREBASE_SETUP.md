# Firebase Setup Instructions

The app includes cloud backup functionality using Firebase.

## ⚠️ Important: Replace Dummy Firebase Config

The current Firebase configuration in `lib/firebase_options.dart` uses **dummy values** for development.

To enable cloud backup in production:

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "bharat-store" or similar
3. Add Android app with package name: `com.example.bharat_store`

### 2. Download google-services.json
1. In Firebase Console, go to Project Settings
2. Download `google-services.json` for Android
3. Place it in: `android/app/google-services.json`

### 3. Update firebase_options.dart
Run FlutterFire CLI to auto-generate proper config:
```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

This will update `lib/firebase_options.dart` with real API keys.

### 4. Enable Firestore Database
1. In Firebase Console, go to Firestore Database
2. Click "Create Database"
3. Choose "Start in production mode"
4. Select region closest to your users
5. Click "Enable"

### 5. Set Firestore Security Rules
In Firebase Console → Firestore Database → Rules, paste:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/backups/{backupId} {
      allow read, write: if request.auth != null
                         && request.resource.data.uid == userId;
    }
  }
}
```

### 6. Enable Anonymous Authentication
1. In Firebase Console → Authentication
2. Click "Get Started" (if first time)
3. Go to "Sign-in method" tab
4. Enable "Anonymous" provider
5. Click "Save"

## 🧪 Testing Cloud Backup

1. Open app and login with email OTP
2. Go to Settings → Cloud Backup
3. Enable "Cloud Backup" toggle
4. Click "Backup Now" - should upload to Firestore
5. Check Firebase Console → Firestore → users/{uid}/backups/latestBackup
6. Click "Restore Backup" to test download

## 📝 Notes

- Cloud backup is **manual only** - no auto-sync
- Uses anonymous auth for Firestore access
- User ID is SHA256 hash of email
- Backup includes: products, bills, settings, analytics
- Restore overwrites local data completely

## 🔒 Security

- Each user can only access their own backups
- Firestore rules enforce userId matching
- No passwords stored in Firebase
- Anonymous auth only for Firestore write permission

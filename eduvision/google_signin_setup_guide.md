# Google Sign-In Integration Guide for EduVision

This guide will walk you through setting up Google Sign-In for EduVision on both Android and iOS platforms.

## Prerequisites
- A Google Cloud Platform (GCP) project with Google Sign-In API enabled
- Firebase project linked to your application
- Flutter development environment set up

## Step 1: Configure Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project (or create a new one if needed)
3. Add Android and iOS apps to your project if not already done
   - Use the package name `com.example.eduvision` for Android
   - Use the appropriate Bundle ID for iOS

## Step 2: Generate SHA-1 and SHA-256 Fingerprints (Android)

For debugging:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

For release builds, use your signing key:
```bash
keytool -list -v -keystore <path-to-keystore> -alias <key-alias>
```

## Step 3: Add Fingerprints to Firebase

1. In Firebase Console, go to Project Settings > Your Android App
2. Scroll down to "SHA certificate fingerprints"
3. Click "Add fingerprint" and add both SHA-1 and SHA-256 values

## Step 4: Download Updated google-services.json

1. After adding the fingerprints, download the updated `google-services.json`
2. Replace the file in `android/app/google-services.json`

## Step 5: Configure Web Client ID

Ensure the `googleClientId` in `lib/config/api_config.dart` is correctly set to your Web Client ID from Google Cloud Console:

```dart
static const String googleClientId = 'your-web-client-id.apps.googleusercontent.com';
```

## Step 6: Update AndroidManifest.xml (If Needed)

Ensure your `android/app/src/main/AndroidManifest.xml` has proper Internet permissions:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Step 7: iOS Configuration (Info.plist)

For iOS, update your `ios/Runner/Info.plist` to include:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <!-- Copied from GoogleService-Info.plist -->
            <string>com.googleusercontent.apps.YOUR-CLIENT-ID</string>
        </array>
    </dict>
</array>
```

## Troubleshooting

If you're experiencing issues:

1. **App crashes during Google Sign-In**: Check that SHA fingerprints are correctly added and google-services.json is updated
2. **"Sign in failed" error**: Verify Google Sign-In API is enabled in Google Cloud Console
3. **Backend authentication fails**: Ensure the backend is correctly configured to accept Google tokens
4. **Silent sign-in not working**: Check if the user has granted permissions to your app

## Common Errors and Solutions

### PlatformException: sign_in_failed
- Verify SHA fingerprints in Firebase
- Check Google Play Services is up to date on the device
- Ensure the device has a Google account added

### Backend Authentication Errors
- Check network connectivity
- Verify token format and expiration
- Ensure backend can validate Google tokens

## Testing Google Sign-In

Use the built-in config screen by tapping "🔑 Cấu hình Google Login" on the login screen to:
- Verify your configuration
- Test sign-in process
- View detailed error information

---

For additional support, please consult the [Google Sign-In for Flutter documentation](https://pub.dev/packages/google_sign_in) or [Firebase Authentication documentation](https://firebase.google.com/docs/auth).

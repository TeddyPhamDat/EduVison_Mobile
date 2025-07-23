@echo off
echo ======================================
echo Checking SHA-1 Certificates for Google Sign-In
echo ======================================

echo.
echo === Debug certificate SHA-1 ===
cd android
call gradlew signingReport

echo.
echo === Verifying Google Play Services ===
echo Please ensure Google Play Services is up to date on your device.
echo To check manually, go to Settings > Apps > Google Play Services > App details
echo.

echo === Instructions to fix Google Sign-In ===
echo 1. Compare the SHA-1 above with what's in Firebase Console
echo 2. Make sure to add both debug and release SHA-1 fingerprints
echo 3. Update google-services.json after adding fingerprints
echo 4. Clean and rebuild the project
echo.

cd ..
echo Running Flutter clean...
call flutter clean

echo.
echo Fetching dependencies...
call flutter pub get

echo.
echo Rebuilding project...
call flutter build apk --debug

echo.
echo ======================================
echo Done! If Google Sign-In still fails:
echo 1. Check troubleshooting_guide.md
echo 2. Update Google Play Services on the test device
echo 3. Use a different device for testing
echo ======================================

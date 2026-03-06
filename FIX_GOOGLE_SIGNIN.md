# Fix Google Sign In Error

## The Problem
Error: `PlatformException(sign_in_failed, com.google.android.gms.common.api.j: 10)`
This means the SHA-1 fingerprint is not registered in Firebase Console.

## Solution Steps

### Step 1: Get SHA-1 Fingerprints

Open PowerShell in your project root and run:

**For Debug Build:**
```powershell
cd android
./gradlew signingReport
```

**Alternative method (if above doesn't work):**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**For Release Build (if you have a release keystore):**
```powershell
keytool -list -v -keystore "path/to/your/release.keystore" -alias your-key-alias
```

### Step 2: Copy the SHA-1 and SHA-256 Fingerprints

The output will look like:
```
Certificate fingerprints:
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
SHA256: ...
```

**Copy both SHA-1 and SHA-256 values.**

### Step 3: Add to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Project Settings** (gear icon)
4. Scroll down to **Your apps** section
5. Find your Android app: `com.rental.b3324.rental_app`
6. Click **Add fingerprint**
7. Paste the **SHA-1** value and click Save
8. Click **Add fingerprint** again
9. Paste the **SHA-256** value and click Save

### Step 4: Download Updated google-services.json

1. In Firebase Console, after adding fingerprints
2. Click the **Download google-services.json** button
3. Replace the file at: `d:\Rental_main1\android\app\google-services.json`

### Step 5: Rebuild APK

```powershell
flutter clean
flutter pub get
flutter build apk --release
```

Or for debug:
```powershell
flutter build apk --debug
```

### Step 6: Install and Test

```powershell
flutter install
```

---

## Important Notes

- **Debug vs Release**: If you're building debug APK, use debug keystore SHA-1. For release APK, use release keystore SHA-1.
- **Add Both**: Add both debug AND release SHA-1 fingerprints to Firebase for flexibility.
- Your package name is: `com.rental.b3324.rental_app` - make sure this matches in Firebase.

## Still Having Issues?

1. **Check package name**: Ensure `com.rental.b3324.rental_app` is registered in Firebase
2. **Enable Google Sign-In**: In Firebase Console → Authentication → Sign-in method → Google → Enable
3. **Wait**: Sometimes it takes 5-10 minutes for Firebase changes to propagate
4. **Clear cache**: Uninstall the app completely before reinstalling

## Quick Command Reference

```powershell
# Get SHA-1 (Method 1)
cd android; ./gradlew signingReport

# Get SHA-1 (Method 2 - Debug)
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# Rebuild
flutter clean; flutter pub get; flutter build apk

# Install
flutter install
```

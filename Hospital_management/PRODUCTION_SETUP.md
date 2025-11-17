# Production Setup Guide - Hospital Management System

This document ensures your app works in **real production**, not just as a demo/project.

## ✅ Current Status

Your app is **already configured** for real Firebase services:
- **Project ID**: `hospital-management-syst-75183`
- **Storage Bucket**: `hospital-management-syst-75183.firebasestorage.app`
- **Auth Domain**: `hospital-management-syst-75183.firebaseapp.com`

## 🔧 Required Firebase Console Configurations

### 1. Password Reset Emails (CRITICAL)

#### Step 1: Enable Email/Password Authentication
1. Go to [Firebase Console](https://console.firebase.google.com/project/hospital-management-syst-75183/authentication/providers)
2. Click **Authentication** → **Sign-in method**
3. Enable **Email/Password** provider
4. Click **Save**

#### Step 2: Configure Email Templates
1. Go to **Authentication** → **Templates** tab
2. Click **Password reset** template
3. Verify the template is enabled and customize if needed:
   - **From name**: Hospital Management System
   - **Reply-to email**: Your support email (optional)
4. Click **Save**

#### Step 3: Verify Authorized Domains
1. Go to **Authentication** → **Settings** → **Authorized domains**
2. Ensure these domains are listed:
   - `localhost` (for development)
   - `hospital-management-syst-75183.firebaseapp.com` (auto-added)
   - Any custom domain you're using
3. Add your domain if deploying to web

#### Step 4: Test Password Reset
```bash
# Run the app
cd Hospital_management
flutter run -d chrome

# Then:
1. On login screen, click "Forgot password?"
2. Enter a valid email from your Firebase Auth users
3. Check your email inbox AND spam folder
4. Look for email from: noreply@hospital-management-syst-75183.firebaseapp.com
```

**Debug if email not received:**
- Check Firestore collection `debug_auth_resets/{sanitized_email}` for logs
- Verify the email exists in Firebase Console → Authentication → Users
- Check spam/junk folder
- Verify email template is enabled in Firebase Console
- For Gmail: check "All Mail" folder

---

### 2. Profile Photo Upload (Storage)

#### Step 1: Configure Storage Rules
1. Go to [Firebase Console Storage](https://console.firebase.google.com/project/hospital-management-syst-75183/storage)
2. Click **Rules** tab
3. Replace with these production-safe rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Profile photos - authenticated users can read/write their own
    match /profile_photos/{userId}/{fileName} {
      allow read: if true; // Anyone can view profile photos
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024  // Max 5MB
                   && request.resource.contentType.matches('image/.*');
    }
    
    // Patient prescriptions - authenticated users can upload their own
    match /patient_prescriptions/{userId}/{fileName} {
      allow read: if request.auth != null 
                  && (request.auth.uid == userId || 
                      exists(/databases/$(database)/documents/users/$(request.auth.uid)) 
                      && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'doctor');
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024  // Max 10MB
                   && (request.resource.contentType.matches('image/.*') 
                       || request.resource.contentType == 'application/pdf');
    }
    
    // Deny all other access
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

4. Click **Publish**

#### Step 2: Enable CORS for Web
Run this command in your terminal (requires `gsutil` from Google Cloud SDK):

```bash
# Install Google Cloud SDK if not installed
# macOS: brew install google-cloud-sdk
# Then authenticate:
gcloud auth login

# Create cors.json file
cat > /tmp/cors.json << 'EOF'
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"]
  }
]
EOF

# Apply CORS configuration
gsutil cors set /tmp/cors.json gs://hospital-management-syst-75183.firebasestorage.app
```

**Alternative (if gsutil not available):**
CORS is usually auto-configured for Firebase Storage. If uploads fail with CORS errors:
1. Check browser DevTools Network tab for the actual error
2. Contact Firebase support to enable CORS for your bucket

#### Step 3: Test Photo Upload
```bash
# Run the app
flutter run -d chrome

# Then:
1. Sign in as patient or doctor
2. Click the edit icon on the profile avatar
3. Choose a small JPG image (< 1MB)
4. Watch for:
   - Immediate preview (MemoryImage)
   - Success SnackBar message
   - Persisted photo after page reload
5. Verify in Firebase Console:
   - Storage → profile_photos/{uid}/{timestamp}.jpg exists
   - Firestore → users/{uid} → photoUrl field contains URL
   - Firestore → debug_uploads/{uid} shows upload details
```

---

### 3. Firestore Database Rules

#### Step 1: Configure Firestore Security Rules
1. Go to [Firestore Rules](https://console.firebase.google.com/project/hospital-management-syst-75183/firestore/rules)
2. Replace with production-safe rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - users can read/write their own document
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Notifications subcollection
      match /notifications/{notificationId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Doctors collection - doctors can write their own, anyone can read
    match /doctors/{doctorId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == doctorId;
    }
    
    // Appointments - patients and doctors can read/write their own
    match /appointments/{appointmentId} {
      allow read: if request.auth != null 
                  && (resource.data.patientId == request.auth.uid 
                      || resource.data.doctorId == request.auth.uid);
      allow create: if request.auth != null 
                    && request.resource.data.patientId == request.auth.uid;
      allow update: if request.auth != null 
                    && (resource.data.patientId == request.auth.uid 
                        || resource.data.doctorId == request.auth.uid);
    }
    
    // Prescriptions - patients can write their own, doctors can read
    match /prescriptions/{prescriptionId} {
      allow read: if request.auth != null 
                  && (resource.data.patientId == request.auth.uid 
                      || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'doctor');
      allow create: if request.auth != null 
                    && request.resource.data.patientId == request.auth.uid;
    }
    
    // Chats - participants can read/write
    match /chats/{chatId} {
      allow read, write: if request.auth != null 
                         && request.auth.uid in resource.data.participants;
      
      match /messages/{messageId} {
        allow read, write: if request.auth != null 
                           && request.auth.uid in get(/databases/$(database)/documents/chats/$(chatId)).data.participants;
      }
    }
    
    // Debug collections (remove in production or restrict to admins)
    match /debug_uploads/{userId} {
      allow read, write: if request.auth != null;
    }
    
    match /debug_auth_resets/{docId} {
      allow read, write: if request.auth != null;
    }
    
    // Audit logs
    match /audit_logs/{logId} {
      allow read: if request.auth != null;
      allow write: if false; // Only server can write
    }
  }
}
```

3. Click **Publish**

---

## 🧪 Production Verification Checklist

Use the built-in diagnostics tool to verify everything works:

### Method 1: In-App Diagnostics
1. Run the app: `flutter run -d chrome`
2. Sign in as patient or doctor
3. Open **Drawer** → **Diagnostics (dev)**
4. Verify you see real data from Firestore

### Method 2: Manual Testing

#### Test 1: Password Reset Email
- [ ] Click "Forgot password?" on login screen
- [ ] Enter a registered email
- [ ] See masked email confirmation (e.g., "jo**@example.com")
- [ ] **Receive actual email** in inbox (check spam)
- [ ] Click reset link in email
- [ ] Successfully reset password
- [ ] Verify `debug_auth_resets/{email}` shows `status: sent`

#### Test 2: Profile Photo Upload
- [ ] Sign in as patient
- [ ] Click edit icon on avatar
- [ ] Choose "Take Photo" (mobile) or "Choose file" (web)
- [ ] Select a JPG < 1MB
- [ ] See immediate preview
- [ ] See success SnackBar with Storage URL
- [ ] Reload page → photo persists
- [ ] Check Firebase Console Storage → file exists
- [ ] Check Firestore `users/{uid}.photoUrl` → URL exists
- [ ] Check `debug_uploads/{uid}` → shows upload details

#### Test 3: Prescription Upload (Patient)
- [ ] Sign in as patient
- [ ] Go to Medical Reports → Prescriptions tab
- [ ] Click Upload button
- [ ] Choose a PDF or image < 10MB
- [ ] See success message
- [ ] Verify in Firestore `prescriptions` collection
- [ ] Verify in Storage `patient_prescriptions/{uid}/...`

---

## 🚨 Common Issues & Solutions

### Issue 1: "No email received for password reset"

**Cause**: Email template disabled or domain not authorized

**Solution**:
1. Firebase Console → Authentication → Templates → Enable "Password reset"
2. Check spam folder
3. Verify authorized domains include your app's domain
4. Check `debug_auth_resets` collection for error messages
5. For custom domains, add them to authorized domains list

**Debug console command**:
```dart
// Check if email was sent
debugPrint('Sending password reset to: $emailToUse');
```

---

### Issue 2: "Profile photo upload fails or doesn't persist"

**Cause**: Storage rules block uploads or CORS issue

**Solution**:
1. Firebase Console → Storage → Rules → Apply rules from above
2. Check browser DevTools Console for CORS errors
3. Check `debug_uploads/{uid}` for error details
4. Verify user is signed in (FirebaseAuth.instance.currentUser != null)
5. Check Storage bucket name matches `firebase_options.dart`

**Test upload manually**:
Open browser console and check Network tab for Storage PUT requests:
- Status 200 = Success
- Status 403 = Rules rejection
- Status CORS error = CORS configuration needed

---

### Issue 3: "Image shows immediately but disappears after reload"

**Cause**: Cache-busting not working or Firestore write failed

**Solution**:
1. Check `users/{uid}.photoUrl` in Firestore Console
2. Verify the URL includes `?ts={timestamp}` query param
3. Check `debug_uploads/{uid}.savedPhotoUrl` field
4. Try hard-refresh (Cmd+Shift+R / Ctrl+Shift+F5)

---

## 🚀 Deployment to Production

### Web Deployment (Firebase Hosting)
```bash
# Build for web
cd Hospital_management
flutter build web --release

# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize (if not done)
firebase init hosting
# Select: hospital-management-syst-75183
# Public directory: build/web
# Single-page app: Yes
# Overwrite index.html: No

# Deploy
firebase deploy --only hosting

# Your app will be live at:
# https://hospital-management-syst-75183.web.app
```

### Mobile Deployment

#### Android
```bash
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
# Upload to Google Play Console
```

#### iOS
```bash
flutter build ios --release
# Open in Xcode and upload to App Store Connect
```

---

## 📊 Monitoring & Analytics

1. **Firebase Console → Analytics**
   - Track user sign-ups, logins, photo uploads
   
2. **Crashlytics** (optional)
   ```bash
   flutter pub add firebase_crashlytics
   # Follow setup guide
   ```

3. **Performance Monitoring** (optional)
   ```bash
   flutter pub add firebase_performance
   ```

---

## 🔒 Production Security Checklist

- [x] Storage rules restrict access to user's own files
- [x] Firestore rules prevent unauthorized reads/writes
- [x] Password reset requires valid email in database
- [x] File size limits enforced (5MB photos, 10MB prescriptions)
- [x] File type validation (only images/PDFs)
- [ ] Remove or secure debug collections (`debug_uploads`, `debug_auth_resets`)
- [ ] Enable App Check (optional, prevents abuse)
- [ ] Set up billing alerts in Firebase Console
- [ ] Review Firebase Console → Usage for quota limits

---

## 📞 Support

If issues persist after following this guide:

1. **Check debug collections in Firestore**:
   - `debug_uploads/{uid}` - Photo upload logs
   - `debug_auth_resets/{email}` - Password reset logs

2. **Browser DevTools**:
   - Console tab: Look for error messages
   - Network tab: Check Firebase API calls (200 = success, 403 = rules issue)

3. **Firebase Console Logs**:
   - Functions → Logs (if using Cloud Functions)
   - Storage → Usage & monitoring

4. **Test with a fresh account**:
   - Create new test user
   - Try upload/reset with no cached data

---

## ✅ Final Verification

Run this command to test everything:

```bash
cd Hospital_management
flutter run -d chrome

# Then perform:
# 1. Sign up new account
# 2. Upload profile photo
# 3. Sign out
# 4. Click "Forgot password"
# 5. Check email
# 6. Reset password
# 7. Sign in with new password
# 8. Verify photo persists
```

**All features should work end-to-end in real production!**

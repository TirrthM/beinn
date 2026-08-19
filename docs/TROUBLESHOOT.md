# Troubleshooting Guide

Common issues encountered by developers setting up the Beinn platform locally.

## Frontend (Flutter)

### Issue: CocoaPods failing to install on macOS (Apple Silicon)
**Error:** `LoadError - dlsym(0x7f8..., Init_ffi_c): Symbol not found`
**Fix:** 
Ensure you are running the `ffi` gem natively.
```bash
sudo arch -x86_64 gem install ffi
cd ios && arch -x86_64 pod install
```

### Issue: Firebase Initialization Crash
**Error:** `Default FirebaseApp is not initialized in this process.`
**Fix:**
Ensure you have downloaded the `google-services.json` and `GoogleService-Info.plist` from the Firebase console and placed them in the correct `android/app` and `ios/Runner` directories.

## Backend (NestJS / Postgres)

### Issue: PostGIS Functions Missing
**Error:** `function st_distance(geometry, geometry) does not exist`
**Fix:**
The database does not have the PostGIS extension installed. Connect to your database and run:
```sql
CREATE EXTENSION postgis;
```

### Issue: Razorpay Signature Validation Fails
**Error:** `Invalid webhook signature`
**Fix:**
Ensure your `.env` file contains the correct `RAZORPAY_KEY_SECRET` matching the webhook secret configured in your Razorpay developer dashboard. Local testing requires exposing your localhost port via Ngrok for webhooks to reach your machine.

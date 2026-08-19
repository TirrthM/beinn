# Deployment Guide

This guide details how to deploy the various components of the Beinn platform to a production environment.

## 1. Backend (NestJS, Postgres, Redis)

The backend is containerized using Docker and is designed to run on scalable orchestration platforms (e.g., AWS ECS, Google Cloud Run, or Kubernetes).

### Prerequisites
- Managed PostgreSQL Database with the **PostGIS** extension enabled (e.g., AWS RDS, Supabase).
- Managed Redis instance (e.g., AWS ElastiCache, Upstash).

### Steps
1. Build the Docker image:
   ```bash
   docker build -t beinn-backend ./backend
   ```
2. Set up environment variables in your hosting provider matching `.env.example`.
3. Ensure Firebase Admin SDK JSON credentials are securely injected via a secret manager or base64 encoded env var.
4. Deploy the image.
5. Run database migrations: `npm run typeorm migration:run`.

## 2. Real-time Infrastructure (Firebase)

1. Create a Firebase Project.
2. Enable Authentication (Email/Password & Google).
3. Provision a Cloud Firestore database.
4. Deploy the Firestore security rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

## 3. Frontend (Flutter Mobile App)

### Android (Google Play Store)
1. Update the `versionName` and `versionCode` in `pubspec.yaml`.
2. Ensure you have your production `google-services.json` in `android/app/`.
3. Create a `.jks` keystore and configure `key.properties`.
4. Build the App Bundle:
   ```bash
   flutter build appbundle --release
   ```
5. Upload the `.aab` file to the Google Play Console.

### iOS (Apple App Store)
1. Ensure your production `GoogleService-Info.plist` is in `ios/Runner/`.
2. Update provisioning profiles and certificates in Xcode.
3. Build the IPA:
   ```bash
   flutter build ipa --release
   ```
4. Upload via Xcode or Transporter to App Store Connect.

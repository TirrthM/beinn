# Beinn: E-Commerce and Delivery Platform

## Overview

Beinn is a full-stack e-commerce and delivery platform focused on modern retail. The project is split into two primary components: a cross-platform mobile application developed with Flutter, and a high-performance backend microservice architecture developed with NestJS. 

The platform provides a unified experience handling the customer storefront, seamless checkout, and a specialized interface for delivery drivers to receive dispatch assignments and track deliveries in real-time.

## Key Features

### Customer Storefront
*   Rich Product Catalog: Browse products with categorized feeds and engaging UI components.
*   Seamless Authentication: Secure login via Firebase Auth (Email/Password and Google Sign-In).
*   Secure Payments: Native Razorpay integration for fast, compliant checkout experiences.
*   Live Order Tracking: Real-time map tracking of deliveries using flutter_map and Socket.IO.

### Delivery Driver Interface
*   Real-Time Dispatch: Receive and accept delivery assignments dynamically.
*   Background Geolocation: Accurate driver tracking in the background using flutter_background_geolocation.
*   Smart Routing: Geofencing and route optimization handled via PostgreSQL and PostGIS.

### Backend Infrastructure
*   High-Frequency Real-Time Engine: WebSocket integration for instant state updates.
*   Secure Transaction Handling: Server-side Razorpay order generation and webhook verification.
*   Geospatial Queries: PostgreSQL with PostGIS for fast spatial lookups.

## Technology Stack

*   Frontend: Flutter (Dart)
*   Backend: NestJS (TypeScript / Node.js)
*   Database: PostgreSQL (with PostGIS)
*   Caching & WebSockets: Redis, Socket.IO
*   Cloud Services: Firebase (Auth, Firestore, Analytics)

## Development Setup

### Prerequisites
*   Flutter SDK: Version 3.44.4 or higher
*   Node.js: Version 18.x or higher
*   PostgreSQL: With PostGIS extension installed locally
*   Redis: A local Redis server instance

### 1. Backend Configuration
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install Node dependencies:
   ```bash
   npm install
   ```
3. Configure Environment Variables:
   Create a `.env` file in the `backend/` directory and define:
   * `RAZORPAY_KEY_ID`
   * `RAZORPAY_KEY_SECRET`
   * `DATABASE_URL`
   * `REDIS_URL`
   * `FIREBASE_ADMIN_CREDENTIALS` (absolute path to `serviceAccountKey.json`)
4. Start the development server:
   ```bash
   npm run start:dev
   ```

### 2. Frontend Configuration
1. Navigate to the project root:
   ```bash
   cd ..
   ```
2. Configure Environment Variables:
   Create a `.env` file in the project root:
   ```env
   RAZORPAY_KEY_ID=rzp_test_YourKeyHere
   BACKEND_API_URL=http://localhost:3000
   ```
3. Firebase Configuration:
   * Place your `google-services.json` in `android/app/`
   * Place your `GoogleService-Info.plist` in `ios/Runner/`
4. Fetch dependencies and run:
   ```bash
   flutter pub get
   flutter run
   ```

## CI/CD Pipeline

We use GitHub Actions for continuous integration. Every push or pull request to the `main` branch triggers a workflow that runs:
*   Dart formatter (with automatic pull requests for formatting changes).
*   Static code analysis (`flutter analyze`).
*   Automated test suite (`flutter test`).
*   Release APK build verification.

Note: Since the `.env` file is excluded via `.gitignore` for security, the CI pipeline automatically generates a blank `.env` placeholder to ensure the Flutter analyzer completes successfully.

# Beinn

**A full-stack e-commerce and delivery platform for modern retail fashion and fragrance — built with Flutter, NestJS, PostgreSQL, Firebase, and Socket.IO.**

Beinn eliminates the friction between digital storefronts and physical logistics. Instead of relying on disconnected third-party delivery services and generic shopping carts, this platform consolidates the entire lifecycle—from browsing oversized t-shirts to real-time driver tracking—into a single, highly performant ecosystem.

---

## Table of Contents

- [Problem Statement](#problem-statement)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Project Structure](#project-structure)
- [Data Model](#data-model)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [API & WebSocket Reference](#api--websocket-reference)
- [Design Decisions](#design-decisions)
- [License](#license)

---

## Problem Statement

Modern e-commerce brands often struggle to maintain a unified user experience when handling hyper-local deliveries. They face several unique challenges:

1. **Disconnected logistics**: The storefront and the delivery tracking systems are typically separated, leading to disjointed user experiences.
2. **High-frequency updates**: Tracking active deliveries requires massive real-time coordination which can exhaust traditional database read/write quotas.
3. **Complex geospatial matching**: Routing orders to the nearest available driver requires sophisticated geofencing and proximity calculations.
4. **Seamless payments**: Checkout flows must handle high-volume drop events securely without relying on redirect-heavy payment gateways.
5. **Cross-platform UI consistency**: Maintaining high-fidelity animations and complex layouts across both iOS and Android natively.

Beinn addresses all of these problems as first-class features within a unified codebase.

---

## Architecture

```text
Client (Flutter Mobile App)
    |
    v
API Gateway & State Synchronization
    |
    +-- Firebase Authentication (Email/Password, Google)
    +-- Cloud Firestore (Catalog, User Profiles, Order State)
    |       |
    |       +-- Real-time UI updates via Streams
    |       |
    |       v
    +-- NestJS Backend Service (Node.js)
            |
            v
        REST & WebSocket Controller Layer
            |
            +-- auth.ts       (JWT generation, signature validation)
            +-- order.ts      (Razorpay generation, secure checkouts)
            +-- tracking.ts   (Socket.IO real-time location streaming)
            +-- dispatch.ts   (PostGIS proximity matching)
            |
            v
        PostgreSQL (with PostGIS) + Redis
```

The application utilizes a hybrid architectural approach. Firebase handles client-heavy, low-latency data streams (like product catalogs and profile syncs) directly to the Flutter app. The custom NestJS backend handles secure transactions, complex geospatial calculations, and high-frequency WebSocket traffic that would otherwise overwhelm NoSQL document quotas.

---

## Tech Stack

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| Frontend Framework | Flutter | 3.44+ | Cross-platform mobile UI |
| Frontend Language | Dart | 3.6+ | End-to-end client logic |
| Backend Framework | NestJS | 10.0+ | Microservice architecture and REST API |
| Backend Language | TypeScript | 5.0+ | Server-side type safety |
| Primary Database | PostgreSQL | 14.0+ | Relational data and geospatial queries (PostGIS) |
| Client Sync Database| Cloud Firestore | - | Real-time NoSQL data synchronization |
| Caching & Events | Redis | 7.0+ | High-speed data caching and WebSocket state |
| Payments | Razorpay | - | Secure INR checkouts and webhooks |
| Authentication | Firebase Auth | - | Identity management and OAuth |
| Maps & Location | flutter_map | 6.2+ | Native map rendering and routing |

---

## Features

### Customer Storefront

- Engaging, animated UI for browsing oversized t-shirts, hoodies, sweatshirts, and perfumes.
- Real-time catalog updates synchronized directly from Cloud Firestore.
- Seamless, native checkout flows utilizing Razorpay for secure payment capture.
- Live order tracking interface displaying the delivery driver's real-time location.
- Rich animations utilizing Lottie and SVG rendering.

### Delivery Driver Interface

- Specialized driver dashboard for receiving dynamic dispatch assignments.
- Battery-efficient background geolocation tracking ensuring accurate location data even when the app is minimized.
- Real-time navigation routing and geofencing validation.
- Earnings and order history tracking.

### Backend Logistics & Dispatch

- High-frequency tracking engine using Socket.IO to manage driver location streams without exhausting database quotas.
- Geospatial engine utilizing PostGIS to calculate proximity, manage geofences, and optimize routes.
- Webhook verification endpoints ensuring cryptographic security for all Razorpay transactions.
- Automated push notifications dispatched via Firebase Cloud Messaging (FCM).

### CI/CD Pipeline

- Fully automated GitHub Actions workflow triggered on every push and pull request.
- Automatic Dart formatting with automatic PR generation for styling fixes.
- Deep static analysis via `flutter analyze` ensuring strict type and linting compliance.
- Automated widget and unit testing (`flutter test`).
- Dummy `.env` placeholder generation to bypass strict asset validation during CI runs.

---

## Project Structure

```text
.
├── android/                   # Native Android configuration
├── ios/                       # Native iOS configuration
├── lib/                       # Flutter Application Source
│   ├── main.dart              # Application entry point
│   ├── models/                # Dart data structures
│   ├── data/                  # Static mocks and configurations
│   ├── screens/               # UI Views (Storefront, Checkout, Driver)
│   ├── widgets/               # Reusable UI components
│   └── services/              # API clients and Firebase wrappers
├── assets/                    # Static media
│   └── images/                # Product imagery (hoodies, t-shirts, perfume)
├── backend/                   # NestJS Application Source
│   ├── src/
│   │   ├── app.module.ts      # Root backend module
│   │   ├── auth/              # JWT and security logic
│   │   ├── orders/            # Razorpay integration
│   │   └── tracking/          # Socket.IO gateways and PostGIS queries
│   ├── package.json           # Backend dependencies
│   └── .env.example           # Example backend configuration
├── .github/
│   └── workflows/             # GitHub Actions CI/CD pipelines
├── pubspec.yaml               # Flutter dependencies and assets
└── README.md                  # This file
```

---

## Data Model

The application leverages a hybrid data model across Firestore and PostgreSQL:

| Model | Database | Key Fields |
|---|---|---|
| `User` | Firestore | `uid`, `displayName`, `email`, `role` (CUSTOMER/DRIVER) |
| `Product` | Firestore | `id`, `name`, `category`, `price`, `stockCount`, `imageUrls` |
| `Order` | Postgres | `orderId`, `userId`, `amount`, `status`, `razorpaySignature` |
| `DriverLocation`| Redis/Postgres| `driverId`, `lat`, `lng`, `geog` (PostGIS point), `timestamp` |

---

## Getting Started

### Prerequisites

- Flutter SDK (v3.44.4 or higher)
- Node.js (v18.x or higher)
- PostgreSQL (with PostGIS extension)
- Redis Server

### Installation

```bash
# Clone the repository
git clone https://github.com/TirrthM/beinn.git
cd beinn

# 1. Setup Backend
cd backend
npm install
# Configure your backend .env file here
npm run start:dev

# 2. Setup Frontend
cd ..
flutter pub get
# Configure your root .env file and Firebase service files here
flutter run
```

---

## Environment Configuration

To run both services locally, configure the following variables. Do not commit these files to version control.

### Frontend (`/.env`)
```env
RAZORPAY_KEY_ID=rzp_test_YourKeyHere
BACKEND_API_URL=http://localhost:3000
```
*(Ensure `google-services.json` and `GoogleService-Info.plist` are placed in their respective native directories).*

### Backend (`/backend/.env`)
```env
RAZORPAY_KEY_ID="rzp_test_your_key_id"
RAZORPAY_KEY_SECRET="your_razorpay_secret"
DATABASE_URL="postgres://user:password@localhost:5432/beinn"
REDIS_URL="redis://localhost:6379"
FIREBASE_ADMIN_CREDENTIALS="/absolute/path/to/serviceAccountKey.json"
```

---

## API & WebSocket Reference

### REST Endpoints (`/api/v1/*`)

| Endpoint | Method | Description |
|---|---|---|
| `/orders/create` | POST | Generates a secure Razorpay order ID |
| `/orders/verify` | POST | Validates the Razorpay webhook signature |
| `/dispatch/nearest`| GET | Queries PostGIS for the closest active driver |

### WebSocket Events (`/tracking`)

| Event Name | Direction | Payload |
|---|---|---|
| `location_update` | Client -> Server | `{ driverId, lat, lng, timestamp }` |
| `order_assigned` | Server -> Client | `{ orderId, pickupLocation, deliveryLocation }` |

---

## Design Decisions

### Why Flutter?
Flutter was selected to ensure a visually identical, highly performant experience across both iOS and Android. The platform requires complex, fluid animations and intricate map rendering which Flutter handles natively via its Skia/Impeller graphics engine, eliminating the overhead of web-view based frameworks.

### Why a Hybrid Firebase + NestJS Backend?
Firebase Cloud Firestore is unparalleled for synchronizing real-time catalog and profile data directly to the client with zero boilerplate. However, Firestore becomes prohibitively expensive and inefficient for high-frequency GPS tracking and complex geospatial proximity queries. NestJS paired with PostgreSQL (PostGIS) and Redis elegantly solves the tracking and secure payment requirements, resulting in a perfectly balanced architectural hybrid.

---

## License

Copyright 2026 Beinn. All rights reserved.

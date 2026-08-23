# Beinn

**A full-stack e-commerce and delivery platform for modern retail fashion and fragrance — built with Flutter, NestJS, PostgreSQL, Firebase, and Socket.IO.**

Beinn eliminates the friction between digital storefronts and physical logistics. Instead of relying on disconnected third-party delivery services and generic shopping carts, this platform consolidates the entire lifecycle—from browsing oversized t-shirts to real-time driver tracking—into a single, highly performant ecosystem.

---

## Table of Contents

- [Problem Statement](#problem-statement)
- [Product Model](#product-model)
- [Product Surface](#product-surface)
- [Commercial Model](#commercial-model)
- [Data Policy](#data-policy)
- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Project Structure](#project-structure)
- [Data Model](#data-model)
- [Getting Started](#getting-started)
- [Available Commands](#available-commands)
- [Environment Configuration](#environment-configuration)
- [Testing and Completion](#testing-and-completion)
- [Security](#security)
- [Data Sources and External APIs](#data-sources-and-external-apis)
- [API & WebSocket Reference](#api--websocket-reference)
- [Design Decisions](#design-decisions)
- [Documentation](#documentation)
- [Disclaimer](#disclaimer)
- [License](#license)

---

## Problem Statement

Modern e-commerce brands often struggle to maintain a unified user experience when handling hyper-local deliveries. They face several unique challenges:

1. **Disconnected logistics**: The storefront and the delivery tracking systems are typically separated, leading to disjointed user experiences. Customers have to jump between shopping apps and tracking links.
2. **High-frequency updates**: Tracking active deliveries requires massive real-time coordination which can exhaust traditional database read/write quotas, resulting in massive scaling costs.
3. **Complex geospatial matching**: Routing orders to the nearest available driver requires sophisticated geofencing, proximity calculations, and radius-based bounding boxes.
4. **Seamless payments**: Checkout flows must handle high-volume drop events securely without relying on redirect-heavy payment gateways that reduce conversion rates.
5. **Cross-platform UI consistency**: Maintaining high-fidelity animations and complex layouts across both iOS and Android natively is historically difficult with separate codebases.

Beinn addresses all of these problems as first-class features within a unified codebase, ensuring absolute synergy between the point-of-sale and the point-of-delivery.

---

## Product Model

```mermaid
flowchart LR
  A[Customer Storefront] --> B[Browse & Checkout]
  B --> C[Razorpay Payment]
  C --> D[Backend Dispatch]
  D --> E[Driver Assigned]
  E --> F[Real-time Tracking]
  F --> G[Delivery Completed]
  C --> H[Analytics & Metrics]
```

## Product Surface

- Public product storefront
- Customer browsing and checkout workflows
- Driver profile and delivery dashboard
- Real-time location tracking interface
- Backend order and dispatch orchestration
- Geofencing and proximity matching boundaries

## Commercial Model

The application models Customer, Driver, and Admin roles. Plan entitlements and role configurations control real product access and limits. Payment processing via Razorpay is not represented as live until actual production API credentials are provided.

## Data Policy

Production metrics must come from persisted application data. No dashboard number is treated as authoritative merely because it is present in source code. Synthetic data may be used for controlled development fixtures only when explicitly identified as synthetic and kept separate from production evidence.

---

## Architecture

```mermaid
flowchart TD
  subgraph Client [Client Applications]
    C[Customer Storefront\nFlutter iOS/Android]
    D[Driver Interface\nFlutter iOS/Android\nBackground Geolocation]
  end

  subgraph Firebase [Firebase Cloud Services]
    FA[Authentication\nEmail/Password, Google]
    FCM[Cloud Messaging\nPush Notifications]
    CF[(Cloud Firestore\nNoSQL)]
    CF_CAT[Catalog / Products]
    CF_PROF[User Profiles]
    CF_ORD[Order State]
    CF --- CF_CAT & CF_PROF & CF_ORD
  end

  subgraph NestJS [NestJS Backend Microservices]
    API[API Gateway]
    REST[REST Controller Layer]
    WS[WebSocket Gateway]
    
    auth[auth.ts\nJWT & Signature Validation]
    order[order.ts\nRazorpay Secure Checkouts]
    track[tracking.ts\nSocket.IO Location Streams]
    disp[dispatch.ts\nPostGIS Proximity Matching]
    
    API --> REST & WS
    REST --> auth & order
    WS --> track & disp
  end

  subgraph Persistence [Data Persistence]
    PG[(PostgreSQL 14+\nACID Transactions)]
    POSTGIS[(PostGIS\nGeospatial Engine)]
    REDIS[(Redis 7+\nEphemeral State & Caching)]
    
    PG --- POSTGIS
  end
  
  subgraph External [External Providers]
    RZP[Razorpay\nPayment Gateway]
  end

  %% Client to Firebase Sync
  C & D -->|Login / Auth| FA
  C & D <-->|Real-time Streams| CF
  
  %% Client to Backend
  C -->|REST Requests| API
  D <-->|Socket.IO Connections| API
  
  %% Backend Logic
  order <-->|Webhooks / Create Order| RZP
  order -->|Commit Transactions| PG
  track <-->|Ephemeral GPS State| REDIS
  disp <-->|ST_Distance / ST_DWithin| POSTGIS
  
  %% Backend to Firebase
  REST -->|Dispatch Events| FCM
  FCM -->|Push Notifications| C & D
```

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

The application utilizes a sophisticated hybrid architectural approach. Firebase handles client-heavy, low-latency data streams (like product catalogs and profile syncs) directly to the Flutter app via websockets, avoiding the need to poll REST APIs for state changes. 

The custom NestJS backend handles secure transactions, complex geospatial calculations, and high-frequency WebSocket traffic that would otherwise overwhelm NoSQL document quotas. By combining these two paradigms, Beinn maintains enterprise-grade security and localized state-syncing simultaneously.

See [`ARCHITECTURE.md`](./ARCHITECTURE.md) and [`DATA_MODEL.md`](./DATA_MODEL.md).

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
- Real-time catalog updates synchronized directly from Cloud Firestore, reflecting stock count changes instantly.
- Seamless, native checkout flows utilizing Razorpay for secure payment capture without external redirects.
- Live order tracking interface displaying the delivery driver's real-time location on an interactive map.
- Rich animations utilizing Lottie and SVG rendering to enhance the premium feel of the storefront.
- Intelligent search and categorization tailored specifically for fashion apparel.

### Delivery Driver Interface

- Specialized driver dashboard for receiving dynamic dispatch assignments based on proximity.
- Battery-efficient background geolocation tracking utilizing `flutter_background_geolocation`, ensuring accurate location data even when the app is minimized or the screen is locked.
- Real-time navigation routing and geofencing validation to ensure deliveries are completed precisely at the customer's coordinates.
- Earnings and order history tracking natively integrated into the profile view.

### Backend Logistics & Dispatch

- High-frequency tracking engine using Socket.IO to manage driver location streams without exhausting expensive database document quotas.
- Geospatial engine utilizing PostGIS to calculate proximity, manage geofences, and optimize routes using ST_Distance and ST_DWithin functions.
- Webhook verification endpoints ensuring cryptographic security for all Razorpay transactions, completely preventing client-side spoofing.
- Automated push notifications dispatched via Firebase Cloud Messaging (FCM) based on order status changes.

### CI/CD Pipeline

- Fully automated GitHub Actions workflow triggered on every push and pull request to the main branch.
- Automatic Dart formatting with automatic PR generation for styling fixes, ensuring strict codebase consistency.
- Deep static analysis via `flutter analyze` ensuring strict type and linting compliance.
- Automated widget and unit testing (`flutter test`) verifying core business logic.
- Dummy `.env` placeholder generation to bypass strict asset validation during CI runs without exposing secrets.

---

## Project Structure

```text
.
├── android/                   # Native Android configuration (Gradle, Manifests)
├── ios/                       # Native iOS configuration (CocoaPods, Info.plist)
├── lib/                       # Flutter Application Source
│   ├── main.dart              # Application entry point and Root provider
│   ├── models/                # Dart data structures and serialization logic
│   ├── data/                  # Static mocks and configurations
│   ├── screens/               # UI Views (Storefront, Checkout, Driver Dash)
│   ├── widgets/               # Reusable UI components (Buttons, Cards, Inputs)
│   └── services/              # API clients, Repositories, and Firebase wrappers
├── assets/                    # Static media
│   └── images/                # Product imagery (hoodies, t-shirts, perfume)
├── backend/                   # NestJS Application Source
│   ├── src/
│   │   ├── app.module.ts      # Root backend module
│   │   ├── auth/              # JWT and security middleware logic
│   │   ├── orders/            # Razorpay integration and webhook handling
│   │   └── tracking/          # Socket.IO gateways and PostGIS queries
│   ├── package.json           # Backend dependencies and scripts
│   └── .env.example           # Example backend configuration
├── .github/
│   └── workflows/             # GitHub Actions CI/CD pipelines
├── pubspec.yaml               # Flutter dependencies and assets
└── README.md                  # This file
```

---

## Data Model

The application leverages a highly specialized hybrid data model split intelligently across Firestore (for client state) and PostgreSQL (for ACID transactions):

| Model | Database | Key Fields | Description |
|---|---|---|---|
| `User` | Firestore | `uid`, `displayName`, `email`, `role` | Maps authentication tokens to internal application roles (CUSTOMER/DRIVER). |
| `Product` | Firestore | `id`, `name`, `category`, `price`, `stockCount` | Represents the live catalog. Subscribed to by the client for instant stock updates. |
| `Order` | Postgres | `orderId`, `userId`, `amount`, `status`, `signature` | Handles financial truths. Validated cryptographically via backend webhooks. |
| `DriverLocation`| Redis/Postgres| `driverId`, `lat`, `lng`, `geog`, `timestamp` | Ephemeral state is held in Redis, while persistent delivery routes map to PostGIS Points. |

See [`DATA_MODEL.md`](./DATA_MODEL.md).

---

## Getting Started

### Prerequisites

- Flutter SDK (v3.44.4 or higher)
- Node.js (v18.x or higher)
- PostgreSQL (with PostGIS extension installed locally)
- Redis Server (Running on default port 6379)

### Installation

```bash
# Clone the repository
git clone https://github.com/TirrthM/beinn.git
cd beinn

# 1. Setup Backend
cd backend
npm install
# Configure your backend .env file here (see Configuration section)
npm run start:dev

# 2. Setup Frontend
cd ..
flutter pub get
# Configure your root .env file and Firebase service files here
flutter run
```

---

## Available Commands

| Command | Directory | Description |
|---|---|---|
| `npm run start:dev` | `/backend` | Starts the NestJS backend with hot-reload enabled. |
| `flutter run` | `/` | Compiles and launches the Flutter app on an emulator/device. |
| `flutter test` | `/` | Runs the automated widget and unit test suites. |
| `flutter analyze` | `/` | Performs static analysis based on `analysis_options.yaml`. |
| `dart format .` | `/` | Formats all Dart files according to idiomatic style guides. |
| `flutter build apk` | `/` | Compiles the Android release package. |

---

## Environment Configuration

To run both services locally, configure the following variables. Do not commit these files to version control.

The production application requires PostgreSQL before durable data workflows can be enabled.

### Frontend (`/.env`)
```env
RAZORPAY_KEY_ID=rzp_test_YourKeyHere
BACKEND_API_URL=http://localhost:3000
```
*(Ensure `google-services.json` and `GoogleService-Info.plist` are placed in their respective native directories `android/app/` and `ios/Runner/`).*

### Backend (`/backend/.env`)
```env
RAZORPAY_KEY_ID="rzp_test_your_key_id"
RAZORPAY_KEY_SECRET="your_razorpay_secret"
DATABASE_URL="postgres://user:password@localhost:5432/beinn"
REDIS_URL="redis://localhost:6379"
FIREBASE_ADMIN_CREDENTIALS="/absolute/path/to/serviceAccountKey.json"
```

---

## Testing and Completion

A successful build is not the definition of completion. The acceptance path is:

1. CI passes security, lint, test and build checks.
2. End-to-end automated tests pass across core user journeys.
3. Production deployment reaches a ready state.
4. Client applications and workspace routes render without console/runtime errors.
5. Configured API and database paths are exercised end-to-end.
6. Role entitlements match actual feature access appropriately.
7. No fabricated production metrics are present.
8. Documentation matches the implementation.
9. Post-completion production verification is repeated after the required observation window.

---

## Security

The project uses environment-based secrets, server-side data access, parameterized database queries and production security rules. Security claims are limited to controls that are actually implemented and verified.

See [`SECURITY.md`](./SECURITY.md).

---

## Data Sources and External APIs

Provider adapters (such as Razorpay, Firebase, PostGIS) can be added without coupling credentials to the application. Until a provider is configured, the product presents an explicit unconfigured state rather than inventing delivery or risk data.

---

## API & WebSocket Reference

### REST Endpoints (`/api/v1/*`)

| Endpoint | Method | Description |
|---|---|---|
| `/orders/create` | POST | Generates a secure Razorpay order ID and initiates the database transaction. |
| `/orders/verify` | POST | Validates the Razorpay webhook signature to confirm payment success. |
| `/dispatch/nearest`| GET | Queries PostGIS utilizing `ST_Distance` for the closest active driver. |

### WebSocket Events (`/tracking`)

| Event Name | Direction | Payload |
|---|---|---|
| `location_update` | Client -> Server | `{ driverId, lat, lng, timestamp }` |
| `order_assigned` | Server -> Client | `{ orderId, pickupLocation, deliveryLocation }` |
| `status_change` | Server -> Client | `{ orderId, status: "EN_ROUTE" | "DELIVERED" }` |

---

## Design Decisions

### Why Flutter?
Flutter was selected to ensure a visually identical, highly performant experience across both iOS and Android. The platform requires complex, fluid animations and intricate map rendering which Flutter handles natively via its Skia/Impeller graphics engine, completely eliminating the sluggish overhead of web-view based hybrid frameworks like React Native or Ionic. It allows us to share 99% of our UI codebase while delivering native 60fps performance.

### Why a Hybrid Firebase + NestJS Backend?
Firebase Cloud Firestore is unparalleled for synchronizing real-time catalog and profile data directly to the client with zero boilerplate. It allows the UI to react instantly to stock changes or profile updates. 

However, Firestore becomes prohibitively expensive and inefficient for high-frequency GPS tracking and complex geospatial proximity queries (due to document read/write costs). NestJS paired with PostgreSQL (PostGIS) and Redis elegantly solves the tracking and secure payment requirements. Redis handles ephemeral Socket.IO state, PostGIS handles complex boundary mapping, and NestJS securely signs transaction data. This results in a perfectly balanced architectural hybrid that maximizes speed while minimizing cloud provider costs.

---

## Documentation

- [`ARCHITECTURE.md`](./ARCHITECTURE.md) — system boundaries and deployment model
- [`DATA_MODEL.md`](./DATA_MODEL.md) — persistence model
- [`SECURITY.md`](./SECURITY.md) — security requirements
- [`CHANGELOG.md`](./CHANGELOG.md) — implementation history

---

## Disclaimer

This software is an engineering product for e-commerce and logistics workflows. It is not financial or legal advice and does not replace formal model validation, operational governance, regulatory review, or production controls.

---

## License

Copyright 2026 Beinn. All rights reserved.

MIT. See [`LICENSE`](./LICENSE).

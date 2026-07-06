# Beinn E-Commerce Application

This repository contains the complete source code for the Beinn clothing store application. The project is designed with a hybrid architecture that leverages Firebase for core e-commerce functionality and a specialized NestJS microservice for high-frequency, real-time driver tracking.

## Architecture Overview

The system is organized into three primary layers to ensure scalability and real-time performance without overwhelming the main database.

### 1. Flutter Mobile Application

The front-end is a cross-platform Flutter application that handles both the customer shopping experience and the driver delivery interface.

- **Background Tracking:** The driver side of the application uses background geolocation services to continuously monitor and transmit GPS coordinates, even when the device is locked.
- **Interactive Maps:** The customer side utilizes OpenStreetMap (via flutter_map) to render the live location of their delivery driver. We use smooth interpolation to prevent the marker from jumping abruptly between coordinate updates.
- **Product Catalog:** Product images and details are fetched via HTTP and cached locally on the device to ensure smooth scrolling and reduced network usage on subsequent visits.

### 2. Firebase Services

Firebase acts as the primary backend for standard e-commerce operations.

- **Authentication:** Manages secure sign-ups and logins for both customers and drivers.
- **Firestore Database:** Stores the product catalog, user profiles, order histories, and shopping carts. Security rules are strictly enforced to ensure users can only access their own data.
- **Content Delivery:** Product images and static assets are served through a CDN for global availability and speed.

### 3. NestJS Real-Time Gateway

To prevent Firebase from being flooded with high-frequency GPS coordinate writes, we implemented a decoupled Node.js backend using the NestJS framework.

- **WebSockets (Socket.IO):** Maintains a persistent, lightweight connection between the driver's phone and the server. This is significantly more battery-efficient than standard HTTP polling.
- **Redis In-Memory Data Store:** When the NestJS gateway receives a coordinate update, it writes it directly into Redis using geospatial indexes. This allows for incredibly fast writes and spatial queries.
- **PostgreSQL with PostGIS:** Periodically, the tracking data is synced from Redis to a persistent PostgreSQL database equipped with the PostGIS extension, allowing for long-term storage and complex geographic analysis.

## Step-by-Step Setup Guide

Follow these instructions to run the full stack locally on your development machine.

### Prerequisites

Before you begin, ensure you have the following installed:

- Flutter SDK (version 3.19 or higher)
- Node.js (version 18 or higher)
- A local instance of PostgreSQL with the PostGIS extension enabled
- A local instance of Redis

### Setting up the NestJS Backend

1. Open a terminal and navigate to the `backend` directory.
2. Install the necessary Node dependencies by running `npm install`.
3. Configure your environment variables. You will need to specify the connection strings for both your Redis server and your PostgreSQL database.
4. Start the development server by running `npm run start:dev`. The server will initialize and begin listening for incoming WebSocket connections.

### Setting up the Flutter Application

1. Ensure your Firebase project is properly configured and the `google-services.json` (for Android) and `GoogleService-Info.plist` (for iOS) files are placed in their respective directories.
2. Navigate to the root directory of the repository in your terminal.
3. Download the necessary Dart packages by running `flutter pub get`.
4. Launch your preferred emulator or connect a physical device.
5. Compile and run the application using `flutter run`.

## Continuous Integration

This project utilizes GitHub Actions to automate the testing and build pipeline. Whenever code is pushed to the main branch, the workflow automatically runs the Dart analyzer to check for syntax issues, executes the test suite, and builds a release-ready APK.

# Beinn Project Documentation

This repository contains the source code for the Beinn e-commerce and delivery application. The project is split into a Flutter mobile frontend and a NestJS backend. This document provides a straightforward guide on how to set up the project locally.

## Project Structure

The codebase is organized into two main parts. The root directory contains the Flutter application, which handles the customer storefront and the driver delivery interface. The backend directory contains the NestJS service, which manages secure operations like server-side payment generation and high-frequency location tracking. Firebase is used as the primary database for user profiles, product catalogs, and order history.

## Development Requirements

To run this project, you need to install the following software on your machine:
- Flutter SDK (version 3.3.0 or higher)
- Node.js (version 18 or higher)
- A local PostgreSQL instance with the PostGIS extension
- A local Redis server

## Backend Setup

1. Open your terminal and change into the backend directory.
2. Install the necessary Node packages by running npm install.
3. You need to configure your environment variables. Create a file named .env inside the backend directory. You will need to provide your Razorpay secret key, your Firebase Admin SDK credentials, and your database connection strings. Please refer to the security document for detailed instructions on handling these credentials.
4. Once your environment variables are set, start the development server by running npm run start:dev. The server will start on port 3000.

## Frontend Setup

1. Make sure your Firebase project is configured for your mobile application. You must place the google-services.json file in the android/app directory and the GoogleService-Info.plist file in the ios/Runner directory.
2. Navigate to the root directory of the project in your terminal.
3. Create a file named .env in the root directory. Add your public Razorpay Key ID and the URL of your local backend server (for example, http://localhost:3000).
4. Download the required Dart dependencies by running flutter pub get.
5. Connect your physical device or start an emulator.
6. Build and run the application by running flutter run.

## CI/CD Pipeline

The project uses GitHub Actions to automate testing and builds. Every push to the main branch triggers a workflow that runs the Dart analyzer, executes the test suite, and builds a release APK. This ensures that the codebase remains stable and ready for deployment.

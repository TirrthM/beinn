# Beinn E-Commerce Application

This repository contains the source code for the Beinn clothing store app. It's built with a Flutter frontend and integrates with Firebase for authentication and database management, along with a custom Node.js backend for realtime delivery tracking.

## Architecture Overview

The system is split into a few key parts:

- Flutter App: Serves as both the customer-facing store and the driver delivery interface. It uses background geolocation and WebSockets to transmit live updates.
- Firebase: Handles user authentication, core user profiles, and product catalog rules.
- NestJS Backend: A decoupled service built with Node.js that runs alongside Firebase. It processes real-time GPS coordinates using WebSockets, caches them in Redis with geospatial indexes, and saves them to a PostgreSQL database utilizing PostGIS.

## Development Setup

To get started with development, you'll need Flutter, Node.js, and Docker (or local instances of Redis and PostgreSQL) installed.

### Running the Backend

Navigate to the backend directory, install the required packages using npm, and start the development server. Make sure to provide the necessary environment variables for database connections.

### Running the App

From the root directory, fetch the Flutter dependencies and start the app on your preferred emulator or physical device.

For testing, this project includes a GitHub Actions workflow that automatically lints and builds the application on every push to the main branch.

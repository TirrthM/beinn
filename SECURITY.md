# Security Guidelines

This document outlines the security architecture and best practices implemented in the Beinn application. Because the application processes payments and handles personal data, strict security measures are enforced at both the client and server levels.

## Payment Processing Architecture

The application uses Razorpay for payment processing. To prevent malicious users from modifying order amounts on their devices, we use a server-side order generation flow.

1. The client application never calculates the final payment amount. When a user proceeds to checkout, the mobile app sends a request containing their user ID to the backend server.
2. The backend server uses the Firebase Admin SDK to securely fetch the user's current cart directly from the database. It computes the total price on the server, ensuring the amount cannot be tampered with.
3. The server then contacts the Razorpay API to generate a unique order ID for that specific amount.
4. The server returns this order ID to the mobile app, which then uses it to initialize the Razorpay checkout overlay.

## Environment Variables and Secrets Management

Sensitive keys must never be hardcoded into the source code or pushed to version control. We use environment files to manage these secrets.

### Backend Configuration

The backend requires high-privilege access keys. You must create a file named .env inside the backend directory. This file must contain:
- Your Razorpay Secret Key, which allows the server to create financial orders.
- Your Firebase Admin SDK credentials. You can generate these by navigating to your Firebase Console, opening Project Settings, selecting the Service Accounts tab, and clicking Generate New Private Key. You need to extract the project ID, client email, and the raw private key string from the downloaded JSON file and place them in the backend environment file.

### Frontend Configuration

The frontend requires non-sensitive configuration values. You must create a file named .env in the root directory of the project. This file must contain:
- Your Razorpay Key ID. This is a public key used to identify your merchant account to the Razorpay checkout interface.
- The base URL for your backend server.

Both of these environment files are explicitly listed in the .gitignore file to ensure they are never uploaded to GitHub.

## Database Security Rules

All interactions with the Firebase database directly from the mobile app are restricted by Firebase Security Rules. Users are only granted permission to read and write data that corresponds to their own authenticated user ID. Any attempt to query or modify data belonging to another user will be rejected by the database.

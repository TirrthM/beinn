# Beinn Security Architecture

**A comprehensive overview of the security protocols, payment safeguarding measures, and data protection strategies implemented across the Beinn e-commerce and delivery platform.**

This document outlines the security architecture and best practices implemented in the Beinn application. Because the platform processes financial transactions, coordinates real-time physical logistics, and handles personal data, strict security measures are enforced at both the client and server levels to ensure absolute data integrity and compliance.

---

## Table of Contents

- [Payment Processing Architecture](#payment-processing-architecture)
- [Authentication & Authorization](#authentication--authorization)
- [Database Security Rules](#database-security-rules)
- [Environment Variables & Secrets Management](#environment-variables--secrets-management)
- [Network & Communication Security](#network--communication-security)
- [Vulnerability Reporting](#vulnerability-reporting)

---

## Payment Processing Architecture

The application uses Razorpay for enterprise-grade payment processing. To completely eliminate the risk of malicious users modifying order amounts or spoofing transactions on their devices, we employ a strict **server-side order generation flow**:

1. **Client Isolation**: The client application (Flutter) never calculates the final payment amount. When a user proceeds to checkout, the mobile app sends a request containing their user ID to the backend server.
2. **Server-Side Validation**: The NestJS backend server uses the highly-privileged Firebase Admin SDK to securely fetch the user's current cart directly from the database. It computes the total price, applies taxes, and determines shipping costs on the server, ensuring the final amount cannot be tampered with by a modified client payload.
3. **Order Generation**: The server then contacts the Razorpay API securely using its private credentials to generate a unique, cryptographically signed order ID for that specific, validated amount.
4. **Client Hand-off**: The server returns this generated order ID to the mobile app, which then uses it to initialize the Razorpay checkout overlay.
5. **Webhook Verification**: Once the user completes the payment, Razorpay sends a webhook directly to our NestJS server. The server verifies the `x-razorpay-signature` header using HMAC SHA256 to guarantee the payload originated from Razorpay before fulfilling the order.

---

## Authentication & Authorization

Identity management across the platform utilizes Firebase Authentication as the primary identity provider, integrated with custom NestJS middleware for backend authorization.

### Client Authentication
- Users authenticate via Email/Password or OAuth (Google Sign-In) on the mobile application.
- Firebase handles secure password hashing, brute-force protection, and token rotation natively.

### Backend Authorization
- When the Flutter app communicates with the NestJS backend (for dispatch, payments, or websockets), it attaches a short-lived Firebase ID Token (JWT) in the `Authorization: Bearer <token>` header.
- The NestJS server utilizes custom Guards to cryptographically verify this JWT against Google's public key infrastructure before processing any request.
- Role-based Access Control (RBAC) is enforced by verifying custom claims (e.g., `role: "DRIVER"` vs `role: "CUSTOMER"`) to ensure drivers cannot access administrative endpoints.

---

## Database Security Rules

All direct interactions between the mobile application and the Cloud Firestore database are restricted by strict declarative Firebase Security Rules.

- **Granular Access Control**: Users are only granted permission to read and write data that directly corresponds to their own authenticated user ID (`request.auth.uid == resource.data.userId`).
- **Data Isolation**: Any attempt to query, modify, or delete data belonging to another user will be instantly rejected by the database at the infrastructure level.
- **Schema Validation**: Security rules are also utilized to enforce schema validation (e.g., ensuring a product rating is between 1 and 5) before writes are committed to disk.

---

## Environment Variables & Secrets Management

Sensitive keys, cryptographic secrets, and infrastructure routing URLs must never be hardcoded into the source code or pushed to version control. We utilize localized environment files (`.env`) to securely inject these configurations at runtime.

### Backend Configuration (High-Privilege)
The backend requires high-privilege access keys. You must create a file named `.env` inside the `backend/` directory containing:
- **Razorpay Secret Key**: Allows the server to create financial orders and verify webhooks.
- **Database URIs**: Connection strings for PostgreSQL and Redis.
- **Firebase Admin Credentials**: You must generate these by navigating to your Firebase Console -> Project Settings -> Service Accounts, and clicking "Generate New Private Key". You must extract the project ID, client email, and the raw private key string from the downloaded JSON file and place them in the backend environment file.

### Frontend Configuration (Low-Privilege)
The frontend requires non-sensitive, public configuration values. You must create a file named `.env` in the root directory of the project containing:
- **Razorpay Key ID**: This is a public key used solely to identify your merchant account to the Razorpay checkout UI. It cannot be used to execute financial operations.
- **Backend API URL**: The base URL for your NestJS server instance.

**Important**: Both the root and backend `.env` files, as well as native service files (`google-services.json`, `GoogleService-Info.plist`), are explicitly listed in the `.gitignore` file to ensure they are never uploaded to GitHub or exposed in CI/CD logs.

---

## Network & Communication Security

- **Encryption in Transit**: All communication between the Flutter client, the NestJS backend, and third-party APIs (Razorpay, Firebase) is strictly enforced over TLS 1.2+ (HTTPS/WSS).
- **WebSocket Security**: The Socket.IO tracking connections require immediate JWT authentication upon connection. Unauthenticated sockets are forcefully disconnected to prevent denial-of-service (DoS) attacks on the real-time engine.

---

## Vulnerability Reporting

If you discover a security vulnerability within the Beinn platform, please do not disclose it publicly or open a GitHub issue. Instead, please contact the repository maintainers directly to coordinate a responsible disclosure and patch rollout.

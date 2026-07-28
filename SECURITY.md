# Beinn Security Architecture

**A comprehensive, highly detailed overview of the security protocols, payment safeguarding measures, cryptographic signatures, and data protection strategies implemented across the Beinn e-commerce and delivery platform.**

This document outlines the zero-trust security architecture and best practices implemented in the Beinn application. Because the platform processes high-value financial transactions, coordinates real-time physical logistics involving driver locations, and handles Personally Identifiable Information (PII), strict security measures are enforced at every layer of the OSI model, across both the client applications and the backend microservices, to ensure absolute data integrity and regulatory compliance.

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

The application uses Razorpay for enterprise-grade payment processing. To completely eliminate the risk of malicious users utilizing Man-in-the-Middle (MITM) attacks or memory hooking to modify order amounts on their devices, we employ a strict **server-side order generation flow**:

1. **Client Isolation**: The client application (Flutter) acts merely as a presentation layer and never calculates the final payment amount. When a user proceeds to checkout, the mobile app sends a zero-trust request containing only their user ID to the backend server.
2. **Server-Side Validation**: The NestJS backend server uses the highly-privileged Firebase Admin SDK to securely fetch the user's current cart directly from the database, bypassing the client completely. It computes the total price, applies regional taxes, validates active discount codes against a secure ledger, and determines shipping costs based on PostGIS geospatial routing on the server. This ensures the final amount is mathematically sound and cannot be tampered with.
3. **Cryptographic Order Generation**: The server then contacts the Razorpay API securely via a TLS 1.3 tunnel using its private Basic Auth credentials to generate a unique, cryptographically signed `order_id` for that specific, validated amount.
4. **Client Hand-off**: The server returns this generated `order_id` to the mobile app. The Flutter app uses this ID to initialize the Razorpay checkout overlay. The Razorpay SDK independently verifies this ID with Razorpay's servers before accepting payment.
5. **Webhook Verification**: Once the user completes the payment, Razorpay sends a webhook payload directly to our NestJS server. The server intercepts this request and verifies the `x-razorpay-signature` header by generating an HMAC SHA256 signature using the raw request body and the Razorpay Secret Key. Only if the generated signature precisely matches the received signature is the order marked as `PAID` and fulfillment triggered.

---

## Authentication & Authorization

Identity management across the platform utilizes Firebase Authentication as the primary Identity Provider (IdP), integrated with custom NestJS middleware and Guards for robust backend authorization.

### Client Authentication (Firebase Auth)
- Users authenticate via Email/Password or OAuth 2.0 (Google Sign-In) directly on the mobile application.
- Firebase handles secure bcrypt password hashing, automatic brute-force protection (rate limiting), and token rotation natively.
- Short-lived JSON Web Tokens (JWTs) are issued to the client upon successful authentication, minimizing the risk window if a device is compromised.

### Backend Authorization (NestJS Guards)
- When the Flutter app communicates with the custom NestJS backend (for dispatching, payments, or WebSocket connections), it attaches the short-lived Firebase ID Token in the `Authorization: Bearer <token>` HTTP header.
- The NestJS server utilizes custom Authentication Guards to cryptographically verify the signature of this JWT against Google's rotating public key infrastructure (PKI) before processing *any* request. It verifies the token's audience (`aud`), issuer (`iss`), and expiration (`exp`).
- **Role-Based Access Control (RBAC)**: Authorization is enforced by validating custom claims embedded within the JWT (e.g., `role: "DRIVER"` vs `role: "CUSTOMER"`). This ensures, for example, that standard customers cannot access driver-specific dispatch APIs or view other users' location data.

---

## Database Security Rules

All direct interactions between the mobile application and the Cloud Firestore database bypass the traditional backend and are instead restricted by strict, declarative Firebase Security Rules evaluated at the edge.

- **Granular Access Control**: Users are only granted permission to read and write data that directly corresponds to their own authenticated user ID (`request.auth.uid == resource.data.userId`).
- **Data Isolation**: Any attempt to query, modify, or delete data belonging to another user will be instantly rejected by the database at the infrastructure level, preventing Insecure Direct Object Reference (IDOR) vulnerabilities.
- **Schema Validation**: Security rules are aggressively utilized to enforce strict schema validation before writes are committed to disk. For instance, rules verify that a product rating is strictly an integer between 1 and 5, and that string fields do not exceed maximum character limits to prevent database bloating attacks.
- **Role Enforcement**: Firestore rules check the user's custom claims to grant broad read/write access to administrative users while strictly siloing standard users.

---

## Environment Variables & Secrets Management

Sensitive keys, cryptographic secrets, database credentials, and infrastructure routing URLs must never be hardcoded into the source code or pushed to version control. We utilize localized environment files (`.env`) to securely inject these configurations into the application memory space at runtime.

### Backend Configuration (High-Privilege)
The backend requires high-privilege access keys. You must create a file named `.env` inside the `backend/` directory containing:
- **Razorpay Secret Key**: Allows the server to execute financial operations, issue refunds, and verify incoming webhooks.
- **Database URIs**: Connection strings for PostgreSQL and Redis, incorporating strong authentication credentials.
- **Firebase Admin Credentials**: Used by the NestJS server to bypass standard Firestore rules. You must generate these by navigating to your Firebase Console -> Project Settings -> Service Accounts, and clicking "Generate New Private Key". You must extract the project ID, client email, and the raw private key string from the downloaded JSON file and place them in the backend environment file.

### Frontend Configuration (Low-Privilege)
The frontend requires non-sensitive, public configuration values. You must create a file named `.env` in the root directory of the project containing:
- **Razorpay Key ID**: This is a public key used solely to identify your merchant account to the Razorpay checkout UI. It *cannot* be used to execute backend financial operations.
- **Backend API URL**: The base URL for your NestJS server instance.

**Important**: Both the root and backend `.env` files, as well as native service configuration files (`google-services.json`, `GoogleService-Info.plist`), are explicitly listed in the `.gitignore` file to ensure they are never uploaded to GitHub or exposed in CI/CD pipeline logs. Secret scanning tools are enabled on the repository to detect accidental key commits.

---

## Network & Communication Security

- **Encryption in Transit**: All communication between the Flutter client, the NestJS backend, and third-party APIs (Razorpay, Firebase) is strictly enforced over TLS 1.2 or TLS 1.3. Plain HTTP traffic is automatically dropped or upgraded to HTTPS/WSS.
- **WebSocket Security**: The Socket.IO real-time tracking connections require immediate JWT authentication during the initial handshake. Unauthenticated sockets are forcefully disconnected within milliseconds to prevent Denial-of-Service (DoS) attacks on the real-time geographic engine.
- **CORS & Rate Limiting**: The backend implements strict Cross-Origin Resource Sharing (CORS) policies and IP-based rate limiting (using Redis) to mitigate brute-force attempts and automated scraping.

---

## Vulnerability Reporting

Security is an ongoing process. If you discover a security vulnerability within the Beinn platform, please do not disclose it publicly or open a GitHub issue, as this could put current users at risk. 

Instead, please contact the repository maintainers directly via secure email to coordinate a responsible disclosure and immediate patch rollout. We take all reports seriously and will prioritize vulnerability mitigation above all other development tasks.

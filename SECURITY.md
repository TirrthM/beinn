# Beinn Security Architecture

**A comprehensive, highly detailed overview of the security protocols, payment safeguarding measures, cryptographic signatures, and data protection strategies implemented across the Beinn e-commerce and delivery platform.**

This document outlines the zero-trust security architecture and best practices implemented in the Beinn application. Because the platform processes high-value financial transactions, coordinates real-time physical logistics, and handles Personally Identifiable Information (PII), strict security measures are enforced at every layer.

Below is a detailed breakdown of **what** security implementations exist, **why** they are necessary, and the **justification** for our approach.

---

## Table of Contents

- [1. Server-Side Order Generation (Razorpay)](#1-server-side-order-generation-razorpay)
- [2. Cryptographic Webhook Verification (HMAC SHA256)](#2-cryptographic-webhook-verification-hmac-sha256)
- [3. Backend JWT Authorization (NestJS Guards)](#3-backend-jwt-authorization-nestjs-guards)
- [4. Firebase Security Rules & Role-Based Access (RBAC)](#4-firebase-security-rules--role-based-access-rbac)
- [5. Strict Environment Variable Separation (.env)](#5-strict-environment-variable-separation-env)
- [6. WebSocket Security (Socket.IO over TLS)](#6-websocket-security-socketio-over-tls)
- [Vulnerability Reporting](#vulnerability-reporting)

---

## 1. Server-Side Order Generation (Razorpay)

*   **What is done:** When a user checks out, the Flutter app does *not* tell Razorpay how much to charge. Instead, it sends a zero-trust request to the NestJS backend to calculate the cart total, apply taxes, and request an `order_id` from Razorpay using private credentials.
*   **Why it is necessary:** Mobile applications execute on client devices and can be easily manipulated. An attacker can use a proxy (like Charles Proxy) or memory hooking to intercept the checkout request and change a ₹2000 hoodie to ₹1.
*   **Justification:** By forcing the calculation onto the NestJS backend, the server becomes the "absolute source of truth." Even if a hacker completely reverse-engineers the Flutter app, they cannot alter the price of the items because the backend fetches the real prices directly from the database and passes them to Razorpay directly.

## 2. Cryptographic Webhook Verification (HMAC SHA256)

*   **What is done:** After a user successfully pays, Razorpay sends a webhook payload to the backend server to confirm the payment. The server intercepts this request and verifies the `x-razorpay-signature` header by generating an HMAC SHA256 signature using the raw request body and the Razorpay Secret Key.
*   **Why it is necessary:** Without verification, a hacker could simply send a fake HTTP POST request to the server saying, *"Hey, I just paid for Order #1234, please ship it,"* and the server would blindly trust it and fulfill an unpaid order.
*   **Justification:** The HMAC SHA256 signature guarantees mathematically that the incoming request actually originated from Razorpay's servers. Because only the backend and Razorpay know the Secret Key, it is impossible for an attacker to forge this signature, completely eliminating webhook spoofing.

## 3. Backend JWT Authorization (NestJS Guards)

*   **What is done:** Every time the Flutter app communicates with the custom NestJS backend (for dispatching, payments, or websockets), it attaches a short-lived Firebase ID Token (JWT). The server utilizes custom Guards to cryptographically verify this token against Google's public keys before processing any request.
*   **Why it is necessary:** Without authentication, anonymous internet users could scrape APIs, trigger fake delivery dispatches, or access private infrastructure.
*   **Justification:** Relying on JSON Web Tokens (JWTs) means the NestJS server does not have to execute a slow database lookup to figure out who the user is. It can instantly verify the user's identity mathematically. This ensures the backend remains highly scalable, stateless, and incredibly secure.

## 4. Firebase Security Rules & Role-Based Access (RBAC)

*   **What is done:** Strict declarative rules in Firestore ensure a user can only read/write data where `userId == request.auth.uid`. We also enforce Roles (e.g., separating "Customers" from "Drivers") by validating custom JWT claims.
*   **Why it is necessary:** Because the Flutter application connects *directly* to Firestore (bypassing NestJS for catalog/profile data), a malicious user could write a simple script to download the entire database of users or modify other people's orders (an Insecure Direct Object Reference or IDOR attack).
*   **Justification:** Firebase Security Rules act as an impenetrable firewall evaluated at Google's edge servers. The Role-Based Access Control (RBAC) ensures a standard customer can never access driver-specific dispatch APIs or assign themselves as a driver to steal packages.

## 5. Strict Environment Variable Separation (.env)

*   **What is done:** Public keys (e.g., Razorpay Key ID) are strictly isolated in the Flutter frontend, while highly sensitive keys (Razorpay Secret, Firebase Admin SDK JSON) are kept exclusively on the backend server. These files are blocked from version control via `.gitignore`.
*   **Why it is necessary:** Mobile apps are not secure vaults; they can be decompiled in minutes. If a Secret Key is placed inside Flutter code, attackers will extract it and gain full administrative access to steal funds or delete the database.
*   **Justification:** By keeping secrets strictly on the backend, they never touch the user's physical device. This is the industry-standard baseline for zero-trust security and ensures that a compromised mobile client does not result in a compromised backend infrastructure.

## 6. WebSocket Security (Socket.IO over TLS)

*   **What is done:** Driver location tracking requires persistent Socket.IO connections. These connections are strictly enforced over TLS 1.3 (WSS) and must authenticate immediately with a JWT upon the initial handshake. Unauthenticated sockets are forcefully dropped.
*   **Why it is necessary:** Open WebSockets are highly vulnerable to Denial of Service (DoS) attacks. An attacker could open 100,000 blank connections to the server to exhaust memory and crash the geographic tracking engine.
*   **Justification:** By instantly killing unauthenticated sockets, the server preserves its RAM and CPU for actual, authenticated delivery drivers. This ensures the dispatch routing system never goes offline during a busy product drop or high-traffic event.

---

## Vulnerability Reporting

Security is an ongoing process. If you discover a security vulnerability within the Beinn platform, please do not disclose it publicly or open a GitHub issue, as this could put current users at risk. 

Instead, please contact the repository maintainers directly via secure email to coordinate a responsible disclosure and immediate patch rollout. We take all reports seriously and will prioritize vulnerability mitigation above all other development tasks.

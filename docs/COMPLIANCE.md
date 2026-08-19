# Compliance and Data Security

Beinn is designed to handle sensitive user data and financial transactions. This document outlines our compliance stance and security measures.

## Payment Card Industry Data Security Standard (PCI DSS)
Beinn **does not** process, store, or transmit raw credit card data. All payment processing is offloaded entirely to **Razorpay**. 
- The Flutter client utilizes Razorpay's native SDK.
- The NestJS backend only handles cryptographic webhook verification using the Razorpay API Key Secret to validate transaction authenticity.
- We are out of scope for strict PCI DSS compliance, relying on Razorpay's Level 1 PCI certification.

## General Data Protection Regulation (GDPR) & Privacy
While initially targeting local markets, the architecture supports GDPR principles:
- **Data Minimization:** We only collect required data (Email, Delivery Address, Location).
- **Right to Erasure:** User deletion requests automatically trigger cloud functions that wipe the user's data from Firebase Auth, Firestore, and scrub PII from PostgreSQL order records (leaving anonymized financial data for accounting).
- **Location Privacy:** Driver location data is only stored ephemerally in Redis during active deliveries. Long-term routing data in PostGIS is anonymized and stripped of driver identities after 30 days for analytics purposes.

## Authentication
All API endpoints are secured via JWTs issued by Firebase Authentication. The NestJS backend verifies these tokens using the Firebase Admin SDK, ensuring that spoofed requests are rejected at the gateway layer.

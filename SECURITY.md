# Security Policy

At Beinn, we take the security of our customers' data and our infrastructure extremely seriously. We have established this policy to ensure that any security issues are handled swiftly, responsibly, and transparently.

## Supported Versions

To ensure you are protected against known vulnerabilities, please verify that you are running a supported version of our application.

Currently, we support the following version branches:

- **Version 5.1.x and newer:** Fully supported. These versions receive regular feature updates and all necessary security patches.
- **Version 4.0.x:** Maintenance mode. This version no longer receives new features but will continue to receive critical security patches until it reaches its end of life.
- **Versions 5.0.x and anything older than 4.0:** End of life. These versions are no longer supported and do not receive security updates. If you are using one of these versions, please upgrade your environment as soon as possible.

## Infrastructure Security Measures

We employ several layers of security across our hybrid architecture to protect user data:

- **Authentication:** All user authentication and session management is handled by Firebase Authentication, which adheres to industry-standard security protocols.
- **Database Rules:** Access to Firestore is strictly governed by custom security rules. Users can only read and write data that belongs to their specific authenticated profile, such as their own shopping carts and order histories. Product data is globally readable but strictly write-protected.
- **Real-Time Data Transmission:** The NestJS tracking gateway encrypts all WebSocket communications using TLS. We avoid exposing direct database connections to the client.

## Reporting a Vulnerability

If you are a security researcher or a user who has discovered a potential security vulnerability in this project, we kindly ask for your cooperation in disclosing it to us responsibly.

Please follow these steps to report an issue:

1. **Do not open a public issue:** To protect our users, please do not disclose the vulnerability in a public GitHub issue, forum, or social media platform before we have had a chance to patch it.
2. **Email the security team:** Send a detailed report to our dedicated security team at <security@beinn.example.com>. Please include clear steps to reproduce the issue, the potential impact, and any proof-of-concept code if available.
3. **Wait for acknowledgment:** We will acknowledge receipt of your vulnerability report within 48 hours.
4. **Resolution timeline:** After verifying the issue, we will provide you with an estimated timeline for deploying a fix. We will keep you updated on our progress throughout the investigation and patching process.

We genuinely appreciate the efforts of the security community in helping us maintain a safe platform for everyone.

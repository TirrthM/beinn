# Product Roadmap

This roadmap outlines the planned features and technical improvements for Beinn over the next 12-18 months.

## Q3 2026: The Logistics Update
- **Clustered WebSockets:** Migrate from a single Socket.IO instance to a Redis-backed cluster to handle 10k+ concurrent driver connections.
- **Driver Tipping:** Allow customers to add tips natively via Razorpay post-delivery.
- **Enhanced Geofencing:** Implement strict pickup/drop-off polygon validation to prevent accidental early deliveries.

## Q4 2026: AI & Personalization
- **Smart Recommendations:** Introduce a recommendation engine in the NestJS backend analyzing purchase history to suggest apparel pairings.
- **Dynamic Pricing:** Implement surge pricing algorithms based on local driver availability and order density.
- **Automated Support:** Integrate a conversational AI bot for basic customer queries (e.g., "Where is my order?").

## Q1 2027: Platform Expansion
- **Web Storefront:** Port the Flutter mobile app to Flutter Web for a seamless desktop browsing experience.
- **Multi-tenant Support:** Architect the database to support multiple independent brands utilizing the Beinn logistics network.
- **Advanced Telemetry:** Implement Datadog/New Relic for deep backend tracing and Flutter crashlytics.

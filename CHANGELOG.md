# Changelog

All notable changes to the Beinn project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Geofencing strict validation in NestJS using `ST_Contains`.
- Driver earnings history UI in Flutter.
- Webhook signature validation fallback mechanism.

### Changed
- Migrated primary map rendering from Google Maps to `flutter_map` (OSM tiles) to reduce API costs.
- Updated Flutter SDK requirements to v3.44+.
- Optimized Redis caching layer for WebSocket connections, reducing latency by 15%.

### Fixed
- Memory leak in Socket.IO client on the Flutter side when reconnecting after a network drop.
- Razorpay currency formatting bug causing INR truncation.
- PostgreSQL connection pooling exhaustion during high dispatch loads.

## [1.0.0] - 2026-05-12

### Added
- Initial stable release of the Beinn platform.
- Full e-commerce storefront for browsing fashion apparel.
- Real-time cart and checkout integration via Razorpay.
- Dedicated driver app interface with background geolocation tracking.
- NestJS logistics engine with PostGIS matching.
- Firebase integration for authentication and product catalog syncing.

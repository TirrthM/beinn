# API & WebSocket Reference

This document outlines the REST endpoints and WebSocket events provided by the Beinn NestJS Backend.

## REST API (Base URL: `/api/v1`)

All authenticated REST endpoints require a Bearer token issued by Firebase Auth.

### Orders

#### `POST /orders/create`
Initializes a new order and generates a Razorpay Order ID.
- **Headers:** `Authorization: Bearer <token>`
- **Body:**
  ```json
  {
    "items": [{ "productId": "string", "quantity": 1 }],
    "deliveryAddress": { "lat": 19.076, "lng": 72.877, "address": "string" }
  }
  ```
- **Response:** `200 OK` with Razorpay `order_id`, `amount`, and `currency`.

#### `POST /orders/verify`
Webhook endpoint for Razorpay to confirm payment success.
- **Headers:** `x-razorpay-signature: <signature>`
- **Body:** Razorpay event payload.
- **Response:** `200 OK`

### Dispatch

#### `GET /dispatch/nearest`
Finds the nearest active driver to a given coordinate.
- **Query Params:** `lat` (float), `lng` (float), `radius` (integer in meters)
- **Response:** Returns driver metadata and estimated ETA.

---

## WebSockets (Namespace: `/tracking`)

The WebSocket server runs on Socket.IO. Authentication is handled during the initial handshake connection by passing the Firebase JWT in the `auth` object.

### Client (Driver) -> Server Events

#### `location_update`
Emitted by the driver app every 5 seconds.
- **Payload:**
  ```json
  {
    "driverId": "uid_123",
    "lat": 19.076,
    "lng": 72.877,
    "heading": 145.2,
    "speed": 12.5,
    "timestamp": 1698765432
  }
  ```

### Server -> Client (Customer/Driver) Events

#### `order_assigned`
Emitted to a specific driver when an order is routed to them.
- **Payload:** Order details and routing points.

#### `status_change`
Emitted to the customer app when the order state changes.
- **Payload:**
  ```json
  {
    "orderId": "ord_123",
    "status": "EN_ROUTE",
    "etaMinutes": 12
  }
  ```

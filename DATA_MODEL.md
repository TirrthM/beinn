# Data Model

Beinn leverages a highly specialized hybrid data model split intelligently across Firestore (for client state synchronization) and PostgreSQL (for ACID transactions and geospatial queries).

## Entity Relationship Architecture

```mermaid
erDiagram
    %% Firestore Collections (NoSQL)
    USER {
        string uid PK "Firebase Authentication UID"
        string displayName
        string email
        string role "CUSTOMER or DRIVER"
    }
    
    PRODUCT {
        string id PK "Firestore Document ID"
        string name
        string category
        float price "Amount in INR"
        int stockCount
    }

    %% PostgreSQL Tables (Relational)
    ORDER {
        uuid id PK "Internal UUID"
        string userId FK "Matches User.uid"
        float amount
        string status "PENDING, PAID, DELIVERED"
        string razorpayOrderId "External Reference"
        string signature "HMAC SHA256 Webhook Signature"
        timestamp createdAt
    }

    DRIVER_LOCATION {
        uuid id PK
        string driverId FK "Matches User.uid (Role: DRIVER)"
        geometry geog "PostGIS Point(lng, lat)"
        float lat
        float lng
        timestamp lastUpdated
    }

    %% System Boundaries & Relationships
    USER ||--o{ ORDER : "places (PostgreSQL)"
    ORDER ||--o{ PRODUCT : "contains (Line Items)"
    USER ||--o| DRIVER_LOCATION : "broadcasts (PostGIS / Redis)"
```

## Persistence Strategy

1. **Cloud Firestore (NoSQL)**: High read-throughput for catalog browsing and real-time stock updates. Clients subscribe to documents and collections directly.
2. **PostgreSQL (Relational)**: Ensures strong consistency and ACID guarantees for financial transactions via Razorpay webhooks.
3. **PostGIS**: Dedicated spatial engine for `ST_Distance` and `ST_DWithin` queries, determining optimal driver assignments.
4. **Redis**: Ephemeral tracking state before batched commits to PostGIS, preventing database IO exhaustion from high-frequency driver pings.

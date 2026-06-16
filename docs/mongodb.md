# MongoDB Local Development Setup

This document describes the local MongoDB setup used by the MicroservicesJava demo environment.

MongoDB is used by the Spring Boot microservices to persist service-specific data. In the local development environment, MongoDB runs as a Docker container together with Kafka and Kafka UI.

---

## Local MongoDB Architecture

The local environment uses one MongoDB Docker container.

```text
Docker container:
  mongodb

MongoDB instance:
  orderdb
  paymentdb
  customerdb   # planned for future customer-service
```

Each microservice owns its own logical MongoDB database.

| Microservice     | Database     | Collection  | Purpose                                                |
| ---------------- | ------------ | ----------- | ------------------------------------------------------ |
| order-service    | `orderdb`    | `orders`    | Stores orders created through the order API            |
| payment-service  | `paymentdb`  | `payments`  | Stores payment records created from Kafka order events |
| customer-service | `customerdb` | `customers` | Planned future customer data store                     |

This setup is acceptable for local development because each microservice still uses its own database. The services should not directly read or write each other’s databases.

---

## MongoDB Container

MongoDB runs in Docker.

Container name:

```text
mongodb
```

Default local connection:

```text
localhost:27017
```

Local development credentials:

```text
username: admin
password: admin123
authenticationDatabase: admin
```

Example connection URI:

```text
mongodb://admin:admin123@localhost:27017/orderdb?authSource=admin
```

For `payment-service`:

```text
mongodb://admin:admin123@localhost:27017/paymentdb?authSource=admin
```

---

## Starting MongoDB

MongoDB is started together with Kafka and Kafka UI by the infrastructure script.

From the infrastructure repository root:

```powershell
.\scripts\windows\start-infra.ps1
```

Or through the full local startup script:

```powershell
.\scripts\windows\start-all.ps1
```

Compatibility wrapper:

```powershell
.\scripts\start-all.ps1
```

---

## Stopping MongoDB

To stop the local infrastructure containers:

```powershell
.\scripts\windows\stop-all.ps1
```

This stops Kafka, Kafka UI, MongoDB, and local Spring Boot services.

Stopping a container does not necessarily delete MongoDB data because Docker volumes can preserve data.

---

## Connecting to MongoDB Shell

To connect to the MongoDB container:

```powershell
docker exec -it mongodb mongosh -u admin -p admin123 --authenticationDatabase admin
```

After connecting, list databases:

```javascript
show dbs
```

Example expected databases after the services have created data:

```text
admin
config
local
orderdb
paymentdb
```

---

## MongoDB Terminology

MongoDB does not use tables.

Use this terminology:

```text
MongoDB container
  contains MongoDB server

MongoDB server
  contains databases

Database
  contains collections

Collection
  contains documents
```

Example:

```text
mongodb container
  orderdb database
    orders collection
      order documents

  paymentdb database
    payments collection
      payment documents
```

---

## order-service Database

Database:

```javascript
use orderdb
```

Collection:

```text
orders
```

Show collections:

```javascript
show collections
```

View sample documents:

```javascript
db.orders.find()
```

Pretty-print documents:

```javascript
db.orders.find().pretty()
```

Count orders:

```javascript
db.orders.countDocuments()
```

Find one order by `orderId`:

```javascript
db.orders.findOne({ orderId: "ORD-1002" })
```

---

## orderdb Indexes

Check indexes:

```javascript
use orderdb
db.orders.getIndexes()
```

Expected indexes:

```javascript
[
  { v: 2, key: { _id: 1 }, name: "_id_" },
  { v: 2, key: { orderId: 1 }, name: "orderId_1", unique: true }
]
```

### Index Explanation

| Index       | Type                  | Purpose                                               |
| ----------- | --------------------- | ----------------------------------------------------- |
| `_id_`      | Default MongoDB index | Automatically created by MongoDB for every collection |
| `orderId_1` | Custom unique index   | Prevents duplicate order IDs                          |

The `_id_` index is created automatically by MongoDB.

The `orderId_1` index is custom and should be recreated if the database is deleted.

### Recreate orderdb Indexes

```javascript
use orderdb

db.orders.createIndex(
  { orderId: 1 },
  { unique: true }
)
```

Verify:

```javascript
db.orders.getIndexes()
```

---

## payment-service Database

Database:

```javascript
use paymentdb
```

Collection:

```text
payments
```

Show collections:

```javascript
show collections
```

View sample documents:

```javascript
db.payments.find()
```

Pretty-print documents:

```javascript
db.payments.find().pretty()
```

Count payments:

```javascript
db.payments.countDocuments()
```

Find payment by `orderId`:

```javascript
db.payments.findOne({ orderId: "ORD-1002" })
```

Find payment by `eventId`:

```javascript
db.payments.findOne({ eventId: "some-event-id" })
```

---

## paymentdb Indexes

Check indexes:

```javascript
use paymentdb
db.payments.getIndexes()
```

Expected indexes:

```javascript
[
  { v: 2, key: { _id: 1 }, name: "_id_" },
  { v: 2, key: { orderId: 1 }, name: "orderId_1", unique: true },
  { v: 2, key: { eventId: 1 }, name: "eventId_1", unique: true }
]
```

### Index Explanation

| Index       | Type                  | Purpose                                               |
| ----------- | --------------------- | ----------------------------------------------------- |
| `_id_`      | Default MongoDB index | Automatically created by MongoDB for every collection |
| `orderId_1` | Custom unique index   | Prevents duplicate payment records for the same order |
| `eventId_1` | Custom unique index   | Prevents duplicate Kafka event processing             |

The `eventId_1` index is important for idempotency. If the same Kafka event is consumed more than once, the unique `eventId` index helps prevent duplicate payment records.

### Recreate paymentdb Indexes

```javascript
use paymentdb

db.payments.createIndex(
  { orderId: 1 },
  { unique: true }
)

db.payments.createIndex(
  { eventId: 1 },
  { unique: true }
)
```

Verify:

```javascript
db.payments.getIndexes()
```

---

## customer-service Database

The customer-service is planned for a future iteration.

Planned database:

```javascript
use customerdb
```

Planned collection:

```text
customers
```

Possible future indexes:

```javascript
db.customers.createIndex(
  { customerId: 1 },
  { unique: true }
)

db.customers.createIndex(
  { email: 1 },
  { unique: true }
)
```

This section should be finalized when `customer-service` is implemented.

---

## List Indexes for All Collections in a Database

Use this command after selecting a database:

```javascript
db.getCollectionNames().forEach(function(collectionName) {
  print("Collection: " + collectionName);
  printjson(db.getCollection(collectionName).getIndexes());
});
```

Example for `orderdb`:

```javascript
use orderdb

db.getCollectionNames().forEach(function(collectionName) {
  print("Collection: " + collectionName);
  printjson(db.getCollection(collectionName).getIndexes());
});
```

Example for `paymentdb`:

```javascript
use paymentdb

db.getCollectionNames().forEach(function(collectionName) {
  print("Collection: " + collectionName);
  printjson(db.getCollection(collectionName).getIndexes());
});
```

---

## Reset MongoDB Data

Use this only when old local data is not needed.

### Step 1: Stop local environment

```powershell
.\scripts\windows\stop-all.ps1
```

### Step 2: Find MongoDB Docker volume

```powershell
$mongoVolume = docker inspect mongodb --format '{{range .Mounts}}{{if eq .Destination "/data/db"}}{{.Name}}{{end}}{{end}}'
Write-Host "MongoDB volume: $mongoVolume"
```

### Step 3: Remove MongoDB container

```powershell
docker rm -f mongodb
```

### Step 4: Remove MongoDB data volume

```powershell
if ($mongoVolume) {
    docker volume rm $mongoVolume
}
```

### Step 5: Start infrastructure again

```powershell
.\scripts\windows\start-infra.ps1
```

At this point MongoDB is fresh.

Databases and collections will be recreated when the microservices write data.

---

## Recreate Indexes After Reset

After MongoDB is reset and restarted, connect to MongoDB:

```powershell
docker exec -it mongodb mongosh -u admin -p admin123 --authenticationDatabase admin
```

Then recreate indexes.

### orderdb

```javascript
use orderdb

db.orders.createIndex(
  { orderId: 1 },
  { unique: true }
)

db.orders.getIndexes()
```

### paymentdb

```javascript
use paymentdb

db.payments.createIndex(
  { orderId: 1 },
  { unique: true }
)

db.payments.createIndex(
  { eventId: 1 },
  { unique: true }
)

db.payments.getIndexes()
```

---

## Verify Databases After Running Test Order

After starting services and creating one test order:

```powershell
.\scripts\windows\test-order.ps1
```

Connect to MongoDB:

```powershell
docker exec -it mongodb mongosh -u admin -p admin123 --authenticationDatabase admin
```

Check databases:

```javascript
show dbs
```

Check orders:

```javascript
use orderdb
show collections
db.orders.find().pretty()
db.orders.getIndexes()
```

Check payments:

```javascript
use paymentdb
show collections
db.payments.find().pretty()
db.payments.getIndexes()
```

---

## Troubleshooting

### Container name conflict

Error:

```text
Conflict. The container name "/mongodb" is already in use.
```

Fix:

```powershell
docker rm -f mongodb
```

Then start infrastructure again:

```powershell
.\scripts\windows\start-infra.ps1
```

If Kafka or Kafka UI have the same issue:

```powershell
docker rm -f kafka kafka-ui
```

Then restart:

```powershell
.\scripts\windows\start-infra.ps1
```

---

### MongoDB is running but application cannot connect

Check that the container is running:

```powershell
docker ps
```

Check logs:

```powershell
docker logs mongodb
```

Check port:

```powershell
Get-NetTCPConnection -LocalPort 27017 -State Listen
```

Expected local port:

```text
27017
```

---

### Authentication failed

Make sure the application connection string includes:

```text
authSource=admin
```

Example:

```text
mongodb://admin:admin123@localhost:27017/orderdb?authSource=admin
```

---

### Duplicate key error

Example error:

```text
E11000 duplicate key error
```

This usually means a unique index rejected duplicate data.

For `orderdb.orders`, duplicate `orderId` is not allowed.

For `paymentdb.payments`, duplicate `orderId` and duplicate `eventId` are not allowed.

Check existing document:

```javascript
use orderdb
db.orders.findOne({ orderId: "ORD-1002" })
```

or:

```javascript
use paymentdb
db.payments.findOne({ orderId: "ORD-1002" })
```

---

## Best Practices Used in This Setup

1. Each microservice owns its own logical database.
2. Other services should not directly access another service’s database.
3. MongoDB collections are recreated automatically when services write data.
4. Important business uniqueness rules are enforced through unique indexes.
5. Local development may use one MongoDB container, but service ownership is still separated by database.
6. Production environments should use stronger separation through credentials, access control, or separate MongoDB clusters where appropriate.

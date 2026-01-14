# VynqTalk API Documentation (iOS Aligned)

This document provides details on how to interact with the VynqTalk backend, specifically aligned with the iOS application requirements.

## General Information

- **Base URL**: `http://localhost:8080`
- **WebSocket URL**: `ws://localhost:8080/ws`
- **Content-Type**: `application/json`
- **Date Format**: ISO8601 (e.g., `2026-01-14T06:24:16Z`)

---

## Standard Response Format

All HTTP and WebSocket responses follow this structure:

```json
{
  "success": true,
  "data": { ... },
  "message": "event_type_or_info"
}
```

---

## Authentication

Authentication is handled via **JWT**. 

1. Obtain a token via `POST /auth/signup` or `POST /auth/login`.
2. For Protected routes, include: `Authorization: Bearer <token>`
3. For WebSocket, include: `?token=<token>`

---

## WebSocket Implementation

### Connection
`ws://localhost:8080/ws?token=<JWT_TOKEN>`

### Sending a message (iOS → Backend)
```json
{
  "type": "chat_message",
  "receiverId": "UUID-STR",
  "content": "Hello",
  "messageType": "TEXT" 
}
```
*Note: `messageType` can be `TEXT`, `IMAGE`, `AUDIO`, `VIDEO`, `FILE`.*

### Receiving a message (Backend → iOS)
```json
{
  "success": true,
  "data": {
    "id": "MSG-UUID",
    "content": "Hello",
    "type": "TEXT",
    "sender": { "id": "...", "name": "...", "online": true ... },
    "receiver": { "id": "...", "name": "...", "online": true ... },
    "timestamp": "2026-01-14T06:24:16Z",
    "edited": false,
    "reactions": []
  },
  "message": "chat_message"
}
```

### Typing Indicators
```json
{
  "type": "typing",
  "userId": "YOUR-UUID",
  "receiverId": "OTHER-UUID",
  "isTyping": true
}
```

### Message Read Status
```json
{
  "type": "message_read",
  "messageId": "MSG-UUID",
  "senderId": "ORIGINAL-SENDER-UUID",
  "readerId": "YOUR-UUID"
}
```

### User Status Updates (Server → iOS)
```json
{
  "success": true,
  "data": {
    "userId": "USER-UUID",
    "online": true,
    "lastActive": "2026-01-14T06:24:16Z"
  },
  "message": "user_status"
}
```

---

## HTTP Endpoints (REST)

### Auth
- `POST /auth/signup`: `{ name, email, password }`
- `POST /auth/login`: `{ email, password }`

### Users
- `GET /user`: Current profile
- `GET /users`: List all users (excluding self)
- `GET /users/search?query=...`: Search
- `PATCH /users/:id/status`: Update status

### Messages
- `GET /messages/conversation/:user1/:user2`: Chat history
- `POST /messages`: Fallback send

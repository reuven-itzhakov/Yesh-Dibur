# Yesh Dibur Backend

Backend API for the Yesh Dibur platform.

## Tech Stack

- **Runtime:** Node.js + Express
- **Database:** PostgreSQL + PostGIS
- **Cache:** Redis
- **Message Queue:** RabbitMQ
- **Auth:** Firebase Authentication
- **Real-time:** Socket.IO
- **Push Notifications:** Firebase Cloud Messaging

## Project Structure

```
src/
├── config/          # Configuration (DB, Firebase, RabbitMQ, Redis)
├── middlewares/     # Auth, validation, rate limiting
├── api/v1/          # API route definitions
├── controllers/     # Request handlers
├── services/        # Business logic
├── sockets/         # Socket.IO handlers
├── workers/         # Background workers (moderation, push)
├── utils/           # Logger, error handler
├── app.js           # Express app setup
└── server.js        # Entry point
```

## Getting Started

### Prerequisites

- Node.js 18+
- PostgreSQL + PostGIS
- Redis
- RabbitMQ

### Installation

```bash
npm install
```

### Configuration

Copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
```

### Running

```bash
# Development
npm run dev

# Production
npm start
```

### Docker

```bash
docker-compose -f docker/docker-compose.yaml up -d
```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Health check |
| `GET /api/v1/users` | List users |
| `GET /api/v1/groups` | List groups |
| `GET /api/v1/threads` | List threads |
| `GET /api/v1/chats` | List chats |
| `GET /api/v1/search` | Search |
| `GET /api/v1/feeds` | Feed |

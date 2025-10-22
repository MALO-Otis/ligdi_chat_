# Ligdi Chat Server - Deployment Guide

This guide shows how to deploy the Node/Express/Socket.IO/Prisma server so your mobile app can connect from anywhere.

## 1) Requirements

- Node.js 18+ (or Docker)
- Prisma CLI installed by npm scripts
- DATABASE_URL configured in `.env`
- JWT_SECRET set to a long random string

Copy `.env.example` to `.env` and adjust values.

```bash
cp .env.example .env
# Edit .env: set JWT_SECRET, DATABASE_URL
```

## 2) Database options

- Dev: SQLite
  - DATABASE_URL="file:./dev.db"
  - Run migrations: `npm run prisma:migrate`
- Prod: Postgres (recommended)
  - Example: `DATABASE_URL="postgresql://user:password@host:5432/dbname?schema=public"`
  - Run migrations: `npm run prisma:migrate`

## 3) Deploy with Docker (any VPS or container host)

Build and run locally:

```bash
docker build -t ligdi-chat-server .
docker run -p 4000:4000 --env-file .env -v $(pwd)/uploads:/app/uploads ligdi-chat-server
```

- Port 4000 will be exposed.
- Media files are stored under `/app/uploads`; the volume mount persists them.

## 4) Render.com (Docker)

- Create a new Web Service, connect your repo
- Select Docker as build method (Dockerfile provided)
- Add environment variables from `.env`
- Expose port 4000
- Deploy

## 5) Railway.app (Docker)

- Create a new project, connect your repo
- Use the Dockerfile
- Add variables (PORT, JWT_SECRET, DATABASE_URL)
- Deploy

## 6) After deploy

- Check health: `https://your-domain/health` should return `{ ok: true }`
- Your mobile app’s server URL should be set to `https://your-domain` (no trailing slash)
- Ensure `android:usesCleartextTraffic` is false in production if using HTTPS only

## 7) WebRTC in production

For reliable calls across networks, configure TURN ICE servers in the mobile app (flutter_webrtc). Example:

```dart
final config = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {
      'urls': 'turn:your-turn.example.com:3478',
      'username': 'user',
      'credential': 'pass'
    },
  ]
};
```

Use a managed TURN service (Twilio/Nimble/Vonage) or self-host coturn.

## 8) Security notes

- REST is protected by JWT (Authorization: Bearer)
- Socket.IO now supports JWT in the handshake query (`token`); the server derives `senderId` from the token for message:send and checks conversation membership
- Rate limiting and request size limits can be added behind a reverse proxy (NGINX) or via middleware

## 9) Updates & migrations

- Pull latest code
- Rebuild the Docker image
- Run `npm run prisma:migrate` against the target database
- Redeploy

## 10) Troubleshooting

- 502/504: Check container logs for startup errors
- 401: Verify JWT_SECRET matches between backend and client tokens
- Uploads 404: Ensure volume mount for `/app/uploads` persists and directory is writable
- WebRTC fails remotely: add a TURN server, confirm firewall allows UDP/3478

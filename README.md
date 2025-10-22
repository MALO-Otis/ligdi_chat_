# Ligdi Chat

An online chat platform (texte, audio, vidéo) composed of:

- Backend: Node.js (Express + Prisma + Socket.IO)
- Frontend: Flutter (Android/iOS/Web/desktop) with chat UI, audio recording, video upload, and basic WebRTC

## Prérequis / Prerequisites

- Node.js 18+
- Flutter 3.24+ (Dart 3.8+)

## Démarrage backend (Windows PowerShell)

```
cd "server"
npm install
npm run prisma:generate
npm run prisma:migrate
npm run dev
```

Le serveur écoute sur http://localhost:4000. Les fichiers uploadés sont servis via `/uploads/...`.

## Démarrage Flutter

```
cd "..\ligdi_chat"
flutter pub get
# Lancez sur un émulateur ou appareil :
flutter run
```

Remarque Android:
- Sur un émulateur Android, utilisez http://10.0.2.2:4000 comme API Base (champ en haut de l'écran) au lieu de localhost.
- Assurez-vous d'accorder les permissions micro/caméra lorsqu'elles sont demandées.

## Fonctionnalités

- Création d'utilisateur par pseudo, création de conversation 1:1
- Messages texte en temps réel (Socket.IO) avec persistance (Prisma/SQLite)
- Enregistrement et envoi de messages audio (Multer, lecture dans l'app)
- Upload vidéo (aperçu lien dans la bulle), base WebRTC (appel vidéo simple, P2P avec STUN)

## Stack technique

- Backend: Express, Prisma (SQLite par défaut), Socket.IO, Multer
- Frontend: Flutter, http, socket_io_client, record, audioplayers, image_picker, flutter_webrtc

## Prochaines étapes suggérées

- Authentification réelle (JWT) au lieu des pseudos libres
- Gestion des groupes, avatars, status (vu/reçu), pagination des messages
- Stockage des médias sur un bucket (S3, Cloud Storage) plutôt que local `/uploads`
- Sécurité CORS affinée, rate limiting
- Déploiement (Render/Fly.io/railway) + base Postgres/MySQL en prod

## Getting Started (Flutter)

If you're new to Flutter, see:

- https://docs.flutter.dev/get-started/codelab
- https://docs.flutter.dev/cookbook

For help with Flutter development, view the online documentation.

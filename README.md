# Ligdi Chat

Mini application de messagerie (texte, audio, vidéo) composée de:

- Un backend Node.js (Express + Prisma + Socket.IO)
- Une app Flutter (Android/iOS/Web/desktop) avec UI de chat, enregistrement audio, upload vidéo et WebRTC basique

## Prérequis

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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

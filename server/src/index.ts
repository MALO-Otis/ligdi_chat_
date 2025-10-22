import 'dotenv/config';
import express from 'express';
import http from 'http';
import cors from 'cors';
import { Server } from 'socket.io';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { prisma } from './prisma';

const PORT = Number(process.env.PORT || 4000);
const CLIENT_ORIGIN = process.env.CLIENT_ORIGIN || '*';

const app = express();
app.use(cors({ origin: CLIENT_ORIGIN, credentials: true }));
app.use(express.json());

// Ensure uploads directory exists
const uploadsDir = path.resolve('uploads');
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

// Static serve uploads
app.use('/uploads', express.static(uploadsDir));

// Root info
app.get('/', (_req, res) => {
  res.send(
    'Ligdi Chat API running. Try GET /health, POST /users, POST /conversations, GET /conversations/:id/messages, POST /upload/audio, POST /upload/video.'
  );
});

// Multer storage
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname);
    const base = path.basename(file.originalname, ext).replace(/\s+/g, '_');
    const stamp = Date.now();
    cb(null, `${base}_${stamp}${ext}`);
  }
});
const upload = multer({ storage });

// Health
app.get('/health', (_req, res) => res.json({ ok: true }));

// Create or get user by username
app.post('/users', async (req, res) => {
  try {
    const { username } = req.body as { username?: string };
    if (!username) return res.status(400).json({ error: 'username required' });
    const user = await prisma.user.upsert({
      where: { username },
      create: { username },
      update: {}
    });
    res.json(user);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

// Create conversation (1:1 by default)
app.post('/conversations', async (req, res) => {
  try {
    const { memberIds } = req.body as { memberIds?: string[] };
    if (!memberIds || memberIds.length < 2) return res.status(400).json({ error: 'memberIds (>=2) required' });

    // For demo: always create a new conversation
    const conversation = await prisma.conversation.create({
      data: {
        isGroup: memberIds.length > 2,
        members: { create: memberIds.map(userId => ({ userId })) }
      },
      include: { members: true }
    });
    res.json(conversation);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

// Find or create 1:1 conversation for memberIds[0] and memberIds[1]
app.post('/conversations/find-or-create', async (req, res) => {
  try {
    const { memberIds } = req.body as { memberIds?: string[] };
    if (!memberIds || memberIds.length < 2) return res.status(400).json({ error: 'memberIds (>=2) required' });
    const a = memberIds[0];
    const b = memberIds[1];
    let conversation = await prisma.conversation.findFirst({
      where: {
        isGroup: false,
        AND: [
          { members: { some: { userId: a } } },
          { members: { some: { userId: b } } },
        ],
      },
      include: { members: true },
    });
    if (!conversation) {
      conversation = await prisma.conversation.create({
        data: { isGroup: false, members: { create: [{ userId: a }, { userId: b }] } },
        include: { members: true },
      });
    }
    res.json(conversation);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

// List messages of a conversation
app.get('/conversations/:id/messages', async (req, res) => {
  try {
    const { id } = req.params;
    const messages = await prisma.message.findMany({
      where: { conversationId: id },
      orderBy: { createdAt: 'asc' }
    });
    res.json(messages);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

// Create text message
app.post('/conversations/:id/messages', async (req, res) => {
  try {
    const { id } = req.params;
    const { senderId, text } = req.body as { senderId?: string; text?: string };
    if (!senderId || !text) return res.status(400).json({ error: 'senderId and text required' });
    const message = await prisma.message.create({
      data: { conversationId: id, senderId, type: 'TEXT', text }
    });
    // Emit via socket
    io.to(`conv:${id}`).emit('message:new', message);
    res.status(201).json(message);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

// Upload audio
app.post('/upload/audio', upload.single('file'), async (req, res) => {
  try {
    const { conversationId, senderId, durationMs } = req.body as any;
    if (!req.file) return res.status(400).json({ error: 'file required' });
    if (!conversationId || !senderId) return res.status(400).json({ error: 'conversationId and senderId required' });
    const mediaUrl = `/uploads/${req.file.filename}`;
    const message = await prisma.message.create({
      data: {
        conversationId,
        senderId,
        type: 'AUDIO',
        mediaUrl,
        durationMs: durationMs ? Number(durationMs) : null
      }
    });
    io.to(`conv:${conversationId}`).emit('message:new', message);
    res.status(201).json(message);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

// Upload video
app.post('/upload/video', upload.single('file'), async (req, res) => {
  try {
    const { conversationId, senderId, durationMs } = req.body as any;
    if (!req.file) return res.status(400).json({ error: 'file required' });
    if (!conversationId || !senderId) return res.status(400).json({ error: 'conversationId and senderId required' });
    const mediaUrl = `/uploads/${req.file.filename}`;
    const message = await prisma.message.create({
      data: {
        conversationId,
        senderId,
        type: 'VIDEO',
        mediaUrl,
        durationMs: durationMs ? Number(durationMs) : null
      }
    });
    io.to(`conv:${conversationId}`).emit('message:new', message);
    res.status(201).json(message);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: CLIENT_ORIGIN, credentials: true }
});

io.on('connection', (socket) => {
  // Join conversation room
  socket.on('join', (conversationId: string) => {
    socket.join(`conv:${conversationId}`);
    socket.emit('joined', { conversationId });
  });

  // Real-time message (alternative to REST)
  socket.on('message:send', async (payload: {
    conversationId: string;
    senderId: string;
    type: 'TEXT' | 'AUDIO' | 'VIDEO';
    text?: string;
    mediaUrl?: string;
    durationMs?: number;
  }) => {
    try {
      const message = await prisma.message.create({ data: payload });
      io.to(`conv:${payload.conversationId}`).emit('message:new', message);
    } catch (e) {
      console.error(e);
      socket.emit('error', { error: 'message_failed' });
    }
  });

  // WebRTC signaling basics (room-based)
  socket.on('webrtc:offer', (data: { conversationId: string; sdp: any }) => {
    socket.to(`conv:${data.conversationId}`).emit('webrtc:offer', { from: socket.id, sdp: data.sdp });
  });
  socket.on('webrtc:answer', (data: { conversationId: string; sdp: any }) => {
    socket.to(`conv:${data.conversationId}`).emit('webrtc:answer', { from: socket.id, sdp: data.sdp });
  });
  socket.on('webrtc:ice', (data: { conversationId: string; candidate: any }) => {
    socket.to(`conv:${data.conversationId}`).emit('webrtc:ice', { from: socket.id, candidate: data.candidate });
  });

  socket.on('disconnect', () => {
    // cleanup if needed
  });
});

server.listen(PORT, async () => {
  console.log(`API listening on http://localhost:${PORT}`);
});

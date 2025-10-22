import 'dotenv/config';
import express from 'express';
import http from 'http';
import cors from 'cors';
import { Server } from 'socket.io';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { prisma } from './prisma';

const PORT = Number(process.env.PORT || 4000);
const CLIENT_ORIGIN = process.env.CLIENT_ORIGIN || '*';
const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret';

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
  res.send('Ligdi Chat API running. Try /health, /auth/register, /auth/login, /users/search, /conversations, /upload/*');
});

// Health
app.get('/health', (_req, res) => res.json({ ok: true }));

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

// Auth middleware
type AuthRequest = express.Request & { userId?: string };
const auth = (req: AuthRequest, res: express.Response, next: express.NextFunction) => {
  const h = req.headers.authorization;
  if (!h?.startsWith('Bearer ')) return res.status(401).json({ error: 'unauthorized' });
  const token = h.slice(7);
  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    req.userId = decoded.sub as string;
    next();
  } catch {
    return res.status(401).json({ error: 'unauthorized' });
  }
};

// Auth routes
app.post('/auth/register', async (req, res) => {
  try {
    const { username, password, displayName } = req.body as { username?: string; password?: string; displayName?: string };
    if (!username || !password) return res.status(400).json({ error: 'username and password required' });
    const hash = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({ data: { username, passwordHash: hash, displayName } });
    const token = jwt.sign({}, JWT_SECRET, { subject: user.id, expiresIn: '7d' });
    res.json({ token, user });
  } catch (e: any) {
    if (e.code === 'P2002') return res.status(409).json({ error: 'username_taken' });
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.post('/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body as { username?: string; password?: string };
    if (!username || !password) return res.status(400).json({ error: 'username and password required' });
    const user = await prisma.user.findUnique({ where: { username } });
    if (!user?.passwordHash) return res.status(401).json({ error: 'invalid_credentials' });
    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) return res.status(401).json({ error: 'invalid_credentials' });
    const token = jwt.sign({}, JWT_SECRET, { subject: user.id, expiresIn: '7d' });
    res.json({ token, user });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.get('/users/me', auth, async (req: AuthRequest, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId! } });
  res.json(user);
});

app.get('/users/search', auth, async (req: AuthRequest, res) => {
  const q = (req.query.q as string | undefined)?.trim();
  // If no query provided, return up to 20 users (excluding current) for discovery
  if (!q) {
    const users = await prisma.user.findMany({
      where: { id: { not: req.userId! } },
      take: 20,
      orderBy: { username: 'asc' },
    });
    return res.json(users);
  }
  const users = await prisma.user.findMany({
    where: {
      OR: [
        { username: { contains: q, mode: 'insensitive' } },
        { displayName: { contains: q, mode: 'insensitive' } },
      ],
      NOT: { id: req.userId! },
    },
    take: 20,
    orderBy: { username: 'asc' },
  });
  res.json(users);
});

// Conversations
app.post('/conversations', auth, async (req: AuthRequest, res) => {
  try {
    const { memberIds } = req.body as { memberIds?: string[] };
    if (!memberIds || memberIds.length < 2) return res.status(400).json({ error: 'memberIds (>=2) required' });
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

app.post('/conversations/find-or-create', auth, async (req: AuthRequest, res) => {
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

app.get('/conversations/:id/messages', auth, async (req: AuthRequest, res) => {
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

app.post('/conversations/:id/messages', auth, async (req: AuthRequest, res) => {
  try {
    const { id } = req.params;
    const { text } = req.body as { text?: string };
    const senderId = req.userId!;
    if (!text) return res.status(400).json({ error: 'text required' });
    const message = await prisma.message.create({
      data: { conversationId: id, senderId, type: 'TEXT', text }
    });
    io.to(`conv:${id}`).emit('message:new', message);
    res.status(201).json(message);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

// Uploads
app.post('/upload/audio', auth, upload.single('file'), async (req: AuthRequest, res) => {
  try {
    const { conversationId, durationMs } = req.body as any;
    if (!req.file) return res.status(400).json({ error: 'file required' });
    if (!conversationId) return res.status(400).json({ error: 'conversationId required' });
    const mediaUrl = `/uploads/${req.file.filename}`;
    const message = await prisma.message.create({
      data: { conversationId, senderId: req.userId!, type: 'AUDIO', mediaUrl, durationMs: durationMs ? Number(durationMs) : null }
    });
    io.to(`conv:${conversationId}`).emit('message:new', message);
    res.status(201).json(message);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

app.post('/upload/video', auth, upload.single('file'), async (req: AuthRequest, res) => {
  try {
    const { conversationId, durationMs } = req.body as any;
    if (!req.file) return res.status(400).json({ error: 'file required' });
    if (!conversationId) return res.status(400).json({ error: 'conversationId required' });
    const mediaUrl = `/uploads/${req.file.filename}`;
    const message = await prisma.message.create({
      data: { conversationId, senderId: req.userId!, type: 'VIDEO', mediaUrl, durationMs: durationMs ? Number(durationMs) : null }
    });
    io.to(`conv:${conversationId}`).emit('message:new', message);
    res.status(201).json(message);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

// Generic file upload (any file). Stores original name in text field, type = 'FILE'
app.post('/upload/file', auth, upload.single('file'), async (req: AuthRequest, res) => {
  try {
    const { conversationId } = req.body as any;
    if (!req.file) return res.status(400).json({ error: 'file required' });
    if (!conversationId) return res.status(400).json({ error: 'conversationId required' });
    const mediaUrl = `/uploads/${req.file.filename}`;
    const original = req.file.originalname;
    const message = await prisma.message.create({
      data: { conversationId, senderId: req.userId!, type: 'FILE', mediaUrl, text: original }
    });
    io.to(`conv:${conversationId}`).emit('message:new', message);
    res.status(201).json(message);
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: 'server_error' });
  }
});

// Server & sockets
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: CLIENT_ORIGIN, credentials: true } });

// Optional socket authentication using JWT from query.token
io.use((socket, next) => {
  try {
    const token = (socket.handshake.query?.token as string | undefined) ?? undefined;
    if (!token) return next(); // allow unauth for now; REST paths are already protected
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    (socket.data as any).userId = decoded.sub as string;
    next();
  } catch {
    // Reject invalid token
    return next(new Error('unauthorized'));
  }
});

io.on('connection', (socket) => {
  socket.on('join', async (conversationId: string) => {
    try {
      const userId = (socket.data as any).userId as string | undefined;
      if (userId) {
        // Verify membership when userId is known
        const member = await prisma.conversationMember.findFirst({ where: { conversationId, userId } });
        if (!member) return; // ignore join if not a member
      }
      socket.join(`conv:${conversationId}`);
      socket.emit('joined', { conversationId });
    } catch (e) {
      console.error(e);
    }
  });

  // Derive senderId from socket token if available; keep for compatibility if token is missing
  socket.on('message:send', async (payload: { conversationId: string; senderId?: string; type: 'TEXT' | 'AUDIO' | 'VIDEO'; text?: string; mediaUrl?: string; durationMs?: number; }) => {
    try {
      const userId = (socket.data as any).userId as string | undefined;
      const senderId = userId ?? payload.senderId;
      if (!senderId) return socket.emit('error', { error: 'unauthorized' });

      // Optional membership check
      const member = await prisma.conversationMember.findFirst({ where: { conversationId: payload.conversationId, userId: senderId } });
      if (!member) return socket.emit('error', { error: 'not_member' });

      const message = await prisma.message.create({ data: { ...payload, senderId } });
      io.to(`conv:${payload.conversationId}`).emit('message:new', message);
    } catch (e) {
      console.error(e);
      socket.emit('error', { error: 'message_failed' });
    }
  });

  socket.on('webrtc:offer', (data: { conversationId: string; sdp: any }) => {
    socket.to(`conv:${data.conversationId}`).emit('webrtc:offer', { from: socket.id, conversationId: data.conversationId, sdp: data.sdp });
  });
  socket.on('webrtc:answer', (data: { conversationId: string; sdp: any }) => {
    socket.to(`conv:${data.conversationId}`).emit('webrtc:answer', { from: socket.id, conversationId: data.conversationId, sdp: data.sdp });
  });
  socket.on('webrtc:ice', (data: { conversationId: string; candidate: any }) => {
    socket.to(`conv:${data.conversationId}`).emit('webrtc:ice', { from: socket.id, conversationId: data.conversationId, candidate: data.candidate });
  });
});

server.listen(PORT, async () => {
  console.log(`API listening on http://localhost:${PORT}`);
});

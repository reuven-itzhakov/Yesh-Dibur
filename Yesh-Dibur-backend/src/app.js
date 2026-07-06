const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimiter = require('./middlewares/rateLimiter');
const errorHandler = require('./utils/errorHandler');

const app = express();

app.set('trust proxy', 1);

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CLIENT_URL || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '2mb' }));
app.use(rateLimiter);

// Routes
const users = require('./api/v1/users');
const groups = require('./api/v1/groups');
const threads = require('./api/v1/threads');
const chats = require('./api/v1/chats');
const search = require('./api/v1/search');
const feeds = require('./api/v1/feeds');
const deviceRoutes = require('./api/v1/devices'); 
const notifications = require('./api/v1/notifications');

app.use('/api/v1/users', users);
app.use('/api/v1/groups', groups);
app.use('/api/v1/threads', threads);
app.use('/api/v1/chats', chats);
app.use('/api/v1/search', search);
app.use('/api/v1/feeds', feeds);
app.use('/api/v1/devices', deviceRoutes);
app.use('/api/v1/notifications', notifications);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date() });
});

// Global Error handling middleware
app.use(errorHandler);

module.exports = app;
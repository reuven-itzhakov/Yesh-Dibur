const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimiter = require('./middlewares/rateLimiter');
const errorHandler = require('./utils/errorHandler');

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(rateLimiter);

// Routes
const users = require('./api/v1/users');
const groups = require('./api/v1/groups');
const threads = require('./api/v1/threads');
const chats = require('./api/v1/chats');
const search = require('./api/v1/search');
const feeds = require('./api/v1/feeds');

app.use('/api/v1/users', users);
app.use('/api/v1/groups', groups);
app.use('/api/v1/threads', threads);
app.use('/api/v1/chats', chats);
app.use('/api/v1/search', search);
app.use('/api/v1/feeds', feeds);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Error handling
app.use(errorHandler);

module.exports = app;

'use strict';

const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
  res.status(200).json({
    message: 'DevOps Challenge App — Running on AWS ECS Fargate',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

app.get('/info', (req, res) => {
  res.status(200).json({
    app: 'devops-challenge-app',
    version: process.env.APP_VERSION || '1.0.0',
    node: process.version,
    platform: process.platform,
  });
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`[INFO] Server started on port ${PORT}`);
  console.log(`[INFO] NODE_ENV=${process.env.NODE_ENV || 'development'}`);
});

process.on('SIGTERM', () => {
  console.log('[INFO] SIGTERM received — shutting down gracefully');
  server.close(() => {
    console.log('[INFO] Server closed');
    process.exit(0);
  });
});

module.exports = app;
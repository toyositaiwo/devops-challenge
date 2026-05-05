'use strict';

const request = require('supertest');
const app = require('./index');

describe('DevOps Challenge App', () => {
  describe('GET /', () => {
    it('returns 200 with app message', async () => {
      const res = await request(app).get('/');
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('message');
      expect(res.body.message).toContain('DevOps Challenge App');
    });
  });

  describe('GET /health', () => {
    it('returns 200 with healthy status', async () => {
      const res = await request(app).get('/health');
      expect(res.statusCode).toBe(200);
      expect(res.body.status).toBe('healthy');
      expect(res.body).toHaveProperty('timestamp');
      expect(res.body).toHaveProperty('uptime');
    });
  });

  describe('GET /info', () => {
    it('returns 200 with app info', async () => {
      const res = await request(app).get('/info');
      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveProperty('app');
      expect(res.body).toHaveProperty('node');
    });
  });

  describe('GET /unknown', () => {
    it('returns 404 for unknown routes', async () => {
      const res = await request(app).get('/does-not-exist');
      expect(res.statusCode).toBe(404);
    });
  });
});
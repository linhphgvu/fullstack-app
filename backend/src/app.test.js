const request = require('supertest');
const express = require('express');

// Import your app setup (we'll refactor index.js to be testable)
const createApp = () => {
  const app = express();
  app.use(express.json());

  app.get('/api/health', (req, res) => {
    res.json({ status: 'healthy', timestamp: new Date().toISOString() });
  });

  app.get('/api/hello', (req, res) => {
    res.json({ message: 'Hello from the backend!', environment: process.env.NODE_ENV });
  });

  return app;
};

describe('API Endpoints', () => {
  let app;

  beforeEach(() => {
    app = createApp();
  });

  describe('GET /api/health', () => {
    it('should return health status', async () => {
      const response = await request(app)
        .get('/api/health')
        .expect(200);

      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('timestamp');
    });
  });

  describe('GET /api/hello', () => {
    it('should return hello message', async () => {
      const response = await request(app)
        .get('/api/hello')
        .expect(200);

      expect(response.body).toHaveProperty('message', 'Hello from the backend!');
    });
  });
});
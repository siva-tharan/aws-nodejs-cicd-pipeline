'use strict';

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const express = require('express');
const pkg = require('../package.json');

// Written by scripts/after_install.sh on every CodeDeploy deployment.
const DEPLOY_INFO_FILE = path.join(__dirname, '..', 'deploy-info.json');

function readDeployInfo() {
  try {
    return JSON.parse(fs.readFileSync(DEPLOY_INFO_FILE, 'utf8'));
  } catch {
    return null; // running locally, not deployed by CodeDeploy
  }
}

function createApp() {
  const app = express();

  app.disable('x-powered-by');
  app.use((req, res, next) => {
    res.set({
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'Referrer-Policy': 'no-referrer',
    });
    next();
  });

  app.use(express.static(path.join(__dirname, '..', 'public')));

  // Used by the CodeDeploy ValidateService hook
  app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
  });

  app.get('/api/info', (req, res) => {
    res.json({
      app: pkg.name,
      version: pkg.version,
      hostname: os.hostname(),
      node: process.version,
      uptimeSeconds: Math.round(process.uptime()),
      deployment: readDeployInfo(),
    });
  });

  app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
  });

  return app;
}

module.exports = { createApp };

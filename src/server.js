'use strict';

const { createApp } = require('./app');

const port = Number(process.env.PORT) || 3000;

const server = createApp().listen(port, () => {
  console.log(`Server listening on port ${port}`);
});

// systemd sends SIGTERM on stop/restart: finish in-flight requests, then exit
process.on('SIGTERM', () => {
  console.log('SIGTERM received - shutting down');
  server.close(() => process.exit(0));
});

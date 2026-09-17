const cluster = require('cluster');
const os = require('os');
const path = require('path');

const numCPUs = os.cpus().length || 2;

if (cluster.isPrimary) {
  console.log(`⚡ MyVault Master Cluster ${process.pid} is starting with ${numCPUs} worker processes...`);

  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  cluster.on('online', (worker) => {
    console.log(`🟢 Worker ${worker.process.pid} is online and ready for traffic.`);
  });

  cluster.on('exit', (worker, code, signal) => {
    console.warn(`⚠️ Worker ${worker.process.pid} exited (signal: ${signal}, code: ${code}). Spawning a replacement worker...`);
    cluster.fork();
  });
} else {
  require('./server.js');
}

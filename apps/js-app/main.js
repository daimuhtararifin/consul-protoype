const http = require('http');

// Baca dari Environment Variable
const APP_NAME = process.env.APP_NAME || 'unknown-js-app';
const APP_PORT = process.env.APP_PORT || 3000;
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

const server = http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            service: APP_NAME,
            port: APP_PORT,
            log_level: LOG_LEVEL,
            config_source: "environment variable",
            message: "Config loaded successfully!"
        }));
    } else {
        res.writeHead(404);
        res.end();
    }
});

server.listen(APP_PORT, () => {
    console.log(`[${APP_NAME.toUpperCase()}] Starting on port ${APP_PORT} (log_level=${LOG_LEVEL})`);
});

'use strict';

const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');

const PORT = 3000;
const LOG_DIR = '/var/log/nodeapp';
const LOG_FILE = path.join(LOG_DIR, 'app.log');

function log(level, message) {
    const entry = {
        timestamp: new Date().toISOString(),
        level: level,
        message: message
    };

    const line = JSON.stringify(entry) + '\n';

    fs.mkdirSync(LOG_DIR, { recursive: true });
    fs.appendFileSync(LOG_FILE, line);

    console.log(line);
}

function respond(res, status, data) {
    res.writeHead(status, {
        'Content-Type': 'application/json'
    });

    res.end(JSON.stringify(data, null, 2));
}

const server = http.createServer((req, res) => {

    const pathname = new URL(
        req.url,
        `http://${req.headers.host || 'localhost'}`
    ).pathname;

    // HEALTH CHECK
    if (pathname === '/health') {

        return respond(res, 200, {
            status: 'OK',
            uptime: process.uptime(),
            hostname: os.hostname(),
            timestamp: new Date().toISOString()
        });
    }

    // INTENTIONAL ERROR
    if (pathname === '/error') {

        log('ERROR', 'ERROR: something went wrong');

        return respond(res, 500, {
            status: 'ERROR',
            message: 'something went wrong'
        });
    }

    // CPU STRESS TEST
    if (pathname === '/stress') {

        const duration = 30000;
        const end = Date.now() + duration;

        let iterations = 0;
        let result = 0;

        log('INFO', 'CPU stress test started');

        while (Date.now() < end) {
            result += Math.sqrt((iterations % 10000) + 1);
            iterations++;
        }

        log('INFO', 'CPU stress test completed');

        return respond(res, 200, {
            status: 'completed',
            duration_seconds: 30,
            iterations: iterations,
            checksum: result
        });
    }

    return respond(res, 404, {
        message: 'Endpoint not found'
    });
});

server.listen(PORT, '0.0.0.0', () => {
    log('INFO', `Application running on port ${PORT}`);
});
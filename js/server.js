const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const PUBLIC_DIR = path.resolve(process.argv[2] || '.');

const MIME_TYPES = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'text/javascript',
    '.jpg': 'image/jpeg',
    '.png': 'image/png',
    '.md': 'text/markdown'
};

const server = http.createServer((req, res) => {
    const safeUrl = req.url.split('?')[0];
    // Resolve relative to PUBLIC_DIR (the leading '.' stops a URL like
    // "/../../etc/passwd" from being treated as an absolute path), then
    // verify the result is still inside PUBLIC_DIR before serving anything -
    // path.join alone does not prevent ".." segments from escaping it.
    let filePath = path.resolve(PUBLIC_DIR, '.' + safeUrl);
    if (filePath !== PUBLIC_DIR && !filePath.startsWith(PUBLIC_DIR + path.sep)) {
        res.statusCode = 403;
        res.setHeader('Content-Type', 'text/plain');
        res.end('403 Forbidden');
        return;
    }

    try {
        if (fs.statSync(filePath).isDirectory()) {
            filePath = path.join(filePath, 'index.html');
        }
    } catch (e) {
        // File doesn't exist, readFile will return 404
    }

    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.statusCode = 404;
            res.setHeader('Content-Type', 'text/plain');
            res.end('404 Not Found');
            return;
        }

        const ext = path.extname(filePath).toLowerCase();
        const contentType = MIME_TYPES[ext] || 'application/octet-stream';
        res.statusCode = 200;
        res.setHeader('Content-Type', contentType);
        res.end(data);
    });
});

server.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}/`);
});

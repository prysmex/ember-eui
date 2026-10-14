// Minimal static server for site/dist with an SPA fallback to index.html.
//   node tests/leak/serve.mjs [distDir=dist] [port=4791]
import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import { extname, join, normalize, resolve } from 'node:path';

const dist = resolve(process.argv[2] ?? 'dist');
const port = Number(process.argv[3] ?? 4791);
const types = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.css': 'text/css', '.json': 'application/json', '.svg': 'image/svg+xml',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.woff2': 'font/woff2',
  '.woff': 'font/woff', '.txt': 'text/plain', '.md': 'text/markdown', '.map': 'application/json',
};

createServer(async (req, res) => {
  const path = normalize(decodeURIComponent(new URL(req.url, 'http://x').pathname));
  let file = join(dist, path);
  if (!file.startsWith(dist)) return res.writeHead(403).end();
  try {
    if (!(await stat(file)).isFile()) throw 0;
  } catch {
    file = join(dist, 'index.html');
  }
  const body = await readFile(file);
  res.writeHead(200, { 'content-type': types[extname(file)] ?? 'application/octet-stream' });
  res.end(body);
}).listen(port, '127.0.0.1', () => console.log(`serving ${dist} on http://127.0.0.1:${port}`));

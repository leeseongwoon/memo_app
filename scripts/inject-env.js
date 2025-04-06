const fs = require('fs');
const path = require('path');
require('dotenv').config();

const buildPath = path.join(__dirname, '../build/web');
const indexPath = path.join(buildPath, 'index.html');

let html = fs.readFileSync(indexPath, 'utf8');

// Replace placeholder with actual API key
html = html.replace('__FIREBASE_API_KEY__', process.env.FIREBASE_API_KEY || '');

fs.writeFileSync(indexPath, html); 
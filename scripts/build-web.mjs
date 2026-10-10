// Builds the Markette web app and copies it into www/ for Capacitor.
// Uses ../markette-web (sibling checkout) by default; override with WEB_DIR=/path/to/markette-web.
import { execSync } from 'node:child_process';
import { cpSync, existsSync, rmSync } from 'node:fs';
import { resolve } from 'node:path';

const candidates = [process.env.WEB_DIR, '../markette-web', '../frontend'].filter(Boolean).map((p) => resolve(p));
const web = candidates.find((p) => existsSync(resolve(p, 'angular.json')));
if (!web) {
  console.error('markette-web not found. Clone it next to this repo or set WEB_DIR.');
  process.exit(1);
}
console.log(`Building the web app in ${web}`);
const run = (cmd) => execSync(cmd, { cwd: web, stdio: 'inherit' });
if (!existsSync(resolve(web, 'node_modules'))) run('npm ci');
run('npm run build');
rmSync('www', { recursive: true, force: true });
cpSync(resolve(web, 'dist/frontend/browser'), 'www', { recursive: true });
console.log('Copied the web build into www/');

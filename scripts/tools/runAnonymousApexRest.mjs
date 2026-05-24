import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';

const [,, orgAlias, apexFile] = process.argv;

if (!orgAlias || !apexFile) {
  console.error('Usage: node scripts/tools/runAnonymousApexRest.mjs <org-alias> <apex-file>');
  process.exit(1);
}

const displayOutput = execFileSync('sf', ['org', 'display', '--target-org', orgAlias], {
  encoding: 'utf8',
  stdio: ['ignore', 'pipe', 'pipe']
});

function tableValue(label) {
  const line = displayOutput.split('\n').find((row) => row.includes(`│ ${label}`));
  if (!line) {
    return null;
  }
  const cells = line.split('│').map((cell) => cell.trim()).filter(Boolean);
  return cells.length >= 2 ? cells[1] : null;
}

const accessToken = tableValue('Access Token');
const instanceUrl = tableValue('Instance Url');

if (!accessToken || !instanceUrl) {
  console.error('Unable to read org connection from sf org display output.');
  process.exit(1);
}
const apex = readFileSync(apexFile, 'utf8');
const url = `${instanceUrl}/services/data/v66.0/tooling/executeAnonymous/?anonymousBody=${encodeURIComponent(apex)}`;

const response = await fetch(url, {
  method: 'GET',
  headers: {
    Authorization: `Bearer ${accessToken}`,
    Accept: 'application/json'
  }
});

const text = await response.text();
let payload;
try {
  payload = JSON.parse(text);
} catch {
  payload = { raw: text };
}

if (!response.ok || payload.success === false) {
  console.error(JSON.stringify(payload, null, 2));
  process.exit(1);
}

console.log(JSON.stringify(payload, null, 2));

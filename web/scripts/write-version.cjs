const fs = require('fs');
const path = require('path');

function main() {
  const pkgPath = path.join(__dirname, '..', 'package.json');
  const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf-8'));
  const version = pkg.version || 'dev';
  const commit = process.env.COMMIT || process.env.GIT_COMMIT || '';
  const branch = process.env.BRANCH || process.env.GIT_BRANCH || '';
  const buildDate = process.env.BUILD_DATE || new Date().toISOString();

  const outDir = path.join(__dirname, '..', 'public');
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  const outFile = path.join(outDir, 'version.json');

  const payload = { version, commit, branch, buildDate };
  fs.writeFileSync(outFile, JSON.stringify(payload, null, 2));
  console.log(`Wrote frontend version to ${outFile}:`, payload);
}

main();

// Lists a file's top-level declarations and class members with their lines.
// Usage: node index.mjs <file>
import { readFileSync } from 'node:fs';
import { parseFile } from './parse.mjs';

const file = process.argv[2];
const { tops, classes } = parseFile(
  readFileSync(file, 'utf8'),
  file,
  new Set()
);
for (const t of tops)
  console.log(`top\t${t.name}\t${t.kind}\t${t.line}-${t.end}`);
for (const c of classes) {
  console.log(
    `class\t${c.name}\t${c.line}-${c.end}\thosted=${c.isHosted}\tcomponent=${c.isComponent}`
  );
  for (const m of c.members)
    console.log(`  ${m.name}\t${m.kind}\t${m.decorators}\t${m.line}-${m.end}`);
}

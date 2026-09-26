/**
 * Refreshes the site's injected copies of the workspace packages (see
 * injectWorkspacePackages in pnpm-workspace.yaml).
 *
 * pnpm syncs them itself after a package's `build` script finishes
 * (syncInjectedDepsAfterScripts), but not when a build never finishes
 * (`rollup --watch` during `pnpm start`) or when turbo restores a build from
 * its cache. This covers both, using pnpm's own syncer:
 *
 *   node scripts/sync-injected.mjs          sync every package once
 *   node scripts/sync-injected.mjs --watch  and again whenever one rebuilds
 */
import { watch } from 'node:fs';
import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import { syncInjectedDeps } from '@pnpm/workspace.injected-deps-syncer';

const workspaceDir = join(dirname(fileURLToPath(import.meta.url)), '..');
const packagesDir = join(workspaceDir, 'packages');

const packages = readdirSync(packagesDir).map((dir) => {
  const pkgRootDir = join(packagesDir, dir);
  const { name } = JSON.parse(readFileSync(join(pkgRootDir, 'package.json'), 'utf8'));

  return { name, pkgRootDir };
});

async function sync({ name, pkgRootDir }) {
  await syncInjectedDeps({ pkgName: name, pkgRootDir, workspaceDir });
}

await Promise.all(packages.map(sync));
console.log(`synced injected copies of ${packages.map((p) => p.name).join(', ')}`);

if (process.argv.includes('--watch')) {
  for (const pkg of packages) {
    let timer;

    // dist/ and declarations/ are the build outputs; debounce a rebuild's
    // burst of writes into a single sync
    for (const output of ['dist', 'declarations']) {
      try {
        watch(join(pkg.pkgRootDir, output), { recursive: true }, () => {
          clearTimeout(timer);
          timer = setTimeout(() => {
            sync(pkg).then(
              () => console.log(`synced ${pkg.name}`),
              (error) => console.error(`failed to sync ${pkg.name}`, error)
            );
          }, 300);
        });
      } catch {
        // not built yet; the package's `build` sync covers the first build
      }
    }
  }

  console.log('watching package builds...');
}

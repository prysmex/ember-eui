# site

Documentation site for Ember EUI: an Ember app built with Vite
(`@embroider/vite`) whose pages are generated from the packages' markdown docs
by [docfy](https://github.com/josemarluedke/docfy) (`@docfy/ember-vite`).

## Development

From the repository root (pnpm 12, e.g. via `corepack enable`):

```sh
pnpm install
pnpm build:packages   # the site consumes the packages' built dist
pnpm --filter site start
```

`start` runs Vite and `scripts/sync-injected.mjs --watch`. The site consumes
the workspace packages as pnpm _injected_ dependencies
(`injectWorkspacePackages` in `pnpm-workspace.yaml`): real copies, so their
peer dependencies resolve to the site's Ember. pnpm refreshes the copies after
a package's `build` script; the sync script also covers `rollup --watch` and
turbo cache hits.

## How the docs are built

- `docfy.config.mjs` lists the markdown sources: `../docs` and
  `../packages/*/docs`.
- `@docfy/ember-vite` writes each page to `app/templates/docs/**` as a
  strict-mode `.gjs` template (generated and gitignored), with each demo as a
  colocated component.
- `lib/docfy-auto-imports.mjs` adds the imports those templates need for
  components and helpers used in the markdown prose (`<EuiText>`, `{{t}}`, …),
  so the markdown stays free of import boilerplate.
- `app/components/docfy-demo/` is the EUI-styled demo frame; `vite.config.mjs`
  points the generated pages at it instead of docfy's default.

## Scripts

- `pnpm start`: dev server
- `pnpm build`: production build into `dist/`
- `pnpm test`: builds in development mode and runs the tests with testem
- `pnpm lint` / `pnpm lint:fix`

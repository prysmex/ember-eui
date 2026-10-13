# Last utils gaps (branch eui-wave/last-utils)

Verified against EUI 123.1.0 source. All gaps exist upstream.

## Closed
- **EuiI18n `mappingFunc`**: `@i18n={{hash mappingFunc=fn}}` per instance, plus `euiI18n.mappingFunc` on the service (the `EuiContext` equivalent for all EUI components). Port of upstream `lookupToken`: strings and string values are mapped, formatting-function results mapped as a whole. `_lookupToken` takes `i18nMappingFunc`. `@i18n.mapping` is now optional.
- **Markdown**: `processingConfig.linkProps` (EuiLink args `color/disabled/external/href/rel/target/type` plus `onClick`; overrides the link's own values; `MarkdownLink` is now a class). `@markdownFormatProps` on the editor (`rootClasses`, `textSize`, `color`, `shouldIncludeDefaultRootClasses`; wins over the `@format*` args). Parsing now uses `remark-parse-no-trim` and the ported `remark-intraword-underscore` (`// @ts-nocheck`, straight port).
- **Container queries**: `matchContainer` port (`utils/container-query/match-container.ts`), `container-query` modifier (`{{containerQuery "(width > 400px)" name=... onChange=...}}`) and `EuiContainerQuery` (yields `matches`, `@condition/@name/@type/@onChange`).
- **Scroll**: `euiXScroll`, `euiXScrollWithShadows` in `@ember-eui/core/theming` (generator list extended, parity test added).
- **PrettyDuration**: `EuiPrettyDuration` component and `@ember-eui/core/utils/pretty-duration` (`prettyDuration`, `showPrettyDuration`, re-exports of the super date picker util).
- Docs: markdown d12, i18n d06 + new d09, container-queries (+d02), scroll (+d02), pretty-duration (+d01); API tables regenerated; `api-docs-pages.json` gained two pages.

## Skipped / moved to Decisions
EuiContext, global `eui-*` classes, `componentDefaults`, react-focus-on options, `useEuiTour`. EuiErrorBoundary left to the coordinator (not touched).

## Behaviour changes
- `i18n/util.ts` `processStringToChildren`: initial `child` is now `undefined` (was `{propName: ''}`), so literal text before the first placeholder is a string and can be mapped. Output unchanged without a mappingFunc; the i18n tests pass.
- A formatting-function token result is no longer re-run through placeholder parsing (upstream behaviour).
- Parsing list gained the no-trim parser and intraword plugin: `foo__bar__baz` stays plain text. No existing test changed.

## For the coordinator
- New dependency `remark-parse-no-trim@^8.0.4` in packages/core/package.json; I hand-edited pnpm-lock.yaml (importer entry; the package was already locked via @elastic/eui). Run `pnpm install` to confirm. I symlinked it into packages/core/node_modules (untracked).
- Registry/components additions only; package.json app-js exports refreshed by rollup.

## Checks
Full core suite 1918/1918 (12 new tests in `eui-last-utils-test.gts`). ember-tsc clean, eslint clean on changed files, parity 357/357, generate-eui-styles clean.

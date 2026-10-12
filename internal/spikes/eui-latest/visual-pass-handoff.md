# Visual pass handoff (eui-wave/visual-pass)

## Pages checked
All 109 docs pages (/ plus every entry in site/dist/docfy-urls.json), at 1280px light, 390px mobile, 1280px dark, with
console/network/overflow capture (script: /tmp/claude-1000/-Users-betocantu93-prysmex-ember-eui/ae33d407-e543-44f1-a709-a93910058464/scratchpad/vp/capture.cjs). Screenshots and per-mode report.json:
`/tmp/claude-1000/-Users-betocantu93-prysmex-ember-eui/ae33d407-e543-44f1-a709-a93910058464/scratchpad/vp2/{d,m,dd}/` (d = desktop, m = mobile, dd = dark desktop). Served from this worktree's site build.
Final sweep: no console errors, no horizontal overflow on any page/mode; the only remaining noise is external images
(unsplash, picsum, youtube, contrib.rocks) blocked by the sandbox firewall. New pages (timeline, skeleton, banner, page
sections, live regions, text truncation) were reviewed visually and are fine.

## Fixed
- First agent (commit "wip(docs)"): demos relying on removed Amsterdam CSS or broken layouts in loading, text, form-control-layout,
  range, super-date-picker, flex, flyout (6 demos), horizontal-rule, resizable-container, collapsible-nav, steps, page-template (3);
  scripts/generate-llms-txt.mjs honors a `url` frontmatter.
- Component bugs (with tests): clear-button cross now composes its scale via EuiIcon @css (was a losing separate class, 16px cross
  overflowed its circle); EuiSelectableList no longer scrolls the page (scrollIntoView) for a checked option, it scrolls only the
  list. Both tests fixed to be correct inside the scaled #ember-testing container (ratio / scale-aware scrollTop).
- Loading page url is `docs/display/loading-indicators` (a route named `loading` is Ember's loading substate);
  site/lib/docs-routes.mjs now honors `url` frontmatter so code splitting sees the page (code-splitting test failed otherwise).
- comment-list demo: icon-only EuiButtonIcon missing aria-label (console warning).
- site docs-test "every docs page renders" got assert.timeout(180s): 109 lazy bundles take ~63s on a loaded machine (limit was 60s).

## Checks
Site: node --test lib 8/8; acceptance 17/17 (entry count 108 still correct); site ember-tsc clean.
Core: full suite 1154/1154; ember-tsc and eslint clean; parity 313/313; api docs check clean.
Note: generate-eui-styles --check fails inside a worktree outside the repo path only because of absolute path comments in
styles.generated.ts (not committed); no real drift.

## Open
None found. Left as is: the server for the final screenshots was run on port 4192 and has been stopped.

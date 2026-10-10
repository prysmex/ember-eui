# EuiPageTemplate audit

Reference: [Elastic EUI 41.4.0 page layouts](https://eui.elastic.co/v41.4.0/#/layout/page).
The documentation host was unavailable in the environment, so the comparison
used the published `@elastic/eui@41.4.0` package's implementation instead.
Both bundled theme files are byte-for-byte identical to that release's
**Amsterdam** light and dark CSS, rather than its original theme.

## Coverage

`packages/core/tests/integration/components/eui-page-template-test.gts` adds
90 browser tests covering all four templates, each with and without a sidebar:

- Header present/absent, named blocks and independent block gates, argument
  fallbacks, content uniqueness, root attributes and landmarks.
- Nested body, content, content-body, header and sidebar options override layout
  defaults, including class names, styles, breadcrumbs, title props and widths.
- Explicit false, null roles and zero widths; reactive updates remove stale
  panel, border, width and role state.
- Full-height false/true/`noscroll`, medium breakpoint transitions at 767/768px,
  centered templates ignoring full-height, and bottom-bar positioning.
- External template, width, height, padding, grow and sidebar changes.
- Fixed bottom-bar options, visibility changes, portal teardown and body cleanup.
- Both bundled themes: computed padding, width, centering, border and shadow;
  actual CSS viewport checks at 375, 767, 768 and 1200px; actual tall-content
  scrolling within a 600px parent and reactive full-height mode changes.

Two additional tests in `eui-panel-test.gts` check decoration changes with the
bundled theme for clickable and non-clickable panels. CSS transitions are
disabled in those tests so assertions observe the final styles.

These are behavioral tests, not a measured line/branch coverage percentage or
an exhaustive cross-product of every component option. Responsive modifier tests
use real resize events with controlled innerWidth; CSS tests separately use
iframe viewports containing the rendered markup to exercise media queries.

## Fixes

- Optional nested args now have optional types and are forwarded consistently,
  taking precedence over each branch's released v41 defaults.
- Centered-body with sidebar no longer emits an unrequested header. Gated header
  blocks stay hidden even when title/description arguments keep the header alive.
- The default minimum height now becomes valid `460px`; CSS strings and
  `fullHeight='noscroll'` are accepted by the public types.
- Optional classes no longer emit literal `undefined` tokens.
- Header/content border defaults follow v41, and bottom-bar props work again.
- Numeric widths in the shared width helper become px strings, including zero.
- Shared panel removal classes now apply when border/shadow are explicitly false
  **or** disallowed by the panel color, matching EUI's released implementation.

Bottom bars remain supported only by the default template, and full-height
remains restricted to default/empty at medium screens and above, as in v41.
The changes preserve the released eight layout structures and the library's
existing Ember named-block API; they do not attempt to reproduce React's generic
HTML-attribute spreading through nested prop objects.

## Validation

The final development test build and Chromium run passed **548 core tests**,
including all 90 page-template cases and both additional panel regressions.
Source type checking, ESLint for the changed page/panel files and tests, API-doc
regeneration, and `git diff --check` also passed.

## Documentation examples

The guide and API reference describe the bundled 1200px Amsterdam width,
optional sections, nested overrides, landmarks, bottom-bar props and full-height
constraints. Twelve live demos now cover all eight layouts; the width, tabs and
full-height examples are interactive. The centered-body example no longer nests
extra main landmarks, and the full-height demo uses enough real text to scroll.

Validation passed: eight docs-generation checks, API-reference freshness,
a development docs-site build, and Chromium checks of all twelve rendered demos,
width/tab interactions, bottom-bar options, both scrolling modes, nested
customization, mobile layout and navigation cleanup, with no browser exceptions.

# Emotion spike — feat/emotion

## Objective and baseline

Evaluate Emotion as an Ember-native styling foundation for ember-eui and as a way to reduce the cost of following modern Elastic UI. This is an opt-in experiment, not a migration of the existing component catalog. The spike is based on master after two separate commits: the Ember/Ember CLI 7.3 upgrade and the native element-helper replacement (minimum consumer Ember 7.1, Node 20.19). Those changes belong to master and are not part of the Emotion spike diff.

Our current components map arguments to EUI classes and load prebuilt light/dark theme files. Modern upstream EUI uses Emotion, React theme/cache providers, and styling hooks. `@emotion/css` is framework independent; `@emotion/react` providers/hooks cannot run directly in Ember.

## Architectural decisions

- Use `@emotion/css/create-instance`, with no React dependency or React hook emulation.
- An owner-scoped `eui-emotion` service supplies the root context and a lazily created style cache. Never store a mutable theme/cache in a module singleton.
- `EuiEmotionProvider` uses `ember-provide-consume-context@0.10.0` to publish a typed context. Descendant components and nested providers resolve their nearest ancestor automatically. It produces no wrapper or global reset. Its yielded context/theme/Button and explicit `@parent` remain optional escape hatches.
- A context resolves its parent, color mode, token overrides, and Emotion instance through reactive getters. Provider arguments and tracked service settings remain reactive. Switching themes must update existing components.
- `useEuiTheme(context)` and `useEuiStyles(context, factory)` are ordinary functions called from Ember getters. Their reads participate in autotracking; they have no React hook ordering/lifecycle rules.
- Share the parent's style cache by default. An explicit cache instance supports separate insertion containers, cache keys, and CSP nonces. The creator owns the cache; components/providers must not flush a shared cache on destruction.
- Preserve the existing `EuiButton`. Port an experimental `EuiEmotionButton`, also available as the provider's yielded `Button`, without legacy EUI class names or CSS dependencies.
- Keep scope small: hand-authored tokens and button styling inspired by EUI, not a claim of pixel parity or direct reuse of the current Borealis theme. Do not copy licensed upstream implementation code into this spike.

## MVP API

```gts
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';
import EuiEmotionButton from '@ember-eui/core/components/eui-emotion-button';

<template>
  <EuiEmotionProvider @colorMode='dark'>
    <EuiEmotionButton @fill={{true}}>Save</EuiEmotionButton>
    <EuiEmotionProvider @colorMode='light'>
      <EuiEmotionButton @color='danger'>Delete</EuiEmotionButton>
    </EuiEmotionProvider>
  </EuiEmotionProvider>
</template>
```

Custom components call `getEuiThemeContext(this)` in getters and pass the result to the styling utilities. They need no context argument. Standalone experimental buttons fall back to the owner service. The service exposes tracked `colorMode` and `overrides` for app-wide settings. The provider accepts `@colorMode`, `@overrides`, `@parent`, and `@cache`.

Supported button MVP: primary/success/warning/danger/text colors; small/medium sizes; filled/outlined; full width; disabled and loading; selected state; native button type; enabled href/target links; yielded content; forwarded attributes and event modifiers. Icons, arbitrary element tags, legacy private class-prefix/content APIs, and exact upstream visual parity are deferred.

## Custom component integration

```ts
import { useEuiTheme, useEuiStyles } from '@ember-eui/core/utils/emotion/context';

import { getEuiThemeContext } from '@ember-eui/core/utils/emotion/consume';
get theme() {
  return useEuiTheme(getEuiThemeContext(this));
}

get styles() {
  return useEuiStyles(getEuiThemeContext(this), (theme) => ({
    color: theme.colors.text,
    backgroundColor: theme.colors.background,
    padding: theme.spacing * 2,
  }));
}
```

Apply `class={{this.styles}}` in the template. Read these functions inside a reactive getter, rather than saving resolved tokens in the constructor. Replace tracked override objects instead of mutating nested fields in place. Lookup follows the component rendering tree, not DOM ancestry. Explicit `@context` on buttons and `@parent` on providers override lookup for deliberate bridging.

For a separate insertion target or CSP nonce, call `createEuiEmotionCache({ key: 'my-app', container, nonce })` and pass the returned Emotion instance as `@cache`. The argument is the whole instance (`css`, `keyframes`, `cache`, etc.), not a raw `@emotion/cache` object. Cache keys must meet Emotion's lowercase-key requirements. The creator must flush its instance when its lifetime ends. The owner service flushes only its internally created instance when the Ember owner is destroyed.

## File map

- `packages/core/src/utils/emotion/theme.ts`: mode, tokens, typed overrides, pure token merge.
- `packages/core/src/utils/emotion/context.ts`: lazy cache factory, context inheritance, styling/theme utilities, owned-cache disposal.
- `packages/core/src/utils/emotion/consume.ts`: typed context key and nearest-provider lookup with owner-service fallback.
- `packages/core/src/services/eui-emotion.ts`: tracked owner defaults and cleanup.
- `packages/core/src/components/eui-emotion-provider.gts`: wrapperless provider and contextual component currying.
- `packages/core/src/components/eui-emotion-button.gts`: first standalone component port.
- `packages/core/tests/integration/components/eui-emotion-test.gts`: focused runtime and lifecycle coverage.
- `site/app/components/emotion-spike.gts`, `docs/emotion.md`, and `site/app/routes/emotion-spike.ts`: interactive docs showcase and original URL redirect.

## Implementation phases and acceptance criteria

1. **Foundation:** typed light/dark tokens, nested context resolution, owner service, cache factory, and reactive style/theme utilities. Merge token overrides without mutating parent/default tokens. Cache construction remains lazy and browser/SSR import-safe.
2. **Provider:** wrapperless provider with automatic nearest-ancestor inheritance and per-subtree mode/overrides/cache. Siblings do not affect each other. Provider lifetime does not flush shared styles.
3. **Button:** consume the foundation, generate styles for the supported states, retain native semantics and focus visibility, use reduced-motion-aware loading animation, and avoid legacy CSS selectors. Disabled/loading href buttons render disabled native buttons.
4. **Demo:** a Documentation sidebar page at `/docs/emotion` (`/emotion-spike` redirects here) with side-by-side light/dark examples, nested branding overrides, theme switching, variants, and a click counter. Keep demo implementation details out of its user-facing controls.
5. **Verification:** build package JS/declarations and production site; type-check site and lint changed files; run integration tests for theme reactivity, inheritance/isolation, cache insertion/deduplication, and button semantics. Check computed styles without loading legacy theme CSS. Run the core suite after adding focused tests.
6. **Assessment:** record actual outcomes below, identify adoption blockers, and recommend either broader Emotion porting or static CSS/CSS variables. No broad dependency upgrades or catalog migration in this spike.

## Testing and evaluation matrix

| Area           | Required evidence                                         | Follow-up before production                                     |
| -------------- | --------------------------------------------------------- | --------------------------------------------------------------- |
| Reactivity     | mode and token changes restyle mounted buttons            | system color-scheme listener and high-contrast mode             |
| Isolation      | nested overrides and modes do not change siblings         | portal/wormhole context propagation conventions                 |
| Cache          | explicit container, stable classes, deduplication         | multiple apps, CSP integration in a real host                   |
| Semantics      | links, disabled/loading, type, click, aria-selected state | full keyboard/a11y audit, icon parity                           |
| Styling        | computed light/dark colors without legacy CSS             | screenshots, contrast audit, browser matrix                     |
| Delivery       | build/declarations/site types pass                        | bundle/runtime comparison against CSS variables                 |
| SSR            | no eager global DOM/cache state                           | FastBoot style extraction and hydration validation              |
| Upstream reuse | separation of token/style logic from Ember UI             | port one actual upstream style factory and count required edits |

## Known boundaries and agent handoff

Do not silently change existing EuiButton or global themes. Do not import `@emotion/react`. Do not flush owner/shared caches in provider destruction. Nearest-provider inheritance is the default; retain explicit overrides for intentional context bridging. Token merging must remain pure. Keep every supported button state independent of legacy CSS.

SSR/FastBoot output and hydration are not production-ready merely because imports are safe. Cache extraction, request isolation, style ordering relative to app overrides, CSP, and the effect of generated class names on downstream customization require further work. Emotion handles nested/media selectors, prefixes, and class hashing, but we still own Ember context propagation and theme APIs.

Suggested next agent tasks after review: (a) upstream style-factory reuse experiment; (b) CSS-variables baseline with identical button behavior; (c) bundle/style-insertion measurement; (d) FastBoot and portal design. Do not begin the remaining catalog migration until these results justify it.

## Verification results

- `pnpm --filter @ember-eui/core build`: passes JS and declaration generation.
- `pnpm build:site`: passes all five package builds and the production site build.
- `pnpm --filter site lint:types`: passes.
- `pnpm --filter site test`: eight Node tests and 14 browser acceptance tests pass, including docs discovery, alias redirect, scoped theme switching, and branding controls.
- `pnpm install --frozen-lockfile`: passes after adding the pinned context dependency.
- ESLint on the new foundation/provider/button/tests and the demo/router: passes.
- `pnpm --filter @ember-eui/core test`: **558 tests pass**, including nine focused Emotion tests. Browser tests used Chromium 149 with the normal Testem configuration and a local Chrome executable shim.
- Real-browser check at `/docs/emotion`: no page errors; click counter increments; theme switching works; keyboard focus outline is visible. Captured [light](emotion-light.png), [dark](emotion-dark.png), and [mobile](emotion-mobile.png) screenshots; the 390px mobile viewport has no horizontal overflow.
- The focused computed-style tests render the Emotion buttons without loading the legacy EUI theme stylesheet. The site deliberately retains legacy CSS for the surrounding documentation layout.
- Nested mode/override changes remain reactive; sibling contexts stay independent; equivalent styles reuse generated classes; a supplied cache supports a custom container and nonce; destruction only flushes an internally owned cache.

## Initial assessment and next decision

The MVP demonstrates that framework-independent Emotion integrates with Ember autotracking and contextual components without React. Nearest-provider lookup removes argument drilling and contextual-component references from ordinary consumers. The context dependency patches private Glimmer internals, so framework compatibility must remain a release gate.

The port is intentionally a supported subset of EuiButton and uses our small hand-authored token set. It does not establish pixel parity with current EUI/Borealis or prove that upstream React styling factories can be reused without significant changes. No incremental bundle-cost or runtime-insertion benchmark has been completed; successful builds are not performance evidence.

Recommendation: keep this branch experimental. Next, port one actual upstream style factory (subject to its applicable license), build the same button with CSS variables, and compare source maintenance, bundle size, theme switching, and style insertion. Evaluate FastBoot extraction/hydration and portal context propagation before widening adoption. Existing components and theme files remain available throughout the experiment.

## Showcase follow-up

The showcase is discoverable from Documentation → Emotion showcase and the introduction. It includes an explicit light/dark page switcher, two fixed-mode contexts side by side, scoped accent and corner controls, a working save counter, a variant gallery, and provider/styling examples. Fixed-mode contexts remain unchanged when switching the page mode. Branding overrides affect only the custom preview. The page shares the owner service cache rather than creating a navigation-scoped cache.

## Nearest-provider context follow-up

The user requested automatic consumption instead of requiring yielded references. Adopted [ember-provide-consume-context](https://github.com/customerio/ember-provide-consume-context), pinned at 0.10.0. Its peer range includes Ember 7; compatibility must also be verified at runtime. `@provide` publishes a stable `EuiThemeContext`; `getEuiThemeContext(this)` reads the nearest ancestor on each getter evaluation and falls back to the current owner's service. Provider lookup excludes itself, avoiding recursive inheritance. An explicit `@parent` wins over lookup; button `@context` wins over lookup. The yielded API remains available but is optional.

- Nested providers inherit mode, merged overrides, and cache without `@parent`.
- Ordinary imported buttons and custom consumer components work across intermediate component boundaries, including descendants mounted after rerender.
- `{{in-element}}` moves DOM while retaining render-tree ancestry. Separate `renderComponent` roots do not inherit merely because their mount element is inside a provider. Use the library's `ContextSnapshot` / `ProvideContexts` bridge (or explicit context) for those roots; independent-root bridging remains a follow-up experiment.
- The library's initializer patches `LowLevelVM` and `EnvironmentImpl` and uses opcode constants. These are private APIs, not native Ember context support. Pin the dependency, test framework upgrades, and evaluate FastBoot before production adoption.
- Our strict standalone core test app must register and run dependency app initializers explicitly; `tests/generate-addon-app-modules.mjs` now includes this library, and `tests/test-helper.ts` registers its initializer on `TestApp`. Consumer applications load its initializer through the normal addon app re-export mechanism.

## Dev server dependency refresh

The site uses injected workspace packages. After changing core's runtime dependencies, run `pnpm install --frozen-lockfile` and restart the site dev server so Embroider rebuilds its package graph. Adding the library to the site itself is unnecessary: core already declares it as a runtime dependency. The site's `start` command now synchronizes injected manifests and build outputs before launching Vite, matching the existing build/test startup order. Previously Vite and the initial synchronization started concurrently, allowing Vite to cache an old manifest. The background synchronizer still watches package build outputs after startup. A running server must be restarted after dependency graph changes.

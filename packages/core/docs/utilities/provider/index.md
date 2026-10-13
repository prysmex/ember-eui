---
title: Provider
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Provider"/>
<EuiSpacer @size="l" />

<EuiText>

Upstream's **EuiProvider** contains the context providers EUI needs: theme, color mode, global styles and the Emotion cache. In Ember EUI that is **EuiEmotionProvider**. Descendants consume the nearest provider automatically, and the `eui-emotion` service supplies the defaults, so an app works without one; render a provider to change the theme or color mode of part of a page, or at the root to control it.

```hbs
<EuiEmotionProvider @colorMode={{if this.isDark "dark" "light"}}>
  {{outlet}}
</EuiEmotionProvider>
```

* **Global styles:** the outermost provider injects EUI's global reset and root typography while it is rendered (upstream's `globalStyles`). Nested providers never do. Pass `@globalStyles={{false}}` when your app owns its global styles.
* **Color mode:** `@colorMode` is `"light"` or `"dark"`. A root provider with none follows the operating system's `prefers-color-scheme`; nested providers inherit their parent's.
* **High contrast:** `@highContrastMode` (`true` or `"preferred"`, `false`, `"forced"`); a root provider follows the operating system when it is unset.
* **Theming:** `@borealisOverrides` and `@overrides` modify the theme tokens for the provider's subtree (upstream's `modify`).
* **Nested providers** are valid (upstream's EuiThemeProvider). By default a provider renders a `<span class="euiThemeProvider">` that sets the text color for its mode; pass `@wrapper={{false}}` where an extra element would break layout.
* **Block params:** the block yields `{ context, theme, Button }`.

**Not in Ember EUI:** `componentDefaults`, `utilityClasses`, `@emotion/cache` options (`stylisPlugins`, `container`, ...) and `setEuiDevProviderWarning`: there is no React-style component-defaults context or utility class injection, and the provider owns its Emotion cache. The theme helpers for building your own components are exported from `@ember-eui/core/theming`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiEmotionProvider

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@wrapper` | `boolean` | `true` | Wrap the content in a `<span class="euiThemeProvider">` that sets the resolved paragraph color, as upstream's nested EuiThemeProvider does, so inherited text follows this provider's mode. Pass `false` where an extra element would break layout (e.g. a provider directly inside a flex or grid container); attributes are forwarded to the span. |
| `@globalStyles` | `boolean` | `true` | Like upstream EuiProvider's `globalStyles`: the outermost provider injects EUI's global reset and root typography (root font size 14px in Borealis, which upstream `rem` sizes are relative to) while it is rendered, and removes them when torn down. Nested providers never do. Pass `false` on pages that still rely on legacy EUI CSS, or when the host app owns its global styles. |
| `@colorMode` | `EuiColorMode` |  | `"light"` or `"dark"`. Nested providers inherit their parent's. Like upstream EuiProvider, a root provider (no parent provider) left undefined follows the OS `prefers-color-scheme` (or the `eui-emotion` service's `colorMode` when set). An OS-forced high contrast (`forced-colors: active`) supersedes it. |
| `@borealisOverrides` | `EuiBorealisOverrides` |  |  |
| `@highContrastMode` | `EuiHighContrastModeArg` |  | Like upstream: `true` (or `"preferred"`) enables high contrast, `false` overrides the parent/system preference, `"forced"` forces it. Undefined inherits; a root provider then follows the OS (`prefers-contrast: more` → `"preferred"`, Windows `forced-colors: active` → `"forced"`, which supersedes every app setting, including `@colorMode`). |
| `@overrides` | `EuiThemeOverrides` |  |  |
| `@parent` | `EuiThemeContext` |  |  |
| `@cache` | `EuiEmotionCache` |  |  |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<span>`.

</EuiText>
<!-- api:end -->

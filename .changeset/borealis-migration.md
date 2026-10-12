---
"@ember-eui/core": minor
---

Style every component with current Elastic UI: EUI 123.1.0 with the Borealis 8.1.0 theme, instead of EUI 41.4's Amsterdam CSS. Components build their styles from upstream EUI's style factories and inject them with Emotion at runtime, so the theme stylesheet (`@ember-eui/core/themes/light.css` / `dark.css`) is no longer needed.

- Render one `EuiEmotionProvider` around the app. The outermost provider injects upstream's global styles (reset, 14px root font size, body colors, focus ring); `@colorMode` switches light/dark, `@borealisOverrides` takes Borealis token overrides and `@highContrastMode` sets contrast. `@globalStyles={{false}}` and `@wrapper={{false}}` opt out of the global styles and the `euiThemeProvider` span.
- Components take an `@css` argument, composed last into their own class (like upstream's `css` prop). Amsterdam modifier classes (`euiButton--primary`, `euiFlexGroup--gutterLarge`, …) are removed; stable root and element classes are kept.
- Some defaults follow upstream, e.g. `EuiPanel` has a border and no shadow, `EuiFlexGroup` gutter `m`, `EuiText` size `s`, `EuiLink` color `text` with `rel="noreferrer"`, form rows 400px wide, `EuiTablePagination` 10 rows per page, `EuiPopover` anchored `downLeft` without an arrow, `EuiModal` max width 768px, and `EuiForm` focuses its error callout.
- Icons are EUI 123.1.0's set (698 names); every previous name still resolves through legacy aliases. App icons registered in `euiIcon.icons` now win over EUI icons of the same name.
- `EuiNotificationEvent`, `EuiSuggest`, `EuiColorStops` and `EuiControlBar` were removed upstream: they keep working but are deprecated until 15.0.0 (`ember-eui.<file>.removed-upstream`).

See the "Migrating to Borealis" guide (`/docs/migrating-to-borealis`) for the upgrade steps and the full list of changed defaults.

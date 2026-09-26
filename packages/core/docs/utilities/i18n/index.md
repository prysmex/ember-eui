---
title: i18n
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="i18n"/>

<EuiSpacer @size='l' />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiI18n

Looks up a translated string in the `euiI18n` service (see the i18n docs
page) and yields a component rendering it.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@token` | `string` |  | Translation key, e.g. `'euiComboBox.noMatchesMessage'`. |
| `@default` | `string` |  | Text used when the token has no translation; may contain `{placeholders}`. |
| `@values` | `{ [key: string]: any }` |  | Values for the `{placeholders}` in the text. |
| `@i18n` |  |  | Translations for this instance, `{ mapping: { token: 'text' } }`, and an optional component to render the text with. |

Deprecated: `@tokens` (Has no effect, use one `EuiI18n` per token.); `@defaults` (Has no effect.).

| Block | Description |
| --- | --- |
| default block | Yields a component rendering the text: `as \|Text\|` → `<Text />`. |

</EuiText>
<!-- api:end -->

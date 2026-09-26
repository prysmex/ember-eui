<EuiSpacer/>
<EuiPageHeader @pageTitle="Link"/>
<EuiSpacer @size="l" />

<EuiText>

`EuiLink` is a text link. With `@href` it renders an `<a>`; without it, a
`<button>` styled as a link, for actions (add `{{on "click" …}}`).

```hbs
<EuiLink @href="/docs">Read the docs</EuiLink>
<EuiLink {{on "click" this.showDetails}}>Show details</EuiLink>
<EuiLink @href="https://elastic.co" @target="_blank">Elastic</EuiLink>
```

`@target="_blank"` adds an external link icon and a note for screen
readers that it opens a new tab. `@color` changes the color (`primary`,
`subdued`, `success`, `accent`, `danger`, `warning`, `ghost`, `text`).

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiLink

A text link: an `<a>` with `@href`, otherwise a `<button>` styled as a
link (add `{{on "click" …}}`).

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@color` | `string` | `'primary'` | `'primary'`, `'subdued'`, `'success'`, `'accent'`, `'danger'`, `'warning'`, `'ghost'` or `'text'`. |
| `@disabled` | `boolean` |  | Disables the link. |
| `@external` | `boolean` | `true` for `@target="_blank"` | Shows the external link icon. |
| `@href` | `string` |  | Where it links to; without it the link is a button. |
| `@target` | `string` |  | `target` of the link. `'_blank'` also adds the external icon and a screen reader note that it opens a new tab. |
| `@type` | `string` | `'button'` | `type` of the button (without `@href`). |

| Block | Description |
| --- | --- |
| default block | The link's text. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<a>` / `<button>`.

</EuiText>
<!-- api:end -->

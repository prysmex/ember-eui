---
title: Theming and dark mode
order: 102
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: theming and dark mode"/>
<EuiSpacer @size="l" />

<EuiText>

The sheet takes its colours from the EUI theme, so it follows light and
dark mode; each colour is a CSS custom property you can override.

## Theme

The sheet takes its colours (selection, focus, errors, the editor's input
and the checkbox) from the EUI theme, so it follows light and dark: put
it inside an `EuiEmotionProvider` with `@colorMode="dark"` (or set the
`eui-emotion` service's `colorMode`). The colours are CSS custom
properties set by a class on the sheet's wrapper (`--euiSheet-primary`,
`--euiSheet-selected`, `--euiSheet-hover`, `--euiSheet-plain`,
`--euiSheet-text`, `--euiSheet-textSubdued`, `--euiSheet-danger`,
`--euiSheet-textDanger`, `--euiSheet-dangerFilled`,
`--euiSheet-textInverse`, `--euiSheet-shadow`, `--euiSheet-subdued`,
`--euiSheet-border`, `--euiSheet-link` (link text and file names),
`--euiSheet-star` (a rating's stars), `--euiSheet-checked` (checked rows),
`--euiSheet-elevation` (the open editor's and the row menu's shadow),
`--euiSheet-textSuccess` (a success button's text), `--euiSheet-match`
(the current search match's ring, the theme's warning), the row colours
`--euiSheet-rowPrimary`, `-rowAccent`, `-rowSuccess`, `-rowWarning`,
`-rowDanger` and `-rowNeutral`, and `--euiSheet-highlight` for what is
coming). `--euiSheet-selected`, the
range tint, is the theme's primary at 12 % (20 % in dark). To change
one, set it on the sheet itself, which takes attributes
(`<EuiSheet style="--euiSheet-selected: #E6F0FF" …>`) or a more specific
selector; set on a parent element, it loses to the sheet's class. The
expanded record's flyout or modal, the row menu, the field editor and the
panel editors (`editorLayout: 'panel'`: the selects, linked records,
users, attachments, an app type's picker) are rendered at the end
of `<body>`, placed by their cell or header (below it, above it when there
is no room below in the window), so a card, panel or tab with
`overflow: hidden` around the sheet does not cut them off. They get the
class too, and the overrides set on the sheet's own `style` when they
open; CSS for an app's panel editor should not be scoped under
`.euiSheet`. An editor gets that class as `@themeClass`: one that renders a part of
itself outside the sheet (a wormholed list) adds it there; without it
that part uses the light colours.

## Related

- [Row and cell colours](/docs/sheet/docs/sheet/rows/colours)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>

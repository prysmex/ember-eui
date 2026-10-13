---
title: CSS utility classes
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="CSS utility classes"/>
<EuiSpacer @size="l" />

<EuiText>

Upstream's **EuiProvider** injects a set of CSS only utility classes (`eui-displayBlock`, `eui-alignTop`, `eui-fullWidth`, ...) for micro adjustments of components. **EuiEmotionProvider does not inject them** (there is no `utilityClasses` option), so in an app that uses only Ember EUI's Emotion styles those class names do nothing by themselves. Some components add a few of these class names to their own elements as hooks, but they style themselves.

Instead of the class names, use one of:

* `@css` on EUI components, with a style object or a theme function (see the Provider and Container queries pages).
* Your own stylesheet or the class helpers of your app. The utilities are one liners; these are upstream's declarations:

| Upstream class | Declarations |
| --- | --- |
| `eui-displayBlock` | `display: block !important` |
| `eui-displayInline` | `display: inline !important` |
| `eui-displayInlineBlock` | `display: inline-block !important` |
| `eui-fullWidth` | `display: block !important; width: 100% !important` |
| `eui-fullHeight` | `height: 100%; flex: 1 1 auto; overflow: hidden` |
| `eui-alignTop` | `vertical-align: top !important` |
| `eui-alignMiddle` | `vertical-align: middle !important` |
| `eui-alignBottom` | `vertical-align: bottom !important` |
| `eui-alignBaseline` | `vertical-align: baseline !important` |

`euiFullHeight()` is exported by `@ember-eui/core/theming`. The package also ships the legacy theme stylesheets (`@ember-eui/core/themes/light.css` and `dark.css`), which define the class names above together with the older scroll, text and responsive utilities. They are complete legacy themes, so loading one only for the utilities is not recommended.

For scrolling see the Scroll page. For text truncation see the `EuiTextTruncate` component.

</EuiText>

<EuiSpacer />

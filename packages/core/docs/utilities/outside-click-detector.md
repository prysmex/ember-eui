---
title: Outside click detector
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Outside click detector"/>
<EuiSpacer @size="l" />

<EuiText>

The `outside-click-detector` modifier calls `onOutsideClick` when the
user clicks anywhere outside the element, e.g. to close a custom menu.
`isDisabled` pauses it.

```hbs
<div {{outside-click-detector onOutsideClick=this.close isDisabled=(not this.isOpen)}}>…</div>
```

In `.gjs`/`.gts`: `import { outsideClickDetector } from '@ember-eui/core/modifiers';`.
Popovers, modals and flyouts already handle outside clicks.

</EuiText>

<EuiHorizontalRule />


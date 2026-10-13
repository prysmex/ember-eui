---
title: Outside click detector
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Outside click detector"/>
<EuiSpacer @size="l" />

<EuiText>

Use the `outside-click-detector` modifier (upstream's **EuiOutsideClickDetector** component) to trigger a handler when the user clicks outside of the element. It calls `onOutsideClick` when the
user clicks anywhere outside the element, e.g. to close a custom menu.
`isDisabled` pauses it.

```hbs
<div {{outside-click-detector onOutsideClick=this.close isDisabled=(not this.isOpen)}}>…</div>
```

In `.gjs`/`.gts`: `import { outsideClickDetector } from '@ember-eui/core/modifiers';`.
Popovers, modals and flyouts already handle outside clicks.

</EuiText>

<EuiHorizontalRule />


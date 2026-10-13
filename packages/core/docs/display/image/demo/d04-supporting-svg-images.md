---
order: 4
---

# Supporting SVG images

<EuiText>

If you are using an SVG source within **EuiImage**, the SVG image may not show up! While this is surprising to the user, if your image doesn't have a width or viewbox set, it is behaving in accordance with the SVG spec.

In order to work with an SVG image that lacks a defined size, you'll want to set a `@size` argument. If you are using the `@allowFullScreen` argument as well, you will also want to add a `@width` argument.

</EuiText>

```gjs component
import { EuiImage } from '@ember-eui/core/components';

<template>
<EuiImage
  @size="l"
  @width={{600}}
  @hasShadow={{true}}
  @caption="Diagram of fishapod timelines"
  @alt="Diagram of fishapod timelines"
  @src="https://upload.wikimedia.org/wikipedia/commons/a/af/Fishapods.svg"
  @allowFullScreen={{true}}
/>
</template>
```

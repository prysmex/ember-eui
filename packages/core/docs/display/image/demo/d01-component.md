---
order: 1
---

# Component

<EuiText>

Pass a plain `@caption`, or use the `<:caption>` block for rich content, as in this example. The figure's accessible name is the caption's text.

</EuiText>

```gjs component
import { EuiImage } from '@ember-eui/core/components';

<template>
<EuiImage
  @size="l"
  @hasShadow={{true}}
  @alt="Many small white-spotted pink jellyfish floating in a dark aquarium"
  @src="https://images.unsplash.com/photo-1650253618249-fb0d32d3865c?w=900&h=900&fit=crop&q=60"
>
  <:caption>
    <p><em>Mastigias papua</em>, also known as spotted jelly</p>
  </:caption>
</EuiImage>
</template>
```

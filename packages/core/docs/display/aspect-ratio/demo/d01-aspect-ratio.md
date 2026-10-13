---
order: 1
---

# Component

<EuiText>

`EuiAspectRatio` responsively resizes a single block level child element to a specified ratio.

</EuiText>

```gjs component
import { EuiAspectRatio, EuiSpacer, EuiTitle } from '@ember-eui/core/components';

<template>
<EuiTitle @size="s"><p>16x9 aspect</p></EuiTitle>
<EuiSpacer @size="s" />
<EuiAspectRatio @width={{16}} @height={{9}}>
  <iframe
    title="Elastic is a search company"
    width="560"
    height="315"
    src="https://www.youtube.com/embed/yJarWSLRM24"
    frameborder="0"
    allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
    allowfullscreen
  ></iframe>
</EuiAspectRatio>
<EuiSpacer @size="xl" />
<EuiTitle @size="s"><p>4x3 aspect</p></EuiTitle>
<EuiSpacer @size="s" />
<EuiAspectRatio @width={{4}} @height={{3}}>
  <iframe
    title="Elastic is a search company"
    width="560"
    height="315"
    src="https://www.youtube.com/embed/yJarWSLRM24"
    frameborder="0"
    allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture"
    allowfullscreen
  ></iframe>
</EuiAspectRatio>
<EuiSpacer @size="xl" />
<EuiTitle @size="s"><p>220x150 with a maxWidth set to 500</p></EuiTitle>
<EuiSpacer @size="s" />
<EuiAspectRatio @width={{220}} @height={{150}} @maxWidth={{500}}>
  <iframe
    src="https://app.stitcher.com/splayer/f/13377/54057816"
    title="something"
    frameborder="0"
    scrolling="no"
  ></iframe>
</EuiAspectRatio>
</template>
```

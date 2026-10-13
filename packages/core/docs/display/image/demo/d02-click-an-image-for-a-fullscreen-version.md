---
order: 2
---

# Click an image for a fullscreen version

 <EuiText>
    <p>Apply the <EuiCode @language="text">@allowFullScreen</EuiCode> argument to make the image clickable and show a fullscreen version. Note that the second image also passes <EuiCode @language="text">@fullScreenIconColor="dark"</EuiCode> to change icon color to better contrast against the light background of that image.</p>
    </EuiText>

```gjs component
import { EuiFlexGroup, EuiFlexItem, EuiImage, EuiLink } from '@ember-eui/core/components';

<template>
<EuiFlexGroup @justifyContent="spaceEvenly">
  <EuiFlexItem @grow={{false}}>
    {{! Because this image is sufficiently described by its caption, there is no need to repeat it via alt text }}
    <EuiImage
      @size="m"
      @hasShadow={{true}}
      @allowFullScreen={{true}}
      @caption="Albert Einstein, theoretical physicist"
      @alt=""
      @src="https://upload.wikimedia.org/wikipedia/commons/d/d3/Albert_Einstein_Head.jpg"
    />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiImage
      @allowFullScreen={{true}}
      @alt="Pie chart describing browser usage on Wikimedia on October 2011. Internet Explorer occupies 34 percent, Firefox occupies 23 percent, Chrome occupies 20 percent, Safari occupies 11 percent, Opera occupies 5%, Android occupies 1.9 percent, and other browsers occupy 3.5 percent."
      @src="https://upload.wikimedia.org/wikipedia/commons/a/a2/Wikimedia_browser_share_pie_chart.png"
      @fullScreenIconColor="dark"
      @size={{300}}
      style="padding: 20px 30px; background: white;"
    >
      <:caption>
        Browser usage on
        <EuiLink
          @href="https://commons.wikimedia.org/wiki/File:Wikimedia_browser_share_pie_chart.png"
          @target="_blank"
        >Wikimedia (CC BY 3.0)</EuiLink>
      </:caption>
    </EuiImage>
  </EuiFlexItem>
</EuiFlexGroup>
</template>
```

---
order: 3
---

# Images can be sized

<EuiText>
    <p>Images can be sized by passing the <EuiCode @language="text">@size</EuiCode> argument a value of <EuiCode @language="text">s / m / l / xl / original / fullWidth / number / string</EuiCode>. This size sets the <strong>maximum</strong> length of the longest edge of the image, whether that is height or width, and scales it. Only the provided sizing values will also increase the size of a smaller image.</p>
    </EuiText>

```gjs component
import Component from '@glimmer/component';
import { EuiImage, EuiSpacer } from '@ember-eui/core/components';

export default class ImageSizesDemo extends Component {
  src =
    'https://images.unsplash.com/photo-1477747219299-60f95c811fef?w=1000&h=1000&fit=crop&q=60';
  alt =
    'A cozy breakfast scene. In the background is a plate of waffles and blueberries. In the middle ground is a glass of orange juice and a small cup of cream. In the foreground is a plate of Eggs Benedict with a side of salad and cherry tomatoes.';

  <template>
    <div>
      <EuiImage
        class="eui-textLeft"
        @size={{50}}
        @hasShadow={{true}}
        @allowFullScreen={{true}}
        @caption="Custom size (50)"
        @alt={{this.alt}}
        @src={{this.src}}
      />
      <EuiSpacer />
      <EuiImage
        @size="s"
        @hasShadow={{true}}
        @allowFullScreen={{true}}
        @caption="Small"
        @alt={{this.alt}}
        @src={{this.src}}
      />
      <EuiSpacer />
      <EuiImage
        @size="m"
        @hasShadow={{true}}
        @allowFullScreen={{true}}
        @caption="Medium"
        @alt={{this.alt}}
        @src={{this.src}}
      />
      <EuiSpacer />
      <EuiImage
        @size="l"
        @hasShadow={{true}}
        @allowFullScreen={{true}}
        @caption="Large"
        @alt={{this.alt}}
        @src={{this.src}}
      />
      <EuiSpacer />
      <EuiImage
        @size="xl"
        @hasShadow={{true}}
        @allowFullScreen={{true}}
        @caption="Extra large"
        @alt={{this.alt}}
        @src={{this.src}}
      />
      <EuiSpacer />
      <EuiImage
        @hasShadow={{true}}
        @allowFullScreen={{true}}
        @caption="Original"
        @alt={{this.alt}}
        @src={{this.src}}
      />
      <EuiSpacer />
      <EuiImage
        @size="fullWidth"
        @hasShadow={{true}}
        @allowFullScreen={{true}}
        @caption="Full width"
        @alt={{this.alt}}
        @src={{this.src}}
      />
    </div>
  </template>
}
```


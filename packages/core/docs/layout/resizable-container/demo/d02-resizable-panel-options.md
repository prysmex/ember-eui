---
order: 2
---

# Resizable panel options

<EuiText>
  <p>
    Each <strong>Panel</strong> is simply an <strong>EuiPanel</strong> wrapped with a <EuiCode>&lt;div&gt;</EuiCode> for controlling the width. It stretches to fill its container and accepts all of the same <strong>EuiPanel</strong> args to style your panel.
  </p>
  <p>
    The default args clear most of the <strong>EuiPanel</strong> styles, but you can add them back in with <EuiCode>@color</EuiCode>, <EuiCode>@hasShadow</EuiCode>, and <EuiCode>@paddingSize</EuiCode>.
  </p>
</EuiText>

```gjs component
import { EuiCode, EuiPanel, EuiResizableContainer, EuiText } from '@ember-eui/core/components';

<template>
  <EuiResizableContainer style='height: 200px;' as |c|>
    <c.Panel @initialSize={{20}} @color='subdued'>
      <EuiText @size='s'>
        <p>
          This <strong>Panel</strong> changes the background with <EuiCode>@color="subdued"</EuiCode>.
        </p>
      </EuiText>
    </c.Panel>
    <c.Button @accountForScrollbars='before' />
    <c.Panel
      @initialSize={{40}}
      @color='plain'
      @hasShadow={{true}}
      @borderRadius='m'
      @wrapperPadding='m'
      @minSize='20%'
      tabindex='0'
    >
      <EuiText @size='s'>
        <p>
          This <strong>Panel</strong> resets most of the <strong>EuiPanel</strong> args back to default with <EuiCode>@color="plain" @hasShadow=&#123;&#123;true&#125;&#125; @borderRadius="m"</EuiCode>.
        </p>
        <p>
          It also adds padding to the wrapping div with <EuiCode>@wrapperPadding="m"</EuiCode> to maintain the scroll <strong>inside</strong> the panel.
        </p>
      </EuiText>
    </c.Panel>
    <c.Button />
    <c.Panel @initialSize={{40}} @color='subdued'>
      <EuiPanel>
        <EuiText @size='s'>
          <p>
            This <strong>Panel</strong> also changes the background color but adds an internal <strong>EuiPanel</strong> that will not stretch and will scroll within the <strong>Panel</strong>.
          </p>
        </EuiText>
      </EuiPanel>
    </c.Panel>
  </EuiResizableContainer>
</template>
```

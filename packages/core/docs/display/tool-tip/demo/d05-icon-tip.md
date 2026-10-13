---
order: 5
---

# Icon tip

<EuiText>

You can use `EuiIconTip` to explain options, other controls, or entire parts of the user interface. When possible, surface explanations inline within the UI, and only hide them behind an `EuiIconTip` as a last resort.

It accepts all the same arguments as `EuiToolTip`. For convenience, you can also specify optional icon `@size`, `@type`, and `@color` arguments.

</EuiText>

```gjs component
import { EuiCheckbox, EuiCode, EuiFlexGroup, EuiFlexItem, EuiIconTip, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { hash } from '@ember/helper';

<template>
<EuiFlexGroup @alignItems='center' @gutterSize='s' @responsive={{false}}>
  <EuiFlexItem @grow={{false}}>
    <EuiCheckbox @id='explainedCheckbox' @label='Use source maps' />
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiIconTip
      @content='Source maps allow browser dev tools to map minified code to the original source code'
      @position='right'
    />
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer />

<EuiIconTip
  @ariaLabel='Warning'
  @size='xl'
  @type='warning'
  @color='warning'
  @content='I do not think it means what you think it means'
/>

<EuiSpacer />

<EuiText>
  <p>
    Pass a position utility class via <EuiCode>@iconProps</EuiCode> to
    shift for better alignment.
    <EuiIconTip
      @type='info'
      @color='subdued'
      @iconProps={{hash className='eui-alignTop'}}
    >
      <:content>
        <span>
          This was passed <EuiCode>.eui-alignTop</EuiCode>
        </span>
      </:content>
    </EuiIconTip>
  </p>
</EuiText>
</template>
```

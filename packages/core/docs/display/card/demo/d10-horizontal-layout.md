---
order: 10
---

# Horizontal layout

<EuiText>

Ember EUI extra: `@layout="horizontal"` puts the icon next to the text. Pair it with a larger `@iconSize` or a smaller `@titleSize`.

</EuiText>

```gjs component
import { EuiCard, EuiFlexGroup, EuiFlexItem } from '@ember-eui/core/components';

<template>
<EuiFlexGroup @gutterSize='l'>

  <EuiFlexItem>
    <EuiCard
      @layout='horizontal'
      @icon='logoBeats'
      @title='logoBeats'
      @iconSize='xl'
      @description="This card adds uses an 'xl' size icon which works well in a horizontal layout."
    />
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard
      @layout='horizontal'
      @icon='logoCloud'
      @iconSize='l'
      @titleSize='xs'
      @title='Elastic Cloud'
      @description="This card uses an 'l' size icon but also shrinks the 'titleSize' to 'xs'."
    />
  </EuiFlexItem>

  <EuiFlexItem>
    <EuiCard
      @layout='horizontal'
      @title='No icon example'
      @description="Example of a card's description. Stick to one or two sentences."
      @href='#'
    />
  </EuiFlexItem>

</EuiFlexGroup>
</template>
```

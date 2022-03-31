---
order: 3
---

# Displacement

<EuiText>
  <p>
  There is an <EuiCode>affordForDisplacement</EuiCode> prop (defaulting to <EuiCode>true</EuiCode>), which determines
  whether the component makes room for itself by adding bottom padding
  equivalent to its own height on the document <EuiCode @language="html">body</EuiCode> element. Setting this to
  <EuiCode>false</EuiCode> can be useful to minimize scrollbar visibility but will cause the bottom
  bar to overlap body content.
  </p>
  <p>
     You can
    also apply a different set of positioning locations just by adjusting them
    in with the <EuiCode>top | right | bottom | left</EuiCode> props.
  </p>
</EuiText>

```hbs template
<EuiButton
  @color='primary'
  {{on
    'click'
    (queue
      (set this 'affordForDisplacement' true)
      (set this 'displacedBottomBarActive' true)
    )
  }}
>
  Show bottom bar
</EuiButton>
<EuiButton
  @color='primary'
  {{on
    'click'
    (queue
      (set this 'affordForDisplacement' false)
      (set this 'displacedBottomBarActive' true)
    )
  }}
>
  Show bottom bar (without affordForDisplacement behavior)
</EuiButton>
{{#if this.displacedBottomBarActive}}
  <EuiBottomBar @affordForDisplacement={{this.affordForDisplacement}}>
    <EuiFlexGroup @justifyContent='flexEnd'>
      <EuiFlexItem @grow={{false}}>
        <EuiButtonEmpty
          @color='ghost'
          @size='s'
          @iconType='cross'
          {{on 'click' (set this 'displacedBottomBarActive' false)}}
        >
          close
        </EuiButtonEmpty>
      </EuiFlexItem>
    </EuiFlexGroup>
  </EuiBottomBar>
{{/if}}
<EuiSpacer />
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

export default class BottomBarDemo1Component extends Component {
  @tracked basicBottomBarActive = false;
  @tracked displacedBottomBarActive = false;
  @tracked affordForDisplacement = true;
}
```

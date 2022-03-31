---
order: 2
---

# Positions

<EuiText>
  <p>
  Bottom bars default to a fixed position, in a portal at the bottom of the
    browser window. Alternatively, you can change the <EuiCode>position</EuiCode> to <EuiCode>sticky</EuiCode> where
    it will render in place but stick to the window only as the window edge
    nears. The <EuiCode>static</EuiCode> position reverts back to default DOM behavior.
  </p>
  <p>
     You can
    also apply a different set of positioning locations just by adjusting them
    in with the <EuiCode>top | right | bottom | left</EuiCode> props.
  </p>
</EuiText>

```hbs template
<div>
  <EuiText>
    <p>
      When scrolling past this example block, the
      <strong>EuiBottomBar</strong>
      will stick to the bottom of the browser window (with a 10px offset), but
      keeps it within the bounds of its parent.
    </p>
  </EuiText>
  <EuiSpacer @size='xl' />
  <EuiSpacer @size='xl' />
  <EuiBottomBar
    @landmarkHeading='Page level controls'
    @position='sticky'
    @bottom={{10}}
  >
    <EuiText color='ghost' textAlign='center'>
      <p>Scroll to see!</p>
    </EuiText>
  </EuiBottomBar>
</div>
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

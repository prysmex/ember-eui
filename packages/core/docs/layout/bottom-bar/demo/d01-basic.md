---
order: 1
---

# Basic bottom bar

<EuiText>

Toggle the bar to see it fixed at the bottom of the window.

</EuiText>

```hbs template
<EuiButton
  @color='primary'
  {{on
    'click'
    (set this 'basicBottomBarActive' (not this.basicBottomBarActive))
  }}
>
  Toggle appearance of the bottom bar
</EuiButton>

{{#if this.basicBottomBarActive}}
  <EuiBottomBar>
    <EuiFlexGroup @justifyContent='spaceBetween'>
      <EuiFlexItem @grow={{false}}>
        <EuiFlexGroup @gutterSize='s'>
          <EuiFlexItem @grow={{false}}>
            <EuiButton @color='ghost' @size='s' @iconType='help'>
              Help
            </EuiButton>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButton @color='ghost' @size='s' @iconType='user'>
              Add user
            </EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiFlexGroup @gutterSize='s'>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @color='ghost' @size='s' @iconType='cross'>
              Discard
            </EuiButtonEmpty>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButton
              @color='primary'
              @fill={{true}}
              @size='s'
              @iconType='check'
            >
              Save
            </EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiFlexItem>
    </EuiFlexGroup>
  </EuiBottomBar>
{{/if}}
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

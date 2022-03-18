```hbs template
<EuiText>
  <b>EuiBottomBar</b>
  is a simple wrapper component that does nothing but fix a bottom bar (usually
  filled with buttons) to the bottom of the page. Use it when you have really
  long pages or complicated, multi-page forms. In the case of forms, only invoke
  it if a form is in a savable state.
</EuiText>
<EuiSpacer />

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
<EuiSpacer />
<div>
  <EuiTitle>
    Positions
  </EuiTitle>
  <EuiSpacer />
  <EuiText>
    Bottom bars default to a fixed position, in a portal at the bottom of the
    browser window. Alternatively, you can change the position to sticky where
    it will render in place but stick to the window only as the window edge
    nears. The static position reverts back to default DOM behavior. You can
    also apply a different set of positioning locations just by adjusting them
    in with the top | right | bottom | left props.
  </EuiText>
  <EuiSpacer />
  <EuiBottomBar
  @landmarkHeading='Page level controls'
  @position='sticky' @bottom={{10}}>
    <EuiText color='ghost' textAlign='center'>
      <p>Scroll to see!</p>
    </EuiText>
  </EuiBottomBar>
</div>
<EuiSpacer />

<EuiTitle>
  Displacement
</EuiTitle>
<EuiSpacer />
<EuiText>
  There is an affordForDisplacement prop (defaulting to true), which determines
  whether the component makes room for itself by adding bottom padding
  equivalent to its own height on the document body element. Setting this to
  false can be useful to minimize scrollbar visibility but will cause the bottom
  bar to overlap body content.
</EuiText>
<EuiSpacer />
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

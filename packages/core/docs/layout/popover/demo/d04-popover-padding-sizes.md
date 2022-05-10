---
order: 4
---

# Popover padding sizes

<EuiText>
    Use the
    <EuiCode>panelPaddingSize</EuiCode>
    prop to adjust the padding of the panel content. When using popover titles
    and footers, this setting will propogate to them. Or you can supply a custom
    <EuiCode>paddingSize</EuiCode>
    to either the
    <strong>EuiPopoverTitle</strong>
    of
    <strong>EuiPopoverFooter</strong>.
</EuiText>

```hbs template
<div>
  <EuiFlexGroup>

    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop1}}
        @panelPaddingSize='s'
        @closePopover={{set this 'pop1' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop1' true)}}
          >
            Small panel padding
          </EuiButton>
        </:button>
        <:content>
          <EuiPopoverTitle>
            Hello, I’m a popover title
          </EuiPopoverTitle>
          <div style='width: 300px;'>
            <EuiText @size='s'>
              Only changing the panelPaddingSize will get inherited by the
              title.
            </EuiText>
          </div>
          <EuiPopoverFooter>
            <EuiButton
              @size='s'
              @fullWidth={{true}}
            >
              Footer button
            </EuiButton>
          </EuiPopoverFooter>
        </:content>
      </EuiPopover>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop2}}
        @panelPaddingSize='none'
        @closePopover={{set this 'pop2' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop2' true)}}
          >
            No panel padding (none)
          </EuiButton>
        </:button>
        <:content>
          <EuiPopoverTitle>
            Hello, I’m a popover title
          </EuiPopoverTitle>
          <div style='width: 300px;'>
            <EuiText @size='s'>
              Removing the panelPaddingSize completely is good for lists that
              should extend to the edges.
            </EuiText>
          </div>
          <EuiPopoverFooter>
            <EuiButton
              @size='s'
              @fullWidth={{true}}
            >
              Footer button
            </EuiButton>
          </EuiPopoverFooter>
        </:content>
      </EuiPopover>
    </EuiFlexItem>

  </EuiFlexGroup>


  <EuiFlexGroup>

    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop3}}
        @closePopover={{set this 'pop3' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop3' true)}}
          >
            No title padding (none)
          </EuiButton>
        </:button>
        <:content>
          <EuiPopoverTitle @paddingSize='none'>
            Hello, I’m a popover title
          </EuiPopoverTitle>
          <div style='width: 300px;'>
            <EuiText @size='s'>
              Removing the padding from titles only with paddingSize on
              EuiPopoverTitle.
            </EuiText>
          </div>
          <EuiPopoverFooter>
            <EuiButton
              @size='s'
              @fullWidth={{true}}
            >
              Footer button
            </EuiButton>
          </EuiPopoverFooter>
        </:content>
      </EuiPopover>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop4}}
        @panelPaddingSize='none'
        @closePopover={{set this 'pop4' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop4' true)}}
          >
            No panel padding with small title padding
          </EuiButton>
        </:button>
        <:content>
          <EuiPopoverTitle @paddingSize='s'>
            Hello, I’m a popover title
          </EuiPopoverTitle>
          <div style='width: 300px;'>
            <EuiText @size='s'>
              You can adjust both the panelPaddingSize and the paddingSize at
              the same time
            </EuiText>
          </div>
          <EuiPopoverFooter>
            <EuiButton
              @size='s'
              @fullWidth={{true}}
            >
              Footer button
            </EuiButton>
          </EuiPopoverFooter>
        </:content>
      </EuiPopover>
    </EuiFlexItem>

  </EuiFlexGroup>


  <EuiFlexGroup>

    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop5}}
        @panelPaddingSize='m'
        @closePopover={{set this 'pop5' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop5' true)}}
          >
            No footer padding (none)
          </EuiButton>
        </:button>
        <:content>
          <EuiPopoverTitle>
            Hello, I’m a popover title
          </EuiPopoverTitle>
          <div style='width: 300px;'>
            <EuiText @size='s'>
              Removing the padding from titles only with paddingSize on
              EuiPopoverTitle.
            </EuiText>
          </div>
          <EuiPopoverFooter @paddingSize='none'>
            <EuiButton
              @size='s'
              @fullWidth={{true}}
            >
              Footer button
            </EuiButton>
          </EuiPopoverFooter>
        </:content>
      </EuiPopover>
    </EuiFlexItem>

    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop6}}
        @panelPaddingSize='none'
        @closePopover={{set this 'pop6' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop6' true)}}
          >
            Set each padding individually
          </EuiButton>
        </:button>
        <:content>
          <EuiPopoverTitle @paddingSize='s'>
            Hello, I’m a popover title
          </EuiPopoverTitle>
          <div style='width: 300px;'>
            <EuiText @size='s'>
              For the most reliable padding display, set the panelPaddingSize and the paddingSize props for each component individually.
            </EuiText>
          </div>
          <EuiPopoverFooter @paddingSize='s'>
            <EuiButton
              @size='s'
              @fullWidth={{true}}
            >
              Footer button
            </EuiButton>
          </EuiPopoverFooter>
        </:content>
      </EuiPopover>
    </EuiFlexItem>

  </EuiFlexGroup>

</div>
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo1 extends Component {
  @tracked pop1 = false;
  @tracked pop2 = false;
  @tracked pop3 = false;
  @tracked pop4 = false;
  @tracked pop5 = false;
  @tracked pop6 = false;
}
```

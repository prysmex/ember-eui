---
order: 4
---

# Popover padding sizes

<EuiText>
  <p>
    Use the <EuiCode>@panelPaddingSize</EuiCode> argument to adjust the padding of the panel content. When using popover titles and footers, this setting will propagate to them. Or you can supply a custom <EuiCode>@paddingSize</EuiCode> to either the <strong>EuiPopoverTitle</strong> or <strong>EuiPopoverFooter</strong>.
  </p>
</EuiText>

```hbs template
<EuiFlexGroup @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen1}}
      @closePopover={{fn this.close 'isPopoverOpen1'}}
      @panelPaddingSize='s'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen1')}}
        >
          Small panel padding
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiPopoverTitle>Hello, I&rsquo;m a popover title</EuiPopoverTitle>
        <EuiText @size='s' style='width: 300px;'>
          <p>
            Only changing the <EuiCode>@panelPaddingSize</EuiCode> will get inherited by the title.
          </p>
        </EuiText>
        <EuiPopoverFooter>
          <EuiButton @fullWidth={{true}} @size='s'>
            Footer button
          </EuiButton>
        </EuiPopoverFooter>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen2}}
      @closePopover={{fn this.close 'isPopoverOpen2'}}
      @panelPaddingSize='none'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen2')}}
        >
          No panel padding (none)
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiPopoverTitle>Hello, I&rsquo;m a popover title</EuiPopoverTitle>
        <EuiText @size='s' style='width: 300px;'>
          <p>
            Removing the <EuiCode>@panelPaddingSize</EuiCode> completely is good for lists that should extend to the edges.
          </p>
        </EuiText>
        <EuiPopoverFooter>
          <EuiButton @fullWidth={{true}} @size='s'>
            Footer button
          </EuiButton>
        </EuiPopoverFooter>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiFlexGroup @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen3}}
      @closePopover={{fn this.close 'isPopoverOpen3'}}
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen3')}}
        >
          No title padding (none)
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiPopoverTitle @paddingSize="none">Hello, I&rsquo;m a popover title</EuiPopoverTitle>
        <EuiText @size='s' style='width: 300px;'>
          <p>
            Removing the padding from titles only with <EuiCode>@paddingSize</EuiCode> on <strong>EuiPopoverTitle</strong>.
          </p>
        </EuiText>
        <EuiPopoverFooter>
          <EuiButton @fullWidth={{true}} @size='s'>
            Footer button
          </EuiButton>
        </EuiPopoverFooter>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen4}}
      @closePopover={{fn this.close 'isPopoverOpen4'}}
      @panelPaddingSize='none'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen4')}}
        >
          No panel padding with small title padding
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiPopoverTitle @paddingSize="s">Hello, I&rsquo;m a popover title</EuiPopoverTitle>
        <EuiText @size='s' style='width: 300px;'>
          <p>
            You can adjust both the <EuiCode>@panelPaddingSize</EuiCode> and the <EuiCode>@paddingSize</EuiCode> at the same time.
          </p>
        </EuiText>
        <EuiPopoverFooter>
          <EuiButton @fullWidth={{true}} @size='s'>
            Footer button
          </EuiButton>
        </EuiPopoverFooter>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiFlexGroup @wrap={{true}}>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen5}}
      @closePopover={{fn this.close 'isPopoverOpen5'}}
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen5')}}
        >
          No footer padding (none)
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiPopoverTitle>Hello, I&rsquo;m a popover title</EuiPopoverTitle>
        <EuiText @size='s' style='width: 300px;'>
          <p>
            Removing the padding from footers only with <EuiCode>@paddingSize</EuiCode> on <strong>EuiPopoverFooter</strong>.
          </p>
        </EuiText>
        <EuiPopoverFooter @paddingSize="none">
          <EuiButton @fullWidth={{true}} @size='s'>
            Footer button
          </EuiButton>
        </EuiPopoverFooter>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen6}}
      @closePopover={{fn this.close 'isPopoverOpen6'}}
      @panelPaddingSize='none'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen6')}}
        >
          Set each padding individually
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiPopoverTitle @paddingSize="s">Hello, I&rsquo;m a popover title</EuiPopoverTitle>
        <EuiText @size='s' style='width: 300px;'>
          <p>
            For the most reliable padding display, set the <EuiCode>@panelPaddingSize</EuiCode> and the <EuiCode>@paddingSize</EuiCode> args for each component individually.
          </p>
        </EuiText>
        <EuiPopoverFooter @paddingSize="s">
          <EuiButton @fullWidth={{true}} @size='s'>
            Footer button
          </EuiButton>
        </EuiPopoverFooter>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
</EuiFlexGroup>
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class PopoverDemo extends Component {
  @tracked isPopoverOpen1 = false;
  @tracked isPopoverOpen2 = false;
  @tracked isPopoverOpen3 = false;
  @tracked isPopoverOpen4 = false;
  @tracked isPopoverOpen5 = false;
  @tracked isPopoverOpen6 = false;
  @action
  toggle(name) {
    this[name] = !this[name];
  }

  @action
  close(name) {
    this[name] = false;
  }
}
```

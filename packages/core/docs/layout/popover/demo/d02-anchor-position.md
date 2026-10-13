---
order: 2
---

# Anchor position

<EuiText>
  <p>
    The alignment and arrow on your popover can be set with the <EuiCode>@anchorPosition</EuiCode> argument. These positions will update based upon screen real estate.
  </p>
  <p><strong>Some tips:</strong></p>
  <ul>
    <li>The first word in the <EuiCode>@anchorPosition</EuiCode> denotes where the popover will appear relative to the button.</li>
    <li>The second word in the <EuiCode>@anchorPosition</EuiCode> denotes where the gravity / pin position will appear relative to the popover.</li>
  </ul>
</EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen1}}
      @closePopover={{fn this.close 'isPopoverOpen1'}}
      @anchorPosition='downLeft'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen1')}}
        >
          downLeft
        </EuiButtonEmpty>
      </:button>
      <:content>
        Popover content
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen2}}
      @closePopover={{fn this.close 'isPopoverOpen2'}}
      @anchorPosition='downCenter'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen2')}}
        >
          downCenter
        </EuiButtonEmpty>
      </:button>
      <:content>
        Popover content
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen3}}
      @closePopover={{fn this.close 'isPopoverOpen3'}}
      @anchorPosition='downRight'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen3')}}
        >
          downRight
        </EuiButtonEmpty>
      </:button>
      <:content>
        Popover content
      </:content>
    </EuiPopover>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size='l' />

<EuiFlexGroup>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen4}}
      @closePopover={{fn this.close 'isPopoverOpen4'}}
      @anchorPosition='upLeft'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen4')}}
        >
          upLeft
        </EuiButtonEmpty>
      </:button>
      <:content>
        Popover content
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen5}}
      @closePopover={{fn this.close 'isPopoverOpen5'}}
      @anchorPosition='upCenter'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen5')}}
        >
          upCenter
        </EuiButtonEmpty>
      </:button>
      <:content>
        Popover content
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen6}}
      @closePopover={{fn this.close 'isPopoverOpen6'}}
      @anchorPosition='upRight'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen6')}}
        >
          upRight
        </EuiButtonEmpty>
      </:button>
      <:content>
        Popover content
      </:content>
    </EuiPopover>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size='l' />

<EuiFlexGroup>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen7}}
      @closePopover={{fn this.close 'isPopoverOpen7'}}
      @anchorPosition='leftUp'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen7')}}
        >
          leftUp
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiText>
          <p style='width: 200px;'>
            For left- or right-aligned popovers, make sure there is sufficient content. If the popover height is too short, the arrow positioning will appear off.
          </p>
        </EuiText>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen8}}
      @closePopover={{fn this.close 'isPopoverOpen8'}}
      @anchorPosition='leftCenter'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen8')}}
        >
          leftCenter
        </EuiButtonEmpty>
      </:button>
      <:content>
        Popover content
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen9}}
      @closePopover={{fn this.close 'isPopoverOpen9'}}
      @anchorPosition='leftDown'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen9')}}
        >
          leftDown
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiText>
          <p style='width: 200px;'>
            For left- or right-aligned popovers, make sure there is sufficient content. If the popover height is too short, the arrow positioning will appear off.
          </p>
        </EuiText>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer @size='l' />

<EuiFlexGroup>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen10}}
      @closePopover={{fn this.close 'isPopoverOpen10'}}
      @anchorPosition='rightUp'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen10')}}
        >
          rightUp
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiText>
          <p style='width: 200px;'>
            For left- or right-aligned popovers, make sure there is sufficient content. If the popover height is too short, the arrow positioning will appear off.
          </p>
        </EuiText>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen11}}
      @closePopover={{fn this.close 'isPopoverOpen11'}}
      @anchorPosition='rightCenter'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen11')}}
        >
          rightCenter
        </EuiButtonEmpty>
      </:button>
      <:content>
        Popover content
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @isOpen={{this.isPopoverOpen12}}
      @closePopover={{fn this.close 'isPopoverOpen12'}}
      @anchorPosition='rightDown'
    >
      <:button>
        <EuiButtonEmpty
          @iconType='question'
          @iconSide='right'
          {{on 'click' (fn this.toggle 'isPopoverOpen12')}}
        >
          rightDown
        </EuiButtonEmpty>
      </:button>
      <:content>
        <EuiText>
          <p style='width: 200px;'>
            For left- or right-aligned popovers, make sure there is sufficient content. If the popover height is too short, the arrow positioning will appear off.
          </p>
        </EuiText>
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
  @tracked isPopoverOpen7 = false;
  @tracked isPopoverOpen8 = false;
  @tracked isPopoverOpen9 = false;
  @tracked isPopoverOpen10 = false;
  @tracked isPopoverOpen11 = false;
  @tracked isPopoverOpen12 = false;
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

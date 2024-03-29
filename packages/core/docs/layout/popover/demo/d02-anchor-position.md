---
order: 2
---

# Anchor position

<EuiText>
    The alignment and arrow on your popover can be set with the
    <EuiCode>anchorPosition</EuiCode>
    prop. These positions will update based upon screen real estate.<br /><br />
    <strong>Some tips:</strong>
    <ul>
      <li>The first word in the <EuiCode>anchorPosition</EuiCode> denotes where the popover will
        appear relative to the button.</li>
      <li>The second word in the <EuiCode>anchorPosition</EuiCode> denotes where the gravity / pin
        position will appear relative to the popover.</li>
    </ul>
  </EuiText>
  
```hbs template
<div>
  
  <EuiFlexGroup>
    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop1}}
        @anchorPosition='downLeft'
        @closePopover={{set this 'pop1' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop1' true)}}
          >
            downLeft
          </EuiButton>
        </:button>
        <:content>
          Popover content
        </:content>
      </EuiPopover>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop2}}
        @anchorPosition='downCenter'
        @closePopover={{set this 'pop2' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop2' true)}}
          >
            downCenter
          </EuiButton>
        </:button>
        <:content>
          Popover content
        </:content>
      </EuiPopover>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop3}}
        @anchorPosition='downRight'
        @closePopover={{set this 'pop3' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop3' true)}}
          >
            downRight
          </EuiButton>
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
        @ownFocus={{true}}
        @isOpen={{this.pop4}}
        @anchorPosition='upLeft'
        @closePopover={{set this 'pop4' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop4' true)}}
          >
            upLeft
          </EuiButton>
        </:button>
        <:content>
          Popover content
        </:content>
      </EuiPopover>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop5}}
        @anchorPosition='upCenter'
        @closePopover={{set this 'pop5' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop5' true)}}
          >
            upCenter
          </EuiButton>
        </:button>
        <:content>
          Popover content
        </:content>
      </EuiPopover>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop6}}
        @anchorPosition='upRight'
        @closePopover={{set this 'pop6' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop6' true)}}
          >
            upRight
          </EuiButton>
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
        @ownFocus={{true}}
        @isOpen={{this.pop7}}
        @anchorPosition='leftUp'
        @closePopover={{set this 'pop7' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop7' true)}}
          >
            leftUp
          </EuiButton>
        </:button>
        <:content>
          <EuiText>
            <p style='width: 200px;'>
              For left- or right-aligned popovers, make sure there is sufficient
              content. If the popover height is too short, the arrow positioning
              will appear off.
            </p>
          </EuiText>
        </:content>
      </EuiPopover>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop8}}
        @anchorPosition='leftCenter'
        @closePopover={{set this 'pop8' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop8' true)}}
          >
            leftCenter
          </EuiButton>
        </:button>
        <:content>
          Popover content
        </:content>
      </EuiPopover>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop9}}
        @anchorPosition='leftDown'
        @closePopover={{set this 'pop9' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop9' true)}}
          >
            leftDown
          </EuiButton>
        </:button>
        <:content>
          <EuiText>
            <p style='width: 200px;'>
              For left- or right-aligned popovers, make sure there is sufficient
              content. If the popover height is too short, the arrow positioning
              will appear off.
            </p>
          </EuiText>
        </:content>
      </EuiPopover>
    </EuiFlexItem>
  </EuiFlexGroup>
  <EuiSpacer size='l' />
  <EuiFlexGroup>
    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop10}}
        @anchorPosition='rightUp'
        @closePopover={{set this 'pop10' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop10' true)}}
          >
            rightUp
          </EuiButton>
        </:button>
        <:content>
          <EuiText>
            <p style='width: 200px;'>
              For left- or right-aligned popovers, make sure there is sufficient
              content. If the popover height is too short, the arrow positioning
              will appear off.
            </p>
          </EuiText>
        </:content>
      </EuiPopover>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop11}}
        @anchorPosition='rightCenter'
        @closePopover={{set this 'pop11' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop11' true)}}
          >
            rightCenter
          </EuiButton>
        </:button>
        <:content>
          Popover content
        </:content>
      </EuiPopover>
    </EuiFlexItem>
    <EuiFlexItem @grow={{false}}>
      <EuiPopover
        @ownFocus={{true}}
        @isOpen={{this.pop12}}
        @anchorPosition='rightDown'
        @closePopover={{set this 'pop12' false}}
      >
        <:button>
          <EuiButton
            @iconType='arrowDown'
            @iconSide='right'
            {{on 'click' (set this 'pop12' true)}}
          >
            rightDown
          </EuiButton>
        </:button>
        <:content>
          <EuiText>
            <p style='width: 200px;'>
              For left- or right-aligned popovers, make sure there is sufficient
              content. If the popover height is too short, the arrow positioning
              will appear off.
            </p>
          </EuiText>
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
  @tracked pop7 = false;
  @tracked pop8 = false;
  @tracked pop9 = false;
  @tracked pop10 = false;
  @tracked pop11 = false;
  @tracked pop12 = false;
}
```

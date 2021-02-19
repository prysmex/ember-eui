---
order: 2
---

# Demo

```hbs template
<EuiFlexGroup>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @ownFocus={{true}}
      @isOpen={{this.pop1}}
      @anchorPosition="downLeft"
      @closePopover={{set this.pop1 false}}
    >
      <:button as |register|>
        <EuiButton
          @iconType="arrowDown"
          @iconSide="right"
          {{did-insert register}}
          {{on "click" (set this.pop1 true)}}
        >
          downLeft
        </EuiButton>
      </:button>
      <:content>
        <EuiPopoverTitle>
          Hello, I’m a popover title
        </EuiPopoverTitle>
        <div style="width: 300px;">
          <EuiText size="s">
            <p>
              Selfies migas stumptown hot chicken quinoa wolf green juice,
                mumblecore tattooed trust fund hammock truffaut taxidermy kogi.
            </p>
          </EuiText>
        </div>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @ownFocus={{true}}
      @isOpen={{this.pop2}}
      @anchorPosition="downLeft"
      @closePopover={{set this.pop2 false}}
    >
      <:button as |register|>
        <EuiButton
          @iconType="arrowDown"
          @iconSide="right"
          {{did-insert register}}
          {{on "click" (set this.pop2 true)}}
        >
          downLeft
        </EuiButton>
      </:button>
      <:content>
        <div style="width: 300px;">
          <EuiText @size="s">
            <p>
              Selfies migas stumptown hot chicken quinoa wolf green juice,
                mumblecore tattooed trust fund hammock truffaut taxidermy kogi.
            </p>
          </EuiText>
        </div>
        <EuiPopoverFooter>
          <EuiTextColor @color="subdued">
            Hello, I’m a small popover footer caption
          </EuiTextColor>
        </EuiPopoverFooter>
      </:content>
    </EuiPopover>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @ownFocus={{true}}
      @isOpen={{this.pod3}}
      @anchorPosition="downLeft"
      @closePopover={{set this.pod3 false}}
    >
      <:button as |register|>
        <EuiButton
          @iconType="arrowDown"
          @iconSide="right"
          {{did-insert register}}
          {{on "click" (set this.pod3 true)}}
        >
          downLeft
        </EuiButton>
      </:button>
      <:content>
        <EuiPopoverTitle>
          Hello, I’m a popover title
        </EuiPopoverTitle>
        <div style="width: 300px">
          <EuiText @size="s">
            <p>
              Selfies migas stumptown hot chicken quinoa wolf green juice,
                mumblecore tattooed trust fund hammock truffaut taxidermy kogi.
            </p>
          </EuiText>
        </div>
        <EuiPopoverFooter>
          <EuiButton @fullWidth={{true}} @size="s">
            Manage this thing
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

export default class PopoverDemo1 extends Component {
  @tracked pop1 = false;
  @tracked pop2 = false;
  @tracked pop3 = false;
}
```

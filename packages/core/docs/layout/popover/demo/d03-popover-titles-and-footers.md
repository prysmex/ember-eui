---
order: 3
---

# Popover titles and footers
<EuiText>
  Popovers often need titling. Use the
  <strong>EuiPopoverTitle</strong>
  component nested somewhere inside the popover contents.
  <br /><br />
  You can also add a similarly styled
  <strong>EuiPopoverFooter</strong>
  for smaller captions or call to action buttons.
</EuiText>

```hbs template

<EuiFlexGroup @gutterSize="l">
  <!-- example 1 -->
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @ownFocus={{true}}
      @isOpen={{this.pop1}}
      @closePopover={{set this 'pop1' false}}
    >
      <:button>
        <EuiButton
          @iconType='arrowDown'
          @iconSide='right'
          {{on 'click' (set this 'pop1' true)}}
        >
          With title
        </EuiButton>
      </:button>
      <:content>
        <EuiPopoverTitle>
          Hello, I’m a popover title
        </EuiPopoverTitle>
        <div style='width: 300px;'>
          <EuiText @size='s'>
            <p>
              Selfies migas stumptown hot chicken quinoa wolf green juice, mumblecore tattooed trust fund hammock truffaut taxidermy kogi.
            </p>
          </EuiText>
        </div>
      </:content>
    </EuiPopover>
  </EuiFlexItem>

  <!-- example 2 -->
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @ownFocus={{true}}
      @isOpen={{this.pop2}}
      @anchorPosition='upCenter'
      @closePopover={{set this 'pop2' false}}
    >
      <:button>
        <EuiButton
          @iconType='arrowDown'
          @iconSide='right'
          {{on 'click' (set this 'pop2' true)}}
        >
          With footer
        </EuiButton>
      </:button>
      <:content>
        <div style='width: 300px;'>
          <EuiText @size='s'>
            <p>
              Selfies migas stumptown hot chicken quinoa wolf green juice, mumblecore tattooed trust fund hammock truffaut taxidermy kogi.
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

  <!-- example 3 -->
  <EuiFlexItem @grow={{false}}>
    <EuiPopover
      @ownFocus={{true}}
      @isOpen={{this.pop3}}
      @anchorPosition='upCenter'
      @closePopover={{set this 'pop3' false}}
    >
      <:button>
        <EuiButton
          @iconType='arrowDown'
          @iconSide='right'
          {{on 'click' (set this 'pop3' true)}}
        >
          With Title and footer button
        </EuiButton>
      </:button>
      <:content>
        <EuiPopoverTitle>
          Hello, I’m a popover title
        </EuiPopoverTitle>
        <div style='width: 300px;'>
          <EuiText @size='s'>
            <p>
              Selfies migas stumptown hot chicken quinoa wolf green juice, mumblecore tattooed trust fund hammock truffaut taxidermy kogi.
            </p>
          </EuiText>
        </div>
        <EuiPopoverFooter>
          <EuiButton @fullWidth={{true}}>
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

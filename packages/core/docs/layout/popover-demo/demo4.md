---
order: 4
---

```hbs template
<EuiTitle>
  Popover titles and footers
</EuiTitle>
<EuiSpacer />
<EuiText>
  Popovers often need titling. Use the
  <strong>EuiPopoverTitle</strong>
  component nested somewhere inside the popover contents.
  <br /><br />
  You can also add a similarly styled
  <strong>EuiPopoverFooter</strong>
  for smaller captions or call to action buttons.
</EuiText>
<EuiSpacer />
<EuiPopover
  @ownFocus={{true}}
  @isOpen={{this.pop1}}
  @closePopover={{set this 'pop1' false}}
>
  <:button>
    <EuiButton
      @iconType='arrowDown'
      @iconSide='right'
      @fill={{true}}
      {{on 'click' (set this 'pop1' true)}}
    >
      With title
    </EuiButton>
  </:button>
  <:content>
    <EuiPopoverTitle>
      HELLO, I’M A POPOVER TITLE
    </EuiPopoverTitle>
    <div style='width: 300px;'>
      <EuiText size='s'>
        <p>
          Selfies migas stumptown hot chicken quinoa wolf green juice, mumblecore tattooed trust fund hammock truffaut taxidermy kogi.
        </p>
      </EuiText>
    </div>
  </:content>
</EuiPopover>
<EuiPopover
  @ownFocus={{true}}
  @isOpen={{this.pop2}}
  @closePopover={{set this 'pop2' false}}
>
  <:button>
    <EuiButton
      @iconType='arrowDown'
      @iconSide='right'
      @fill={{true}}
      {{on 'click' (set this 'pop2' true)}}
    >
      With footer
    </EuiButton>
  </:button>
  <:content>
    <div style='width: 300px;'>
      <EuiText size='s'>
        <p>
          Selfies migas stumptown hot chicken quinoa wolf green juice, mumblecore tattooed trust fund hammock truffaut taxidermy kogi.
        </p>
      </EuiText>
    </div>
    <EuiPopoverFooter>
      Hello, I’m a small popover footer caption
    </EuiPopoverFooter>
  </:content>
</EuiPopover>
<EuiPopover
  @ownFocus={{true}}
  @isOpen={{this.pop3}}
  @closePopover={{set this 'pop3' false}}
>
  <:button>
    <EuiButton
      @iconType='arrowDown'
      @iconSide='right'
      @fill={{true}}
      {{on 'click' (set this 'pop3' true)}}
    >
      With Title and footer button
    </EuiButton>
  </:button>
  <:content>
    <EuiPopoverTitle>
      HELLO, I’M A POPOVER TITLE
    </EuiPopoverTitle>
    <div style='width: 300px;'>
      <EuiText size='s'>
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

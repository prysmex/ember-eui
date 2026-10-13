---
order: 3
---

# Popover titles and footers

<EuiText>
  <p>
    Popovers often need titling. Use the <strong>EuiPopoverTitle</strong> component nested somewhere inside the popover contents.
  </p>
  <p>
    You can also add a similarly styled <strong>EuiPopoverFooter</strong> for smaller captions or call to action buttons.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButton, EuiButtonEmpty, EuiFlexGroup, EuiFlexItem, EuiPopover, EuiPopoverFooter, EuiPopoverTitle, EuiText, EuiTextColor } from '@ember-eui/core/components';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

export default class PopoverDemo extends Component {
  @tracked isPopoverOpen1 = false;
  @tracked isPopoverOpen2 = false;
  @tracked isPopoverOpen3 = false;
  @action
  toggle(name) {
    this[name] = !this[name];
  }

  @action
  close(name) {
    this[name] = false;
  }

  <template>
    <EuiFlexGroup>
      <EuiFlexItem @grow={{false}}>
        <EuiPopover
          @isOpen={{this.isPopoverOpen1}}
          @closePopover={{fn this.close 'isPopoverOpen1'}}
          @anchorPosition='downCenter'
        >
          <:button>
            <EuiButtonEmpty
              @iconType='question'
              @iconSide='right'
              {{on 'click' (fn this.toggle 'isPopoverOpen1')}}
            >
              With title
            </EuiButtonEmpty>
          </:button>
          <:content>
            <EuiPopoverTitle>Hello, I&rsquo;m a popover title</EuiPopoverTitle>
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
      <EuiFlexItem @grow={{false}}>
        <EuiPopover
          @isOpen={{this.isPopoverOpen2}}
          @closePopover={{fn this.close 'isPopoverOpen2'}}
          @anchorPosition='upCenter'
        >
          <:button>
            <EuiButtonEmpty
              @iconType='question'
              @iconSide='right'
              {{on 'click' (fn this.toggle 'isPopoverOpen2')}}
            >
              With footer
            </EuiButtonEmpty>
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
              <EuiTextColor @color='subdued'>
                Hello, I&rsquo;m a small popover footer caption
              </EuiTextColor>
            </EuiPopoverFooter>
          </:content>
        </EuiPopover>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiPopover
          @isOpen={{this.isPopoverOpen3}}
          @closePopover={{fn this.close 'isPopoverOpen3'}}
          @anchorPosition='upCenter'
        >
          <:button>
            <EuiButtonEmpty
              @iconType='question'
              @iconSide='right'
              {{on 'click' (fn this.toggle 'isPopoverOpen3')}}
            >
              With title and footer button
            </EuiButtonEmpty>
          </:button>
          <:content>
            <EuiPopoverTitle>Hello, I&rsquo;m a popover title</EuiPopoverTitle>
            <div style='width: 300px;'>
              <EuiText @size='s'>
                <p>
                  Selfies migas stumptown hot chicken quinoa wolf green juice, mumblecore tattooed trust fund hammock truffaut taxidermy kogi.
                </p>
              </EuiText>
            </div>
            <EuiPopoverFooter>
              <EuiButton @fullWidth={{true}} @size='s'>
                Manage this thing
              </EuiButton>
            </EuiPopoverFooter>
          </:content>
        </EuiPopover>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```

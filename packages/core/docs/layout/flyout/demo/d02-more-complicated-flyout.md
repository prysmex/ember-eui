---
order: 2
---
# More complicated flyout

<EuiText>
  <p>

This component also comes with related child components for ease of creating headers, footers and scrolling body content. <strong>EuiFlyoutHeader</strong> and <strong>EuiFlyoutFooter</strong> are pinned to the top and bottom of the flyout, respectively, to allow for always visible navigation and actions. The <strong>EuiFlyoutBody</strong> component will then automatically overflow.

  </p>
  </EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { eq } from 'ember-truth-helpers';
import { set } from 'ember-set-helper';
import { EuiButton, EuiButtonEmpty, EuiCode, EuiCodeBlock, EuiComboBox, EuiExpression, EuiFlexGroup, EuiFlexItem, EuiFlyout, EuiFlyoutBody, EuiFlyoutFooter, EuiFlyoutHeader, EuiForm, EuiFormRow, EuiPopover, EuiSpacer, EuiSuperSelect, EuiTab, EuiTabs, EuiText, EuiTitle } from '@ember-eui/core/components';

export default class FlyoutComplicatedComponent extends Component {
  @tracked flyoutOpen = false;
  @tracked selectedTab;

  @tracked popover = false;
  @tracked superSelectValue = 'option_one';
  @tracked isExpressionOpen = false;

  htmlCode = `<!--I'm an example of HTML-->
<div>
  asdf
</div>
`;

  superSelectOptions = [
    { value: 'option_one', inputDisplay: 'Option one' },
    { value: 'option_two', inputDisplay: 'Option two' },
    { value: 'option_three', inputDisplay: 'Option three' }
  ];

  comboOptions = [
    { label: 'Option one' },
    { label: 'Option two' },
    { label: 'Option three' }
  ];

  comboSelected = [{ label: 'Option one' }];

  @action
  toggleExpression() {
    this.isExpressionOpen = !this.isExpressionOpen;
  }

  constructor() {
    super(...arguments);

    this.tabs = [
      {
        id: '1',
        name: 'Tab 1'
      },
      {
        id: '2',
        name: 'Tab 2'
      }
    ];

    this.selectedTab = this.tabs[0];
  }

  @action
  openFlyout() {
    this.flyoutOpen = true;
  }

  @action
  closeFlyout(flyout) {
    this.flyoutOpen = false;
  }

  <template>
  <EuiButton {{on 'click' this.openFlyout}}>
    Show flyout
  </EuiButton>

  {{#if this.flyoutOpen}}
    <EuiFlyout
      @ownFocus={{true}}
      @hideCloseButton={{true}}
      @onClose={{this.closeFlyout}}
      aria-labelledby="complicatedFlyoutTitle"
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size='m' id="complicatedFlyoutTitle">Flyout header</EuiTitle>
        <EuiSpacer @size='s'/>
        <EuiText @color="subdued">
          <p>
            Put navigation items in the header, and cross tab actions in a
            footer.
          </p>
        </EuiText>
        <EuiTabs style="margin-bottom: -25px;">
          {{#each this.tabs as |tab|}}
            <EuiTab
              @isSelected={{eq this.selectedTab.id tab.id}}
              {{on 'click' (set this 'selectedTab' tab)}}
            >
              {{tab.name}}
            </EuiTab>
          {{/each}}
        </EuiTabs>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>

        <EuiPopover
          @isOpen={{this.popover}}
          @repositionOnScroll={{true}}
          @closePopover={{set this 'popover' false}}
        >
          <:button>
            <EuiButton
              {{on 'click' (set this 'popover' true)}}
            >
              Even popovers can be included
            </EuiButton>
          </:button>
          <:content>
            <p>This is the popover content, notice how it can overflow the flyout!</p>
            <p>
              When placed in a flyout, the <EuiCode>@repositionOnScroll</EuiCode> argument ensures that the popover scrolls with body of the flyout.
            </p>
          </:content>
        </EuiPopover>

        <EuiSpacer @size="m" />

        <EuiForm @component="form">
          <EuiFormRow @label="A SuperSelect field">
            <EuiSuperSelect
              @options={{this.superSelectOptions}}
              @valueOfSelected={{this.superSelectValue}}
              @onChange={{set this "superSelectValue"}}
            >
              <:inputDisplay as |option|>{{option.inputDisplay}}</:inputDisplay>
              <:dropdownDisplay as |option|>
                <strong>{{option.inputDisplay}}</strong>
                <EuiText @size="s" @color="subdued">
                  <p>Has a short description giving more detail to the option.</p>
                </EuiText>
              </:dropdownDisplay>
            </EuiSuperSelect>
          </EuiFormRow>
        </EuiForm>

        <EuiSpacer />

        <EuiPopover
          @isOpen={{this.isExpressionOpen}}
          @repositionOnScroll={{true}}
          @closePopover={{set this "isExpressionOpen" false}}
        >
          <:button>
            <EuiExpression
              @description="expression"
              @value="configurations"
              @onClick={{this.toggleExpression}}
            />
          </:button>
          <:content>
            <EuiComboBox
              @options={{this.comboOptions}}
              @selectedOptions={{this.comboSelected}}
            />
          </:content>
        </EuiPopover>

        <EuiSpacer />

        <EuiText>
          <p>
            Far out in the uncharted backwaters of the unfashionable end of the
            western spiral arm of the Galaxy lies a small unregarded yellow sun.
          </p>

          <p>
            Orbiting this at a distance of roughly ninety-two million miles is an
            utterly insignificant little blue green planet whose ape- descended life
            forms are so amazingly primitive that they still think digital watches
            are a pretty neat idea.
          </p>

          <ul>
            <li>List item one</li>
            <li>List item two</li>
            <li>Dolphins</li>
          </ul>

          <p>
            This planet has - or rather had - a problem, which was this: most of the
            people living on it were unhappy for pretty much of the time. Many
            solutions were suggested for this problem, but most of these were
            largely concerned with the movements of small green pieces of paper,
            which is odd because on the whole it was not the small green pieces of
            paper that were unhappy.
          </p>

          <h2>This is Heading Two</h2>

          <ol>
            <li>Number one</li>
            <li>Number two</li>
            <li>Dolphins again</li>
          </ol>

          <p>
            But the dog wasn&rsquo;t lazy, it was just practicing mindfulness, so it
            had a greater sense of life-satisfaction than that fox with all its
            silly jumping.
          </p>

          <p>
            And from the fox&rsquo;s perspective, life was full of hoops to jump
            <em>through</em>, low-hanging fruit to jump <em>for</em>, and dead car
            batteries to jump-<em>start</em>.
          </p>

          <h3>This is Heading Three</h3>

          <p>
            So it thought the dog was making a poor life choice by focusing so much
            on mindfulness. What if its car broke down?
          </p>
        </EuiText>

        <EuiCodeBlock @language='html' @isCopyable={{false}}>{{this.htmlCode}}</EuiCodeBlock>

      </EuiFlyoutBody>
      <EuiFlyoutFooter>
        <EuiFlexGroup @justifyContent='spaceBetween'>
          <EuiFlexItem @grow={{false}}>
            <EuiButtonEmpty @iconType="cross" @flush="left" {{on 'click' this.closeFlyout}}>
              Close
            </EuiButtonEmpty>
          </EuiFlexItem>
          <EuiFlexItem @grow={{false}}>
            <EuiButton @fill={{true}} {{on 'click' this.closeFlyout}}>
              Save
            </EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiFlyoutFooter>
    </EuiFlyout>
  {{/if}}
  </template>
}
```

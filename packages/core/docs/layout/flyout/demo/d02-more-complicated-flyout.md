---
order: 2
---
# More complicated flyout

<EuiSpacer />

<EuiText>
  <p>

This component also comes with related child components for ease of creating headers, footers and scrolling body content. <strong>EuiFlyoutHeader</strong> and <strong>EuiFlyoutFooter</strong> are pinned to the top and bottom of the flyout, respectively, to allow for always visible navigation and actions. The <strong>EuiFlyoutBody</strong> component will then automatically overflow.

  </p>
  </EuiText>

```hbs template
<EuiButton {{on 'click' this.openFlyout}}>
  Show flyout
</EuiButton>

{{#if this.flyoutOpen}}
  <EuiFlyout
    @size='m'
    @onClose={{this.closeFlyout}}
  >
    <EuiFlyoutHeader @hasBorder={{true}}>
      <EuiTitle @size='l'>Flyout header</EuiTitle>
      <EuiSpacer @size='s'/>
      <EuiText @color="subdued">
        <p>Put navigation items in the header, and cross tab actions in a footer.</p>
      </EuiText>
      <EuiTabs @bottomBorder={{false}} style="margin-bottom: -25px;">
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
        @ownFocus={{true}}
        @isOpen={{this.popover}}
        @anchorPosition='downCenter'
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
            When placed in a flyout, the <EuiCode>repositionOnScroll</EuiCode> prop ensures that the popover scrolls with body of the flyout.
          </p>
        </:content>
      </EuiPopover>

      <EuiSpacer/>

      <TodoText @text="missing EuiSuperSelect component"/>
      <TodoText @text="missing euiExpression component"/>

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
          And from the fox&rsquo;s perspective, life was full of hoops to jump{' '}
          <em>through</em>, low-hanging fruit to jump <em>for</em>, and dead car
          batteries to jump-<em>start</em>.
        </p>

        <h3>This is Heading Three</h3>

        <p>
          So it thought the dog was making a poor life choice by focusing so much
          on mindfulness. What if its car broke down?
        </p>
      </EuiText>

      <EuiCodeBlock
        @isCopyable={{false}}
        @language='html'
      >
        {{this.htmlCode}}
      </EuiCodeBlock>

    </EuiFlyoutBody>
    <EuiFlyoutFooter>
      <EuiFlexGroup @justifyContent='spaceBetween' @gutterSize='s'>
        <EuiButtonEmpty @iconType="cross" {{on 'click' this.closeFlyout}}>
          Close
        </EuiButtonEmpty>
        <EuiButton
          @fill={{true}}
          {{on 'click' this.closeFlyout}}
        >
          Save
        </EuiButton>
      </EuiFlexGroup>
    </EuiFlyoutFooter>
  </EuiFlyout>
{{/if}}
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoFlyoutDemo2Component extends Component {
  @tracked flyoutOpen = false;
  @tracked selectedTab;

  htmlCode = `
    <!--I'm an example of HTML-->
    <div>
      asdf
    </div>
  `;

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
}
```

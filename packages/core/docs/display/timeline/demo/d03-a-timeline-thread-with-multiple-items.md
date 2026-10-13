---
order: 3
---

# A timeline thread with multiple items

<EuiText>

You can create a timeline thread by rendering multiple `EuiTimelineItem` components in a `EuiTimeline`. Following this structure ensures that timeline styles are applied correctly and appropriate semantic elements are used to assist with screen readers.

When passing an icon and content to each item, there are some design considerations to take into account:

*   icon: use icons of the same size to create a better visual consistency.
*   content: when your content is just one line of text, the recommendation is to use an `EuiText` as a wrapper. For multi-line content consider using an `EuiPanel` or an `EuiSplitPanel` instead. For other types of components like editors, the recommendation is to render the content without any wrapper.

The following example shows how to display multiple `EuiTimelineItem`s and how you can use an `EuiSplitPanel` as the content wrapper.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { euiPaletteColorBlindBehindText } from '@ember-eui/core/utils/color/eui_palettes';
import { EuiAccordion, EuiAvatar, EuiBadge, EuiFlexGroup, EuiFlexItem, EuiHorizontalRule, EuiPanel, EuiSpacer, EuiSplitPanelInner, EuiSplitPanelOuter, EuiSwitch, EuiText, EuiTimeline, EuiTimelineItem, EuiTitle } from '@ember-eui/core/components';
import { fn } from '@ember/helper';

class Phase {
  @tracked checked = false;

  constructor(title, color) {
    this.title = title;
    this.color = color;
  }

  get switchLabel() {
    return this.checked ? `${this.title} is on` : `${this.title} is off`;
  }
}

// We could use `euiPaletteColorBlind` for coloring the avatars, but because
// we're placing an icon on top of these colors `euiPaletteColorBlindBehindText`
// is a better choice to ensure better contrast
const colors = euiPaletteColorBlindBehindText();

export default class extends Component {
  hotColor = colors[0];

  phases = [
    new Phase('Warm phase', colors[1]),
    new Phase('Cold phase', colors[2]),
    new Phase('Frozen phase', colors[3]),
  ];

  @action
  toggle(phase) {
    phase.checked = !phase.checked;
  }

  <template>
    <EuiTimeline aria-label='Life cycle of data'>
      <EuiTimelineItem @verticalAlign='top'>
        <:icon>
          <EuiAvatar @name='Checked' @iconType='check' @color={{this.hotColor}} />
        </:icon>
        <:default>
          <EuiSplitPanelOuter @color='transparent' @hasBorder={{true}} @grow={{true}}>
            <EuiSplitPanelInner>
              <EuiTitle @size='s'>
                Hot phase
                <EuiBadge @color='warning'>Required</EuiBadge>
              </EuiTitle>
            </EuiSplitPanelInner>
            <EuiHorizontalRule @margin='none' />
            <EuiSplitPanelInner>
              <EuiText @grow={{false}} @size='s'>
                <p>
                  Store your most recent, most frequently-searched data in the hot
                  tier. The hot tier provides the best indexing and search
                  performance by using the most powerful, expensive hardware.
                </p>
              </EuiText>
            </EuiSplitPanelInner>
          </EuiSplitPanelOuter>
        </:default>
      </EuiTimelineItem>

      {{#each this.phases as |phase|}}
        <EuiTimelineItem @verticalAlign='top'>
          <:icon>
            {{#if phase.checked}}
              <EuiAvatar @name='Checked' @iconType='check' @color={{phase.color}} />
            {{else}}
              <EuiAvatar @name='Unchecked' @iconType='dot' @color='subdued' />
            {{/if}}
          </:icon>
          <:default>
            <EuiSplitPanelOuter @color='transparent' @hasBorder={{true}} @grow={{true}}>
              <EuiSplitPanelInner @color={{if phase.checked 'transparent' 'subdued'}}>
                <EuiFlexGroup @alignItems='center' @gutterSize='s'>
                  <EuiFlexItem @grow={{false}}>
                    <EuiSwitch
                      @showLabel={{false}}
                      @label={{phase.switchLabel}}
                      @checked={{phase.checked}}
                      @onChange={{fn this.toggle phase}}
                    />
                  </EuiFlexItem>
                  <EuiFlexItem>
                    <EuiTitle @size='s'>{{phase.title}}</EuiTitle>
                  </EuiFlexItem>
                </EuiFlexGroup>
              </EuiSplitPanelInner>
              <EuiHorizontalRule @margin='none' />
              <EuiSplitPanelInner>
                <EuiText @size='s' @grow={{false}}>
                  <p>
                    Move data to the cold tier when you are searching it less often
                    and don't need to update it. The cold tier is optimized for
                    cost savings over search performance.
                  </p>
                </EuiText>

                {{#if phase.checked}}
                  <EuiSpacer />
                  <EuiAccordion @buttonElement='div' @buttonContent='Advanced settings'>
                    <EuiPanel @color='transparent'>
                      Any content inside of <strong>EuiAccordion</strong> will appear here.
                    </EuiPanel>
                  </EuiAccordion>
                {{/if}}
              </EuiSplitPanelInner>
            </EuiSplitPanelOuter>
          </:default>
        </EuiTimelineItem>
      {{/each}}
    </EuiTimeline>
  </template>
}
```


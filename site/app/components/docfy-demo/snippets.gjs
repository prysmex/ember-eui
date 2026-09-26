import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { schedule } from '@ember/runloop';
import {
  EuiFlexGroup,
  EuiFlexItem,
  EuiHorizontalRule,
  EuiTab,
  EuiTabs,
} from '@ember-eui/core/components';
import EuiSplitPanelInner from '@ember-eui/core/components/eui-split-panel/inner';
import { classNames } from '@ember-eui/core/helpers';

import { eq } from 'ember-truth-helpers';

import DocfyDemoSnippet from './snippet.gjs';

/**
 * Tabbed group of snippets (template, component, ...). Each yielded Snippet
 * registers itself so its name shows up as a tab; clicking a tab toggles
 * that snippet's code block.
 */
export default class DocfyDemoSnippets extends Component {
  @tracked snippets = [];
  @tracked active = '';

  registerSnippet = (snippet) => {
    // snippets register while rendering; update the tabs right after
    // eslint-disable-next-line ember/no-runloop -- a render-queue hop, not a timer
    schedule('afterRender', this, () => {
      this.snippets = [...this.snippets, snippet];
    });
  };

  toggle = (id) => {
    this.active = this.active === id ? '' : id;
  };

  <template>
    <EuiSplitPanelInner
      class="docfy-demo__snippets"
      @borderRadius="none"
      @hasBorder={{false}}
      @hasShadow={{false}}
      @paddingSize="none"
      @color="subdued"
    >
      <EuiFlexGroup
        @gutterSize="none"
        @responsive={{false}}
        @wrap={{true}}
        @alignItems="center"
      >
        <EuiFlexItem>
          <EuiTabs
            class={{classNames
              "guideSectionTabs"
              (if this.active "guideSectionTabs--open")
            }}
            @display="condensed"
            @size="s"
          >
            {{#each this.snippets as |snippet|}}
              <EuiTab
                class="docfy-demo__snippets__tabs__button guideSectionTabs__tab"
                @id={{snippet.id}}
                @isSelected={{eq this.active snippet.id}}
                {{on "click" (fn this.toggle snippet.id)}}
              >
                {{snippet.label}}
              </EuiTab>
            {{/each}}
          </EuiTabs>
        </EuiFlexItem>
      </EuiFlexGroup>
      {{#if this.active}}
        <EuiHorizontalRule @margin="none" />
      {{/if}}
      {{yield
        (component
          DocfyDemoSnippet
          registerSnippet=this.registerSnippet
          active=this.active
          multiple=true
          id=@id
        )
      }}
    </EuiSplitPanelInner>
  </template>
}

import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { guidFor } from '@ember/object/internals';
import {
  EuiCodeBlock,
  EuiFlexGroup,
  EuiFlexItem,
  EuiHorizontalRule,
  EuiTab,
  EuiTabs,
} from '@ember-eui/core/components';
import EuiSplitPanelInner from '@ember-eui/core/components/eui-split-panel/inner';
import { classNames } from '@ember-eui/core/helpers';

const LANGUAGES = { template: 'hbs', component: 'js' };

/**
 * A code snippet of a demo. Inside Snippets (`@multiple`) it registers a tab
 * and shows its code while that tab is active; on its own it renders a single
 * "Template" tab that toggles the code.
 */
export default class DocfyDemoSnippet extends Component {
  @tracked isSingleSelected = false;

  id = guidFor(this);

  constructor(owner, args) {
    super(owner, args);

    this.args.registerSnippet?.({ id: this.id, label: this.label });
  }

  get label() {
    const name = this.args.name || '';

    return name.charAt(0).toUpperCase() + name.slice(1);
  }

  get language() {
    return LANGUAGES[this.args.name] ?? this.args.name;
  }

  get isActive() {
    return this.args.active === this.id;
  }

  toggleSingle = () => {
    this.isSingleSelected = !this.isSingleSelected;
  };

  <template>
    {{#if @multiple}}
      {{#if this.isActive}}
        <EuiCodeBlock
          class="docfy-demo__snippet"
          @language={{this.language}}
          @paddingSize="m"
          @isCopyable={{true}}
          @fontSize="m"
          @overflowHeight={{400}}
          ...attributes
        >
          {{yield}}
        </EuiCodeBlock>
      {{/if}}
    {{else}}
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
              @display="condensed"
              @size="s"
              class={{classNames
                "guideSectionTabs"
                (if this.isSingleSelected "guideSectionTabs--open")
              }}
            >
              <EuiTab
                class="docfy-demo__snippets__tabs__button guideSectionTabs__tab"
                @id={{this.id}}
                @isSelected={{this.isSingleSelected}}
                {{on "click" this.toggleSingle}}
              >
                Template
              </EuiTab>
            </EuiTabs>
          </EuiFlexItem>
        </EuiFlexGroup>

        {{#if this.isSingleSelected}}
          <EuiHorizontalRule @margin="none" />
          <EuiCodeBlock
            class="docfy-demo__snippet"
            @language={{this.language}}
            @paddingSize="m"
            @isCopyable={{true}}
            @fontSize="m"
            @overflowHeight={{400}}
            ...attributes
          >
            {{yield}}
          </EuiCodeBlock>
        {{/if}}
      </EuiSplitPanelInner>
    {{/if}}
  </template>
}

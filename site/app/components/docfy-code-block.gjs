import Component from '@glimmer/component';
import { EuiCodeBlock, EuiText } from '@ember-eui/core/components';

/**
 * Docfy's code blocks (fenced code in the docs prose) rendered with
 * EuiCodeBlock, so they are syntax highlighted like the demo snippets.
 * Keeps docfy's arguments: @language, @title, @copyable, @collapsible and
 * @showLineNumbers.
 */
const LANGUAGES = {
  sh: 'bash',
  shell: 'bash',
  zsh: 'bash',
  console: 'bash',
  gjs: 'js',
  gts: 'ts',
};

const COLLAPSED_HEIGHT = 300;

export default class DocfyCodeBlock extends Component {
  get language() {
    const language = this.args.language;
    return LANGUAGES[language] ?? language ?? 'text';
  }

  get isCopyable() {
    return this.args.copyable !== false;
  }

  get overflowHeight() {
    return this.args.collapsible === true ? COLLAPSED_HEIGHT : undefined;
  }

  <template>
    <div class="docsCodeBlock" data-test-id="code-block" data-language={{@language}} ...attributes>
      {{#if @title}}
        <EuiText @size="xs" @color="subdued" class="docsCodeBlock__title" data-test-id="code-block-header">
          <strong>{{@title}}</strong>
        </EuiText>
      {{/if}}
      <EuiCodeBlock
        @language={{this.language}}
        @isCopyable={{this.isCopyable}}
        @lineNumbers={{@showLineNumbers}}
        @overflowHeight={{this.overflowHeight}}
        @paddingSize="m"
        @fontSize="m"
      >
        {{yield}}
      </EuiCodeBlock>
    </div>
  </template>
}

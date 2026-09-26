import { or } from 'ember-truth-helpers';

import classNames from '../helpers/class-names.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** The scrolling main content of an EuiFlyout. */
export interface EuiFlyoutBodySignature {
  Element: HTMLDivElement;
  Blocks: {
    /** Content pinned above the scrolling body, e.g. an `EuiCallOut`. */
    banner?: [];
    /** The body; same as the default block. */
    content?: [];
    /** The body. */
    default?: [];
  };
}

const EuiFlyoutBody: TemplateOnlyComponent<EuiFlyoutBodySignature> = <template>
  <div class="euiFlyoutBody" ...attributes>
    <div
      tabindex={{0}}
      class={{classNames
        "euiFlyoutBody__overflow"
        (if (has-block "banner") "euiFlyoutBody__overflow--hasBanner")
      }}
    >
      {{#if (has-block "banner")}}
        <div class="euiFlyoutBody__banner">
          {{yield to="banner"}}
        </div>
      {{/if}}

      {{#if
        (or (has-block "banner") (has-block "content") (has-block "default"))
      }}
        <div class="euiFlyoutBody__overflowContent">
          {{#if (has-block "default")}}
            {{yield to="default"}}
          {{else}}
            {{yield to="content"}}
          {{/if}}
        </div>
      {{else}}
        {{yield}}
      {{/if}}
    </div>
  </div>
</template>;

export default EuiFlyoutBody;

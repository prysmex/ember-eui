import classNames from '../helpers/class-names';
import { or } from 'ember-truth-helpers';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiFlyoutBodySignature {
  Element: HTMLDivElement;
  Blocks: {
    banner?: [];
    content?: [];
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

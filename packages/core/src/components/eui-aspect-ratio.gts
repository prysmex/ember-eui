import { hash } from '@ember/helper';

import cssStyle from '../-private/css-style.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * Keeps its content (an iframe, video, image or map) at a fixed aspect
 * ratio while it takes the available width.
 */
export interface EuiAspectRatioSignature {
  Element: HTMLDivElement;
  Args: {
    /** Width part of the ratio, e.g. `16` for 16:9. */
    width: number;
    /** Height part of the ratio, e.g. `9` for 16:9. */
    height: number;
    /** Maximum width, e.g. `500` (px) or `'50%'`. */
    maxWidth?: number | string;
  };
  Blocks: {
    /** One element that fills the box, e.g. an `<iframe>`. */
    default: [];
  };
}

function paddingBottom(height: number, width: number): string {
  return `${(height / width) * 100}%`;
}

const EuiAspectRatio: TemplateOnlyComponent<EuiAspectRatioSignature> = <template>
  {{#if @maxWidth}}
    <div style={{cssStyle (hash maxWidth=@maxWidth)}}>
      <div
        class="euiAspectRatio"
        style={{cssStyle
          (hash
            paddingBottom=(paddingBottom @height @width) maxWidth=@maxWidth
          )
        }}
        ...attributes
      >{{yield}}</div>
    </div>
  {{else}}
    <div
      class="euiAspectRatio"
      style={{cssStyle (hash paddingBottom=(paddingBottom @height @width))}}
      ...attributes
    >{{yield}}</div>
  {{/if}}
</template>;

export default EuiAspectRatio;

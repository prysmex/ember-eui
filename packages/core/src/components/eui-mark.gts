import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * Highlights text with a `<mark>`, e.g. the part of a result that matches
 * a search. To highlight the matches in a string, use `EuiHighlight`.
 */
export interface EuiMarkSignature {
  Element: HTMLElement;
  Blocks: {
    /** The highlighted text. */
    default: [];
  };
}

const EuiMark: TemplateOnlyComponent<EuiMarkSignature> = <template>
  <mark class="euiMark" ...attributes>{{yield}}</mark>
</template>;

export default EuiMark;

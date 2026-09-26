import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** An error message under a control; EuiFormRow renders these from `@error`. */
export interface EuiFormErrorTextSignature {
  Element: HTMLDivElement;
  Blocks: {
    /** The message. */
    default: [];
  };
}

const EuiFormErrorText: TemplateOnlyComponent<EuiFormErrorTextSignature> =
  <template>
    <div class="euiFormErrorText" aria-live="polite" ...attributes>
      {{yield}}
    </div>
  </template>;

export default EuiFormErrorText;

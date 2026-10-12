import type { TOC } from '@ember/component/template-only';

import EuiFormAppendPrepend from './eui-form-control-layout/eui-form-append-prepend.gts';

import type {
  EuiFormAppendPrependArgs,
  EuiFormAppendPrependSignature
} from './eui-form-control-layout/eui-form-append-prepend';

export interface EuiFormPrependSignature {
  Element: EuiFormAppendPrependSignature['Element'];
  Args: EuiFormAppendPrependArgs;
  Blocks: {
    /** Content after the label and icons. */
    default: [];
  };
}

/**
 * Content shown before a form control, for an `EuiFormControlLayout` (or
 * field) `<:prepend>` block: a label, icons and/or a button. It inherits
 * `@compressed`, the disabled state and the control id from the layout.
 */
const EuiFormPrepend: TOC<EuiFormPrependSignature> = <template>
  <EuiFormAppendPrepend
    @side="prepend"
    @element={{@element}}
    @label={{@label}}
    @iconLeft={{@iconLeft}}
    @iconRight={{@iconRight}}
    @inputId={{@inputId}}
    @id={{@id}}
    @compressed={{@compressed}}
    @isDisabled={{@isDisabled}}
    @disabled={{@disabled}}
    @onClick={{@onClick}}
    @css={{@css}}
    ...attributes
  >{{yield}}</EuiFormAppendPrepend>
</template>;

export default EuiFormPrepend;

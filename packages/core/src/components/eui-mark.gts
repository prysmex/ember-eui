import Component from '@glimmer/component';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiMarkScreenReaderStyles,
  euiMarkStyles
} from '../utils/eui/utilities.ts';

import type EuiI18n from '../services/eui-i18n.ts';

/**
 * Highlights text with a `<mark>`, e.g. the part of a result that matches
 * a search. To highlight the matches in a string, use `EuiHighlight`.
 */
export interface EuiMarkSignature {
  Element: HTMLElement;
  Args: {
    /**
     * Screen readers announce "highlight start" / "highlight end" around
     * the text (visually hidden `::before`/`::after` content). Set to
     * `false` to remove it. Defaults to `true`.
     */
    hasScreenReaderHelpText?: boolean;
  };
  Blocks: {
    /** The highlighted text. */
    default: [];
  };
}

export default class EuiMark extends Component<EuiMarkSignature> {
  @service declare euiI18n: EuiI18n;

  get classes() {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiMarkStyles);
    const helpText =
      this.args.hasScreenReaderHelpText === false
        ? undefined
        : euiMarkScreenReaderStyles(
            this.euiI18n.lookupToken('euiMark.highlightStart', 'highlight start'),
            this.euiI18n.lookupToken('euiMark.highlightEnd', 'highlight end')
          ).hasScreenReaderHelpText;
    return `euiMark ${euiClass(context, styles.euiMark, helpText)}`;
  }

  <template>
    <mark class={{this.classes}} ...attributes>{{yield}}</mark>
  </template>
}

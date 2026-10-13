import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiErrorBoundaryStyles } from '../utils/eui/styles.generated.ts';
import EuiCodeBlock from './eui-code-block.gts';
import EuiTitle from './eui-title.gts';

import type EuiI18n from '../services/eui-i18n.ts';
import type { EuiCss } from '../utils/eui/styles.ts';

/**
 * Upstream `EuiErrorBoundary`'s message text: "Error: message" followed by
 * the stack without its first line (only Chrome repeats the message there).
 */
export function euiErrorMessageText(error: unknown): string {
  if (!(error instanceof Error)) return String(error);
  const { message, stack } = error;
  const index = stack?.indexOf(message) ?? -1;
  const rest =
    index > -1 ? stack?.substring(index + message.length + 1) : stack;
  return `Error: ${message}\n${rest ?? ''}`;
}

export interface EuiErrorMessageSignature {
  Element: HTMLDivElement;
  Args: {
    /** The text to show, as upstream's `errorMessage` (e.g. a message and stack). */
    errorMessage?: string;
    /**
     * Ember EUI: an error to show instead, formatted like upstream's
     * `EuiErrorBoundary` formats a caught error (message and stack). Handy in
     * a route's `error` template: `<EuiErrorMessage @error={{@model}} />`.
     */
    error?: unknown;
    /** Extra styles composed last into the panel's class (upstream's `css`). */
    css?: EuiCss;
  };
}

/**
 * Upstream `EuiErrorMessage`, the fallback `EuiErrorBoundary` renders: a
 * danger-striped panel with an "Error" title and the error text in a code
 * block. Ember has no render error boundaries, so render it yourself where
 * an error was caught, e.g. in a route's `error` template.
 */
export default class EuiErrorMessage extends Component<EuiErrorMessageSignature> {
  @service declare euiI18n: EuiI18n;

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiErrorBoundaryStyles);
    return `euiErrorBoundary ${euiClass(context, styles.euiErrorBoundary, this.args.css)}`;
  }

  get text(): string | undefined {
    if (this.args.errorMessage !== undefined) return this.args.errorMessage;
    if (this.args.error !== undefined) return euiErrorMessageText(this.args.error);
    return undefined;
  }

  get title(): string {
    return this.euiI18n.lookupToken('euiErrorBoundary.error', 'Error');
  }

  <template>
    <div class={{this.classes}} data-test-subj="euiErrorBoundary" ...attributes>
      {{! upstream puts the title inside the code block; ours highlights text only }}
      <EuiTitle @size="xs"><p>{{this.title}}</p></EuiTitle>
      <EuiCodeBlock>{{this.text}}</EuiCodeBlock>
    </div>
  </template>
}

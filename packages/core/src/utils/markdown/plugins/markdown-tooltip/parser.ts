import EuiMarkdownFormatMarkdownTooltip from '../../../../components/eui-markdown-format/markdown-tooltip.gts';

import type { RemarkTokenizer } from '../../markdown-types';
import type { Plugin } from 'unified';

interface TooltipNodeDetails {
  type: 'component';
  tooltipText: string;
}

export const TooltipParser: Plugin = function TooltipParser() {
  const Parser = this.Parser;
  const tokenizers = Parser.prototype.inlineTokenizers;
  const methods = Parser.prototype.inlineMethods;

  const tokenizeTooltip: RemarkTokenizer = function tokenizeTooltip(
    eat,
    value,
    silent
  ) {
    if (value.startsWith('!{tooltip') === false) return false;

    const nextChar = value[9];

    if (nextChar !== '[') return false; // this isn't actually a tooltip

    let index = 9;

    function readArg(open: string, close: string) {
      if (value[index] !== open) throw 'Expected left bracket';
      index++;

      let body = '';
      let openBrackets = 0;

      for (; index < value.length; index++) {
        const char = value[index];

        if (char === close && openBrackets === 0) {
          index++;

          return body;
        } else if (char === close) {
          openBrackets--;
        } else if (char === open) {
          openBrackets++;
        }

        body += char;
      }

      return '';
    }

    const tooltipAnchor = readArg('[', ']');
    const tooltipText = readArg('(', ')');

    const now = eat.now();

    if (!tooltipAnchor) {
      this.file.info('No tooltip anchor found', {
        line: now.line,
        column: now.column + 10
      });
    }

    if (!tooltipText) {
      this.file.info('No tooltip text found', {
        line: now.line,
        column: now.column + 12 + tooltipAnchor.length
      });
    }

    if (!tooltipText || !tooltipAnchor) return false;

    if (silent) {
      return true;
    }

    now.column += 10;
    now.offset += 10;

    const children = this.tokenizeInline(tooltipAnchor, now);

    return eat(`!{tooltip[${tooltipAnchor}](${tooltipText})}`)({
      type: 'component',
      componentName: EuiMarkdownFormatMarkdownTooltip,
      tooltipText: tooltipText,
      children
    } as TooltipNodeDetails);
  };

  tokenizeTooltip.notInLink = true;

  tokenizeTooltip.locator = (value, fromIndex) => {
    return value.indexOf('!{tooltip', fromIndex);
  };

  tokenizers.tooltip = tokenizeTooltip;
  methods.splice(methods.indexOf('text'), 0, 'tooltip');
};

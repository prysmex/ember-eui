import { tooltipMarkdownIconStyles } from '../../utils/eui/markdown.ts';
import EuiIcon from '../eui-icon.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private A `!{tooltip[text](tooltip)}` rendered by EuiMarkdownFormat. */
export interface MarkdownTooltipSignature {
  Args: {
    /** The parsed tooltip node. */
    node: {
      content: string;
      tooltipText: string;
    };
  };
  Blocks: {
    default: [];
  };
}

const MarkdownTooltip: TemplateOnlyComponent<MarkdownTooltipSignature> =
  <template>
    <span>
      <EuiToolTip @content={{@node.tooltipText}}>
        <span>
          <strong>{{@node.content}}</strong>
          {{! upstream: type "question", absent from the bundled icon set }}
          <EuiIcon
            @type="question"
            @css={{tooltipMarkdownIconStyles}}
          />
        </span>
      </EuiToolTip>
    </span>
  </template>;

export default MarkdownTooltip;
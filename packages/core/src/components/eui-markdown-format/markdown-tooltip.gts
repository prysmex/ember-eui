import EuiIcon from '../eui-icon.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface MarkdownTooltipSignature {
  Args: {
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
          <EuiIcon
            @type="questionInCircle"
            @iconClasses="euiMarkdownTooltip__icon"
          />
        </span>
      </EuiToolTip>
    </span>
  </template>;

export default MarkdownTooltip;
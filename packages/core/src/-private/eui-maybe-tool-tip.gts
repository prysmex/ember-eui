import EuiToolTip from '../components/eui-tool-tip.gts';

import type { EuiCss } from '../utils/eui/styles.ts';
import type { EuiTooltipArgs } from '../components/eui-tool-tip.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiMaybeToolTipSignature {
  Args: {
    /**
     * Upstream's `tooltipProps` as an object of `EuiToolTip` args. Without
     * it the content renders as is.
     */
    props?: Partial<EuiTooltipArgs>;
    /** Replaces `props.anchorClassName`. */
    anchorClass?: string;
    /** Replaces `props.anchorCss`. */
    anchorCss?: EuiCss;
  };
  Blocks: { default: [] };
}

/** Wraps its content in an `EuiToolTip` when there are tooltip props. */
const EuiMaybeToolTip: TemplateOnlyComponent<EuiMaybeToolTipSignature> = <template>
  {{#if @props}}
    <EuiToolTip
      @content={{@props.content}}
      @title={{@props.title}}
      @position={{@props.position}}
      @delay={{@props.delay}}
      @offset={{@props.offset}}
      @display={{@props.display}}
      @id={{@props.id}}
      @className={{@props.className}}
      @disableScreenReaderOutput={{@props.disableScreenReaderOutput}}
      @repositionOnScroll={{@props.repositionOnScroll}}
      @hasTitle={{@props.hasTitle}}
      @css={{@props.css}}
      @anchorClassName={{if @anchorClass @anchorClass @props.anchorClassName}}
      @anchorCss={{if @anchorCss @anchorCss @props.anchorCss}}
    >
      {{yield}}
    </EuiToolTip>
  {{else}}
    {{yield}}
  {{/if}}
</template>;

export default EuiMaybeToolTip;

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
    /**
     * Renders the `<:content>` block as the tooltip's content instead of
     * `props.content` (upstream's node content).
     */
    blockContent?: boolean;
  };
  Blocks: { default: []; content: [] };
}

/** Wraps its content in an `EuiToolTip` when there are tooltip props. */
const EuiMaybeToolTip: TemplateOnlyComponent<EuiMaybeToolTipSignature> = <template>
  {{#if @props}}
    {{#if @blockContent}}
      <EuiToolTip
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
        @isShown={{@props.isShown}}
        @onMouseOut={{@props.onMouseOut}}
        @onFocus={{@props.onFocus}}
        @onBlur={{@props.onBlur}}
        @css={{@props.css}}
        @anchorClassName={{if @anchorClass @anchorClass @props.anchorClassName}}
        @anchorCss={{if @anchorCss @anchorCss @props.anchorCss}}
        @anchorStyle={{@props.anchorStyle}}
        @anchorProps={{@props.anchorProps}}
        @attachTo={{@props.attachTo}}
      >
        <:anchor>{{yield}}</:anchor>
        <:content>{{yield to="content"}}</:content>
      </EuiToolTip>
    {{else}}
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
        @isShown={{@props.isShown}}
        @onMouseOut={{@props.onMouseOut}}
        @onFocus={{@props.onFocus}}
        @onBlur={{@props.onBlur}}
        @css={{@props.css}}
        @anchorClassName={{if @anchorClass @anchorClass @props.anchorClassName}}
        @anchorCss={{if @anchorCss @anchorCss @props.anchorCss}}
        @anchorStyle={{@props.anchorStyle}}
        @anchorProps={{@props.anchorProps}}
        @attachTo={{@props.attachTo}}
      >
        {{yield}}
      </EuiToolTip>
    {{/if}}
  {{else}}
    {{yield}}
  {{/if}}
</template>;

export default EuiMaybeToolTip;

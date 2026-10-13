import EuiPopover from '../components/eui-popover.gts';
import argOrDefault from '../helpers/arg-or-default.ts';
import EuiRenderNode from './eui-render-node.gts';

import type { EuiPopoverArgs } from '../components/eui-popover.gts';
import type { EuiRenderNode as EuiRenderNodeType } from './eui-render-node.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * Upstream's `WithEuiPopoverProps`: the args of `EuiPopover` (minus the
 * button, which is the wrapped content), plus its `children` as text or a
 * component.
 */
export type EuiWithPopoverProps = Partial<EuiPopoverArgs> & {
  /** The popover's content (upstream's `children`): text or a component. */
  children?: EuiRenderNodeType;
  className?: string;
};

const noop = () => {};

export interface EuiMaybePopoverSignature {
  Args: {
    /** `EuiPopover` args and the content. Without it the content renders as is. */
    props?: EuiWithPopoverProps;
  };
  Blocks: { default: [] };
}

/** Upstream's `withEuiPopover`: wraps its content as the button of an `EuiPopover` when there are props. */
const EuiMaybePopover: TemplateOnlyComponent<EuiMaybePopoverSignature> = <template>
  {{#if @props}}
    <EuiPopover
      class={{@props.className}}
      @isOpen={{@props.isOpen}}
      @closePopover={{argOrDefault @props.closePopover noop}}
      @anchorPosition={{@props.anchorPosition}}
      @anchorClassName={{@props.anchorClassName}}
      @display={{@props.display}}
      @hasArrow={{@props.hasArrow}}
      @initialFocus={{@props.initialFocus}}
      @ownFocus={{@props.ownFocus}}
      @panelClassName={{@props.panelClassName}}
      @panelPaddingSize={{@props.panelPaddingSize}}
      @panelStyle={{@props.panelStyle}}
      @panelCss={{@props.panelCss}}
      @css={{@props.css}}
      @popoverScreenReaderText={{@props.popoverScreenReaderText}}
      @repositionOnScroll={{@props.repositionOnScroll}}
      @repositionToCrossAxis={{@props.repositionToCrossAxis}}
      @zIndex={{@props.zIndex}}
      @offset={{@props.offset}}
      @buffer={{@props.buffer}}
      @ariaLabel={{@props.ariaLabel}}
      @ariaLabelledBy={{@props.ariaLabelledBy}}
      @container={{@props.container}}
      @attachToAnchor={{@props.attachToAnchor}}
      @onTrapDeactivation={{@props.onTrapDeactivation}}
      @portalRef={{@props.portalRef}}
      @panelRef={{@props.panelRef}}
      @popoverRef={{@props.popoverRef}}
      @tabindex={{@props.tabindex}}
      @shouldSelfFocus={{@props.shouldSelfFocus}}
      @focusTrapOptions={{@props.focusTrapOptions}}
    >
      <:button>{{yield}}</:button>
      <:content><EuiRenderNode @value={{@props.children}} /></:content>
    </EuiPopover>
  {{else}}
    {{yield}}
  {{/if}}
</template>;

export default EuiMaybePopover;

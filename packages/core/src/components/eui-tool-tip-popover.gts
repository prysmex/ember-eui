import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import willDestroy from '@ember/render-modifiers/modifiers/will-destroy';
import type Owner from '@ember/owner';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import { euiToolTipStyles } from '../utils/eui/styles.generated.ts';

import type { CommonArgs } from './common.ts';

type EuiTooltipPopoverArgs = CommonArgs & {
  /** Repositions the tooltip (on resize and scroll). */
  positionToolTip: () => void;
  /** @deprecated Has no effect, use the `<:title>` block. */
  title?: Component;
  /** Called with the tooltip element. */
  popoverRef?: (ref: HTMLDivElement | null) => void;
  /** Render the title. */
  hasTitle?: boolean;
  /** Position the tooltip ended up in (`data-position`, upstream). */
  calculatedPosition?: 'top' | 'right' | 'bottom' | 'left';
  /** Extra styles composed last into the tooltip's class. */
  css?: EuiCss;
};

/** @private The floating part of EuiToolTip. */
export interface EuiTooltipPopoverSignature {
  Element: HTMLDivElement;
  Args: EuiTooltipPopoverArgs;
  Blocks: {
    /** Unused. */
    default: [];
    /** The title. */
    title: [];
    /** The content. */
    content: [];
  };
}

export default class EuiTooltipPopover extends Component<EuiTooltipPopoverSignature> {
  popover: HTMLDivElement | null = null;

  constructor(owner: Owner, args: EuiTooltipPopoverArgs) {
    super(owner, args);
    document.body.classList.add('euiBody-hasPortalContent');
    window.addEventListener('resize', this.updateDimensions);
    window.addEventListener('scroll', this.updateDimensions, true);
  }

  willDestroy(): void {
    super.willDestroy();
    document.body.classList.remove('euiBody-hasPortalContent');
    window.removeEventListener('resize', this.updateDimensions);
    window.removeEventListener('scroll', this.updateDimensions, true);
    this.popover = null;
  }

  @action
  setPopoverRef(popover: HTMLDivElement | null): void {
    this.popover = popover;

    if (this.args.popoverRef) {
      this.args.popoverRef(popover);
    }
  }

  /** Upstream `euiToolTipStyles`: base and the position slot. */
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiToolTipStyles);
    const position = this.args.calculatedPosition;

    return `euiToolTipPopover ${euiClass(
      context,
      styles.euiToolTip,
      position && styles[position],
      this.args.css
    )}`;
  }

  @cached
  get titleClasses(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiToolTipStyles);

    return `euiToolTip__title ${euiClass(context, styles.euiToolTip__title)}`;
  }

  @action
  updateDimensions(): void {
    requestAnimationFrame(() => {
      // Because of this delay, sometimes `positionToolTip` becomes unavailable.
      if (this.popover) {
        this.args.positionToolTip();
      }
    });
  }

  <template>
    <div
      class={{this.classes}}
      data-position={{@calculatedPosition}}
      {{didInsert this.setPopoverRef}}
      {{willDestroy (fn this.setPopoverRef null)}}
      ...attributes
    >
      {{#if @hasTitle}}
        <div class={{this.titleClasses}}>
          {{yield to="title"}}
        </div>
      {{/if}}
      {{yield to="content"}}
    </div>
  </template>
}

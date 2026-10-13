import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import classNames from '../../helpers/class-names.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import EuiButton from '../eui-button.gts';
import EuiHideFor from '../eui-hide-for.gts';
import { euiScreenReaderOnlyClass } from '../eui-screen-reader-only.gts';
import EuiShowFor from '../eui-show-for.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type EuiI18n from '../../services/eui-i18n';
import type { EuiBreakpointSize } from '../../utils/breakpoint.ts';
import type { EuiButtonSignature } from '../eui-button';
import type { EuiResponsiveSizes } from '../eui-show-for.gts';
import type { EuiTooltipArgs } from '../eui-tool-tip.gts';

/**
 * `EuiToolTip` arguments the update button forwards from `toolTipProps`
 * (upstream `Partial<EuiToolTipProps>`).
 */
export type EuiSuperUpdateButtonToolTipProps = Pick<
  EuiTooltipArgs,
  | 'anchorClassName'
  | 'anchorCss'
  | 'className'
  | 'content'
  | 'css'
  | 'delay'
  | 'disableScreenReaderOutput'
  | 'display'
  | 'id'
  | 'offset'
  | 'position'
  | 'repositionOnScroll'
  | 'title'
>;

/** @private EuiSuperDatePicker's refresh / update button. */
export interface EuiSuperUpdateButtonSignature {
  Element: EuiButtonSignature['Element'];
  Args: {
    /** Extra class(es). */
    className?: string;
    /** Solid button. Defaults to `true` (upstream). */
    fill?: boolean;
    /**
     * Shows only the icon; the label stays for screen readers (upstream
     * forces `responsive` to all sizes).
     */
    iconOnly?: boolean;
    /** Disables it. */
    isDisabled?: boolean;
    /** Loading state. */
    isLoading?: boolean;
    /** Highlights that the range changed and needs applying. */
    needsUpdate?: boolean;
    /** Called on click. */
    onClick: (e: MouseEvent) => void;
    /** Size of the button. */
    size?: EuiButtonSignature['Args']['size'];
    /** Classes for the text. */
    textClasses?: string;
    /**
     * Button color, instead of `primary` (`success` while an update is
     * pending or loading).
     */
    color?: EuiButtonSignature['Args']['color'];
    /** Icon, instead of `refresh` (`push` while an update is pending). */
    iconType?: string;
    /**
     * Custom label (upstream `children`), instead of "Refresh" / "Update" /
     * "Updating"; keep it in sync with `@needsUpdate` and `@isLoading`.
     */
    label?: string;
    /**
     * Minimum width of the text button, a number of px or a CSS length;
     * `false` removes it. Defaults to `118`.
     */
    minWidth?: number | string | false;
    /**
     * Shows the "Click to apply" tooltip for 2 seconds whenever the button
     * updates while an update is pending. Defaults to `false`.
     */
    showTooltip?: boolean;
    /** Arguments for the `EuiToolTip` around the button. */
    toolTipProps?: EuiSuperUpdateButtonToolTipProps;
    /**
     * Screen sizes on which the button collapses to its icon (the label
     * stays for screen readers); `false` never collapses it. Defaults to
     * `['xs', 's']`.
     */
    responsive?: false | EuiBreakpointSize[];
  };
}

/**
 * Upstream `EuiSuperUpdateButtonProps` as EuiSuperDatePicker's
 * `@updateButtonProps` takes them (the arguments it can forward).
 */
export interface EuiSuperUpdateButtonProps {
  fill?: boolean;
  color?: EuiButtonSignature['Args']['color'];
  size?: EuiButtonSignature['Args']['size'];
  iconType?: string;
  iconOnly?: boolean;
  className?: string;
  /** A custom label (upstream `children`). */
  children?: string;
  minWidth?: number | string | false;
  /** Shows the "Click to apply" tooltip (the picker sets it while no date popover is open). */
  showTooltip?: boolean;
  /** Arguments for the button's `EuiToolTip`, e.g. `{ position: 'top' }`. */
  toolTipProps?: EuiSuperUpdateButtonToolTipProps;
  /** Sizes on which the button collapses to its icon, or `false`. */
  responsive?: false | EuiBreakpointSize[];
  'data-test-subj'?: string;
}

const DEFAULT_RESPONSIVE: EuiBreakpointSize[] = ['xs', 's'];

/** Upstream shows "Click to apply" for 2 seconds. */
const TOOLTIP_DURATION = 2000;

export default class EuiSuperUpdateButton extends Component<EuiSuperUpdateButtonSignature> {
  @service declare euiI18n: EuiI18n;

  /** `true` while the "Click to apply" tooltip is forced open. */
  @tracked tooltipShown = false;

  private tooltipTimer?: ReturnType<typeof setTimeout>;
  private installedButtons = new WeakSet<Element>();

  get isActive() {
    return Boolean(this.args.needsUpdate || this.args.isLoading);
  }

  get color() {
    return this.args.color ?? (this.isActive ? 'success' : 'primary');
  }

  /** Upstream uses `push` while an update is pending or loading. */
  get iconType() {
    return this.args.iconType ?? (this.isActive ? 'push' : 'refresh');
  }

  /** Upstream `minWidth={118}` on the full button. */
  get minWidth() {
    return this.args.minWidth ?? 118;
  }

  /** Upstream passes `size` to EuiButton, whose default is `m`. */
  get size() {
    return this.args.size ?? 'm';
  }

  get fill() {
    return this.args.fill ?? true;
  }

  /** Upstream: `iconOnly` forces the collapsed button on all sizes. */
  get responsive(): EuiResponsiveSizes {
    if (this.args.iconOnly) return 'all';
    const responsive = this.args.responsive ?? DEFAULT_RESPONSIVE;
    return responsive || 'none';
  }

  /** The collapsed button keeps its label for screen readers only. */
  @cached
  get iconOnlyTextClasses() {
    return [
      euiScreenReaderOnlyClass(getEuiThemeContext(this)),
      this.args.textClasses
    ]
      .filter(Boolean)
      .join(' ');
  }

  get label() {
    if (this.args.label) return this.args.label;

    if (this.args.isLoading) {
      return this.euiI18n.lookupToken(
        'euiSuperUpdateButton.updatingButtonLabel',
        'Updating'
      );
    }

    if (this.args.needsUpdate) {
      return this.euiI18n.lookupToken(
        'euiSuperUpdateButton.updateButtonLabel',
        'Update'
      );
    }

    return this.euiI18n.lookupToken(
      'euiSuperUpdateButton.refreshButtonLabel',
      'Refresh'
    );
  }

  /** Upstream `renderTooltipContent`. */
  get tooltipContent() {
    if (this.args.isDisabled) {
      return this.euiI18n.lookupToken(
        'euiSuperUpdateButton.cannotUpdateTooltip',
        'Cannot update'
      );
    }

    if (this.args.needsUpdate && !this.args.isLoading) {
      return this.euiI18n.lookupToken(
        'euiSuperUpdateButton.clickToApplyTooltip',
        'Click to apply'
      );
    }

    return undefined;
  }

  get toolTipProps(): EuiSuperUpdateButtonToolTipProps {
    return this.args.toolTipProps ?? {};
  }

  get toolTipContentArg() {
    return 'content' in this.toolTipProps
      ? this.toolTipProps.content
      : this.tooltipContent;
  }

  /**
   * Upstream `componentDidUpdate`: with `showTooltip`, an update while an
   * update is pending (and the button is usable) shows the tooltip, and
   * hides it 2 seconds later.
   */
  autoShowTooltip = modifier(
    (
      element: Element,
      [showTooltip, needsUpdate, isDisabled, isLoading]: [
        boolean | undefined,
        boolean | undefined,
        boolean | undefined,
        boolean | undefined
      ]
    ) => {
      // updates only, not the first render (upstream `componentDidUpdate`)
      if (!this.installedButtons.has(element)) {
        this.installedButtons.add(element);
        return;
      }

      if (!(showTooltip && needsUpdate && !isDisabled && !isLoading)) return;

      // after this render: the tooltip is tracked state read by it
      queueMicrotask(() => {
        if (this.isDestroying || this.isDestroyed) return;
        clearTimeout(this.tooltipTimer);
        this.tooltipShown = true;
        this.tooltipTimer = setTimeout(() => {
          if (this.isDestroying || this.isDestroyed) return;
          this.tooltipShown = false;
        }, TOOLTIP_DURATION);
      });
    }
  );

  willDestroy() {
    super.willDestroy();
    clearTimeout(this.tooltipTimer);
  }

  <template>
    <EuiToolTip
      @content={{this.toolTipContentArg}}
      @position={{if this.toolTipProps.position this.toolTipProps.position "bottom"}}
      @isShown={{this.tooltipShown}}
      @anchorClassName={{this.toolTipProps.anchorClassName}}
      @anchorCss={{this.toolTipProps.anchorCss}}
      @className={{this.toolTipProps.className}}
      @css={{this.toolTipProps.css}}
      @delay={{this.toolTipProps.delay}}
      @disableScreenReaderOutput={{this.toolTipProps.disableScreenReaderOutput}}
      @display={{this.toolTipProps.display}}
      @id={{this.toolTipProps.id}}
      @offset={{this.toolTipProps.offset}}
      @repositionOnScroll={{this.toolTipProps.repositionOnScroll}}
      @title={{this.toolTipProps.title}}
    >
      <EuiShowFor @sizes={{this.responsive}}>
        <EuiButton
          class={{classNames "euiSuperUpdateButton" @className}}
          data-test-subj="superDatePickerApplyTimeButton"
          @minWidth={{false}}
          @fill={{this.fill}}
          @textClasses={{this.iconOnlyTextClasses}}
          @color={{this.color}}
          @iconType={{this.iconType}}
          @isDisabled={{@isDisabled}}
          @isLoading={{@isLoading}}
          @size={{this.size}}
          {{on "click" @onClick}}
          {{this.autoShowTooltip
            @showTooltip
            @needsUpdate
            @isDisabled
            @isLoading
          }}
          ...attributes
        >
          {{this.label}}
        </EuiButton>
      </EuiShowFor>
      <EuiHideFor @sizes={{this.responsive}}>
        <EuiButton
          class={{classNames "euiSuperUpdateButton" @className}}
          data-test-subj="superDatePickerApplyTimeButton"
          @minWidth={{this.minWidth}}
          @fill={{this.fill}}
          @textClasses={{@textClasses}}
          @color={{this.color}}
          @iconType={{this.iconType}}
          @isDisabled={{@isDisabled}}
          @isLoading={{@isLoading}}
          @size={{this.size}}
          {{on "click" @onClick}}
          {{this.autoShowTooltip
            @showTooltip
            @needsUpdate
            @isDisabled
            @isLoading
          }}
          ...attributes
        >
          {{this.label}}
        </EuiButton>
      </EuiHideFor>
    </EuiToolTip>
  </template>
}

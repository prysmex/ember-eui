import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { schedule } from '@ember/runloop';
import { service } from '@ember/service';

import { modifier } from 'ember-modifier';

import cssStyle from '../../-private/css-style.ts';
import { randomId } from '../../-private/random-id.ts';
import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import {
  euiPaddingSize,
  euiResizablePanelContentStyles,
  euiResizablePanelStyles
} from '../../utils/eui/styles.generated.ts';
import EuiPanel from '../eui-panel.gts';
import EuiResizableCollapseButton from './collapse-button.gts';

import type EuiI18n from '../../services/eui-i18n';
import type { PanelModeType, PanelPosition } from '../../-private/resizable.ts';
import type EuiResizableContainer from '../eui-resizable-container.gts';
import type { EuiCss } from '../../utils/eui/styles.ts';
import type { EuiPanelSignature } from '../eui-panel';

type Mode = PanelModeType | [PanelModeType, { position?: 'top' | 'middle' | 'bottom' | 'left' | 'right' }];

/**
 * A panel of an `EuiResizableContainer` (yielded as `Panel`), sized in
 * percent of the container.
 */
export interface EuiResizablePanelSignature {
  Element: HTMLDivElement;
  Args: {
    /** Id of the panel, e.g. to toggle it. Defaults to a random id. */
    id?: string;
    /** Starting size in percent of the container. */
    initialSize?: number;
    /** Controlled size in percent (update it from `@onPanelWidthChange`). */
    size?: number;
    /** Smallest size, e.g. `'20%'` or `'200px'`. Defaults to `'0px'`. */
    minSize?: string;
    /** Scrolls its content when it overflows. Defaults to `true`. */
    scrollable?: boolean;
    /**
     * `'collapsible'` (with a toggle button, next to a `'main'` panel),
     * `'main'`, or `['collapsible', { position }]` to place the toggle
     * (`'top'`, `'middle'`, `'bottom'`).
     */
    mode?: Mode;
    /** Padding inside the panel: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'m'`. */
    paddingSize?: 'none' | 's' | 'm' | 'l';
    /** Padding around the panel: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'none'`. */
    wrapperPadding?: 'none' | 's' | 'm' | 'l';
    /** Background, any `EuiPanel` color. Defaults to `'transparent'`. */
    color?: EuiPanelSignature['Args']['color'];
    /** Adds a shadow (when there is no border). Defaults to `false`. */
    hasShadow?: boolean;
    /** Adds a border, like `EuiPanel`'s (whose own default is `true`). Defaults to `false`. */
    hasBorder?: boolean;
    /** `'none'` or `'m'` rounded corners. Defaults to `'none'`. */
    borderRadius?: EuiPanelSignature['Args']['borderRadius'];
    /** @private The container, set by `EuiResizableContainer`. */
    container: EuiResizableContainer;
  };
  Blocks: {
    /** The panel's content. */
    default: [];
  };
}

export default class EuiResizablePanel extends Component<EuiResizablePanelSignature> {
  @service declare euiI18n: EuiI18n;

  ownId = `resizable-panel_${randomId()}`;
  element?: HTMLElement;
  // ids of the resize buttons before and after it
  resizerIds: [string, string] = ['', ''];

  get id(): string {
    return this.args.id ?? this.ownId;
  }

  get container(): EuiResizableContainer {
    return this.args.container;
  }

  get state() {
    return this.container.panels[this.id];
  }

  get modeType(): PanelModeType | undefined {
    const mode = this.args.mode;

    return Array.isArray(mode) ? mode[0] : mode;
  }

  get togglePosition(): 'top' | 'middle' | 'bottom' | 'left' | 'right' {
    const mode = this.args.mode;

    return (Array.isArray(mode) ? mode[1].position : undefined) ?? 'middle';
  }

  get isCollapsible(): boolean {
    return this.modeType === 'collapsible';
  }

  get isCollapsed(): boolean {
    return this.state?.isCollapsed ?? false;
  }

  get position(): PanelPosition {
    return this.state?.position ?? 'middle';
  }

  get size(): number {
    return this.args.size ?? this.state?.size ?? this.args.initialSize ?? 0;
  }

  get style() {
    const horizontal = this.container.isHorizontal;

    return cssStyle({
      width: horizontal ? `${this.size}%` : '100%',
      height: horizontal ? 'auto' : `${this.size}%`
    });
  }

  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = euiResizablePanelStyles;

    return `euiResizablePanel ${euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiResizablePanel,
      this.isCollapsed && styles.collapsed,
      { padding: euiPaddingSize(context.upstream, this.args.wrapperPadding ?? 'none') ?? undefined }
    )}`;
  }

  /** Composed into the content `EuiPanel`'s own class. */
  @cached
  get contentCss(): EuiCss {
    const styles = useEuiBorealisStyles(getEuiThemeContext(this), euiResizablePanelContentStyles);
    const axis = this.container.isHorizontal ? styles.horizontal : styles.vertical;

    return [
      styles.euiResizablePanel__content,
      this.args.scrollable !== false && styles.scrollable,
      this.isCollapsed && styles.collapsedChildren,
      this.isCollapsed && !this.isCollapsible && axis.collapsed,
      this.isCollapsible && axis.hasCollapsibleButton
    ];
  }

  /** Twice the content padding, the smallest the panel can get. */
  @cached
  get paddingSizes(): string {
    const padding = euiPaddingSize(getEuiThemeContext(this).upstream, this.args.paddingSize ?? 'm') ?? '0px';

    return `${parseFloat(padding) * 2}px`;
  }

  /** Which way a middle panel collapses: toward its main neighbour. */
  get direction(): 'left' | 'right' | null {
    if (this.position !== 'middle' || !(this.isCollapsible || this.isCollapsed)) return null;

    const panels = this.container.panels;
    const ids = Object.keys(panels);
    const index = ids.indexOf(this.id);
    const prev = panels[ids[index - 1] ?? ''];
    const next = panels[ids[index + 1] ?? ''];
    const prevMode = prev?.mode;
    const nextMode = next?.mode;

    if (prevMode === 'main') return 'right';
    if (nextMode === 'main') return 'left';
    if (prevMode && prevMode !== 'collapsible') return 'right';
    if (nextMode && nextMode !== 'collapsible') return 'left';
    if (prev && next) return prev.size > next.size ? 'right' : 'left';
    if (prev) return 'right';
    if (next) return 'left';

    return null;
  }

  get toggle(): { externalPosition: 'before' | 'after'; resizerId: string } | null {
    const canToggle = this.isCollapsible || this.modeType === 'custom' || this.modeType === undefined;
    const showsToggle = this.isCollapsible || this.isCollapsed;

    if (!canToggle || !showsToggle) return null;

    if (this.position === 'last' || (this.position === 'middle' && this.direction === 'right')) {
      return { externalPosition: 'before', resizerId: this.resizerIds[0] };
    }

    if (this.position === 'first' || (this.position === 'middle' && this.direction === 'left')) {
      return { externalPosition: 'after', resizerId: this.resizerIds[1] };
    }

    return null;
  }

  get hasVisibleToggle(): boolean {
    return (this.modeType !== 'main' && this.isCollapsed) || this.isCollapsible;
  }

  get toggleLabel(): string {
    return this.euiI18n.lookupToken('euiResizablePanel.toggleButtonAriaLabel', 'Press to toggle this panel');
  }

  resizer = (id: string) => this.container.resizers[id];

  @action
  onToggleClick(externalPosition: 'before' | 'after', event: MouseEvent): void {
    this.container.onPanelToggle(this.id, { direction: externalPosition === 'before' ? 'right' : 'left' });

    // a mouse click should not leave the focus ring
    if (event.detail) (event.currentTarget as HTMLElement).blur();
  }

  register = modifier((element: HTMLElement, [size, minSize, mode]: [number | undefined, string | undefined, unknown]) => {
    this.element = element;
    void mode;

    const id = this.id;
    const initSize = size ?? this.args.initialSize ?? 0;
    const padding = this.paddingSizes;
    const horizontal = this.container.isHorizontal;

    schedule('afterRender', () => {
      this.resizerIds = [element.previousElementSibling?.id ?? '', element.nextElementSibling?.id ?? ''];

      const siblings = Array.from(element.parentElement?.children ?? []).filter((el) =>
        el.classList.contains('euiResizablePanel')
      );
      const position: PanelPosition =
        siblings[0] === element ? 'first' : siblings[siblings.length - 1] === element ? 'last' : 'middle';

      this.container.registerPanel({
        id,
        size: initSize,
        prevSize: initSize,
        getSizePx: () => {
          const rect = element.getBoundingClientRect();

          return horizontal ? rect.width : rect.height;
        },
        minSize: [minSize ?? '0px', padding],
        mode: this.modeType,
        isCollapsed: false,
        position
      });
    });

    return () => schedule('afterRender', () => this.container.deregisterPanel(id));
  });

  <template>
    <div
      id={{this.id}}
      class={{this.classes}}
      style={{this.style}}
      data-collapsed={{if this.isCollapsed "true"}}
      data-position={{this.position}}
      {{this.register @size @minSize @mode}}
    >
      {{#if this.hasVisibleToggle}}
        {{#let this.toggle as |toggle|}}
          {{#if (isBefore toggle)}}
            <EuiResizableCollapseButton
              aria-label={{this.toggleLabel}}
              @externalPosition="before"
              @direction={{if this.container.isHorizontal "horizontal" "vertical"}}
              @internalPosition={{this.togglePosition}}
              @isVisible={{resizerVisible (this.resizer (resizerIdOf toggle))}}
              @isCollapsed={{resizerDisabled (this.resizer (resizerIdOf toggle))}}
              {{on "click" (fnToggle this.onToggleClick "before")}}
            />
          {{/if}}
        {{/let}}
      {{/if}}
      <EuiPanel
        class="euiResizablePanel__content"
        @css={{this.contentCss}}
        @hasShadow={{if @hasShadow true false}}
        @hasBorder={{if @hasBorder true false}}
        @borderRadius={{if @borderRadius @borderRadius "none"}}
        @color={{if @color @color "transparent"}}
        @paddingSize={{if this.isCollapsed "none" (if @paddingSize @paddingSize "m")}}
        ...attributes
      >
        {{yield}}
      </EuiPanel>
      {{#if this.hasVisibleToggle}}
        {{#let this.toggle as |toggle|}}
          {{#if (isAfter toggle)}}
            <EuiResizableCollapseButton
              aria-label={{this.toggleLabel}}
              @externalPosition="after"
              @direction={{if this.container.isHorizontal "horizontal" "vertical"}}
              @internalPosition={{this.togglePosition}}
              @isVisible={{resizerVisible (this.resizer (resizerIdOf toggle))}}
              @isCollapsed={{resizerDisabled (this.resizer (resizerIdOf toggle))}}
              {{on "click" (fnToggle this.onToggleClick "after")}}
            />
          {{/if}}
        {{/let}}
      {{/if}}
    </div>
  </template>
}

type Toggle = EuiResizablePanel['toggle'];

function isBefore(toggle: Toggle): boolean {
  return toggle?.externalPosition === 'before';
}

function isAfter(toggle: Toggle): boolean {
  return toggle?.externalPosition === 'after';
}

function resizerIdOf(toggle: Toggle): string {
  return toggle?.resizerId ?? '';
}

function resizerVisible(resizer?: { isFocused: boolean; isDisabled: boolean }): boolean {
  return Boolean(resizer && (resizer.isFocused || resizer.isDisabled));
}

function resizerDisabled(resizer?: { isDisabled: boolean }): boolean {
  return Boolean(resizer?.isDisabled);
}

function fnToggle(
  handler: (position: 'before' | 'after', event: MouseEvent) => void,
  position: 'before' | 'after'
): (event: MouseEvent) => void {
  return (event) => handler(position, event);
}


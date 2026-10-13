import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass } from '../utils/eui/styles.ts';
import {
  EUI_BASIC_TABLE_PANEL_CLASS_NAME,
  euiBasicTablePanelStyles
} from '../utils/eui/styles.generated.ts';

import type { EuiCss, EuiCssFunction } from '../utils/eui/styles.ts';

/** What {@link useEuiBasicTablePanelProps} returns. */
export interface EuiBasicTablePanelProps {
  /** The panel styles: a theme function for any component's `@css`. */
  css: EuiCssFunction;
  /** `'euiBasicTablePanel'`: lets a panelled table join the panels above it. */
  className: typeof EUI_BASIC_TABLE_PANEL_CLASS_NAME;
}

const PANEL_PROPS: EuiBasicTablePanelProps = {
  css: euiBasicTablePanelStyles as EuiCssFunction,
  className: EUI_BASIC_TABLE_PANEL_CLASS_NAME
};

/**
 * Upstream's `useEuiBasicTablePanelProps` hook: the styles and class name
 * of a panel attached above a panelled `EuiBasicTable`/`EuiInMemoryTable`
 * (toolbars and other supporting content). Pass `css` to a component's
 * `@css` and `className` to its `class`, or render an
 * `EuiBasicTablePanel`.
 */
export function useEuiBasicTablePanelProps(): EuiBasicTablePanelProps {
  return PANEL_PROPS;
}

/**
 * A `<div>` styled with `useEuiBasicTablePanelProps()`: a supporting
 * panel for a panelled `EuiBasicTable` or `EuiInMemoryTable`, e.g. in the
 * in-memory table's `<:childrenBetween>` block. Consecutive panels join,
 * and the table below loses its top radius. Ember convenience over
 * upstream's hook.
 */
export interface EuiBasicTablePanelSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Extra styles composed last into the panel's class (like upstream's
     * `css` prop), e.g. padding.
     */
    css?: EuiCss;
  };
  Blocks: {
    /** The panel's content. */
    default: [];
  };
}

export default class EuiBasicTablePanel extends Component<EuiBasicTablePanelSignature> {
  @cached
  get classes(): string {
    return euiClass(getEuiThemeContext(this), PANEL_PROPS.css, this.args.css);
  }

  <template>
    <div class="{{PANEL_PROPS.className}} {{this.classes}}" ...attributes>
      {{yield}}
    </div>
  </template>
}

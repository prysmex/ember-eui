import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import {
  euiResizableCollapseButtonStyles,
  euiScreenReaderOnlyStyles
} from '../../utils/eui/styles.generated.ts';
import EuiButtonIcon from '../eui-button-icon.gts';

import type { EuiCss } from '../../utils/eui/styles.ts';

type InternalPosition = 'top' | 'middle' | 'bottom' | 'left' | 'right';

interface CollapseButtonSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    externalPosition: 'before' | 'after';
    internalPosition?: InternalPosition;
    direction: 'horizontal' | 'vertical';
    isVisible?: boolean;
    isCollapsed?: boolean;
  };
}

/**
 * Upstream uses the `transition*In/Out` icons, which the Ember icon set
 * does not include yet; the menu arrows point the same ways.
 */
function icon(externalPosition: string, direction: string, isCollapsed?: boolean): string {
  const horizontal = direction === 'horizontal';

  if (externalPosition === 'before') {
    return isCollapsed ? (horizontal ? 'menuLeft' : 'menuUp') : horizontal ? 'menuRight' : 'menuDown';
  }

  return isCollapsed ? (horizontal ? 'menuRight' : 'menuDown') : horizontal ? 'menuLeft' : 'menuUp';
}

/**
 * @private The button collapsing or expanding a resizable panel: an empty
 * text `EuiButtonIcon`, styled through its `@css`. While the panel is open
 * it floats over the edge (shown when its resizer has focus, or while it
 * has focus itself); a collapsed panel is all button.
 */
export default class EuiResizableCollapseButton extends Component<CollapseButtonSignature> {
  @cached
  get css(): EuiCss {
    const styles = useEuiBorealisStyles(getEuiThemeContext(this), euiResizableCollapseButtonStyles);
    const { direction, externalPosition, isCollapsed, isVisible } = this.args;
    const internalPosition = this.args.internalPosition ?? 'middle';

    return [
      styles.euiResizableCollapseButton,
      !isCollapsed && !isVisible && euiScreenReaderOnlyStyles['euiScreenReaderOnly-showOnFocus'],
      ...(isCollapsed
        ? [
            styles.collapsed.collapsed,
            styles.collapsed[direction],
            styles.collapsed[`${direction}Positions`][internalPosition]
          ]
        : [
            styles.collapsible.collapsible,
            styles.collapsible[direction][externalPosition],
            styles.collapsible[direction][internalPosition]
          ])
    ];
  }

  get iconType(): string {
    return icon(this.args.externalPosition, this.args.direction, this.args.isCollapsed);
  }

  <template>
    <EuiButtonIcon
      class="euiResizableCollapseButton"
      @display="empty"
      @color="text"
      @iconType={{this.iconType}}
      @css={{this.css}}
      ...attributes
    />
  </template>
}

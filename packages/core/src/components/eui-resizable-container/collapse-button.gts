import EuiButtonIcon from '../eui-button-icon.gts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

interface CollapseButtonSignature {
  Element: HTMLButtonElement | HTMLAnchorElement;
  Args: {
    externalPosition: 'before' | 'after';
    internalPosition?: 'top' | 'middle' | 'bottom' | 'left' | 'right';
    direction: 'horizontal' | 'vertical';
    isVisible?: boolean;
    isCollapsed?: boolean;
  };
}

function icon(externalPosition: string, direction: string, isCollapsed?: boolean): string {
  const horizontal = direction === 'horizontal';

  if (externalPosition === 'before') {
    return isCollapsed ? (horizontal ? 'menuLeft' : 'menuUp') : horizontal ? 'menuRight' : 'menuDown';
  }

  return isCollapsed ? (horizontal ? 'menuRight' : 'menuDown') : horizontal ? 'menuLeft' : 'menuUp';
}

function classes(
  direction: string,
  externalPosition: string,
  internalPosition = 'middle',
  isVisible?: boolean,
  isCollapsed?: boolean
): string {
  return [
    'euiResizableToggleButton',
    `euiResizableToggleButton--${direction}`,
    `euiResizableToggleButton--${externalPosition}`,
    `euiResizableToggleButton--${internalPosition}`,
    isVisible && 'euiResizableToggleButton-isVisible',
    isCollapsed && 'euiResizableToggleButton-isCollapsed'
  ]
    .filter(Boolean)
    .join(' ');
}

/** @private The button collapsing or expanding a resizable panel. */
const EuiResizableCollapseButton: TemplateOnlyComponent<CollapseButtonSignature> = <template>
  <EuiButtonIcon
    class={{classes @direction @externalPosition @internalPosition @isVisible @isCollapsed}}
    @display={{if @isCollapsed "empty" "fill"}}
    @color={{if @isCollapsed "text" "ghost"}}
    @iconType={{icon @externalPosition @direction @isCollapsed}}
    ...attributes
  />
</template>;

export default EuiResizableCollapseButton;

import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import EuiContextMenuItem from '../components/eui-context-menu-item.gts';
import EuiHorizontalRule from '../components/eui-horizontal-rule.gts';
import spreadAttributes from './eui-spread-attributes.ts';

import type { EuiContextMenuPanelItem } from '../components/eui-context-menu.gts';
import type { TOC } from '@ember/component/template-only';

const SEPARATOR_ARGS = ['isSeparator', 'key', 'margin', 'size'] as const;

/** Item keys that are `EuiContextMenuItem` args; the rest become attributes (upstream `...rest`). */
const ITEM_ARGS = [
  'isSeparator',
  'key',
  'name',
  'icon',
  'panel',
  'onClick',
  'href',
  'target',
  'rel',
  'external',
  'disabled',
  'hasAriaDisabled',
  'layoutAlign',
  'color',
  'toolTipContent',
  'toolTipTitle',
  'toolTipProps',
  'size'
] as const;

/**
 * @private One entry of a context menu panel's `items`: custom content, a
 * separator or an `EuiContextMenuItem` (`role="menuitem"`, as upstream
 * clones the items of the `items` API). Shared by EuiContextMenu and
 * EuiContextMenuPanel.
 */
const EuiContextMenuEntry: TOC<{
  Args: {
    /** Loosely typed: the template reads the fields of every item kind. */
    item: any;
    index: number;
    onItemClick: (
      item: EuiContextMenuPanelItem,
      index: number,
      event: MouseEvent
    ) => void;
  };
}> = <template>
  {{#if @item.renderItem}}
    <@item.renderItem />
  {{else if @item.isSeparator}}
    <EuiHorizontalRule
      @margin={{if @item.margin @item.margin "xs"}}
      @size={{@item.size}}
      @css={{@item.css}}
      class={{@item.className}}
      role="separator"
      {{spreadAttributes @item SEPARATOR_ARGS}}
    />
  {{else}}
    <EuiContextMenuItem
      @icon={{@item.icon}}
      @hasPanel={{if @item.panel true false}}
      @href={{@item.href}}
      @target={{@item.target}}
      @rel={{@item.rel}}
      @external={{@item.external}}
      @disabled={{@item.disabled}}
      @hasAriaDisabled={{@item.hasAriaDisabled}}
      @layoutAlign={{@item.layoutAlign}}
      @color={{@item.color}}
      @toolTipContent={{@item.toolTipContent}}
      @toolTipTitle={{@item.toolTipTitle}}
      @toolTipProps={{@item.toolTipProps}}
      role="menuitem"
      {{spreadAttributes @item ITEM_ARGS}}
      {{on "click" (fn @onItemClick @item @index)}}
    >{{@item.name}}</EuiContextMenuItem>
  {{/if}}
</template>;

export default EuiContextMenuEntry;

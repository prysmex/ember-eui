import Component from '@glimmer/component';
import { on } from '@ember/modifier';

import { randomId } from '../../-private/random-id.ts';
import { callWithItemIfFunction } from '../../-private/basic-table.ts';
import EuiButtonEmpty from '../eui-button-empty.gts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiScreenReaderOnly from '../eui-screen-reader-only.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type { DefaultItemAction } from '../../-private/basic-table.ts';

/**
 * @private A row action of `EuiBasicTable` (upstream `DefaultItemAction`):
 * an icon button or a small empty button, with the description as tooltip.
 */
export interface DefaultItemActionSignature<T extends object> {
  Element: HTMLElement;
  Args: {
    action: DefaultItemAction<T>;
    enabled: boolean;
    item: T;
  };
}

export default class DefaultItemActionComponent<
  T extends object
> extends Component<DefaultItemActionSignature<T>> {
  ariaLabelId = randomId();

  get resolved() {
    const { action, item } = this.args;
    if (!action.onClick && !action.href) {
      throw new Error(`Cannot render item action [${String(action.name)}]. Missing required 'onClick' callback
      or 'href' string. If you want to provide a custom action control, make sure to define the 'component'`);
    }
    const call = callWithItemIfFunction(item);
    const icon = action.icon ? call(action.icon) : undefined;
    const name = call(action.name);
    const description = call(action.description);
    if (action.type === 'icon' && !icon) {
      throw new Error(`Cannot render item action [${String(action.name)}]. It is configured to render as an icon but no
      icon is provided. Make sure to set the 'icon' property of the action`);
    }
    return {
      color: action.color ? call(action.color) : 'text',
      icon,
      name,
      description,
      // Avoid screen-readers announcing the same text twice
      disableScreenReaderOutput: name === description,
      href: call(action.href),
      testSubj: call(action['data-test-subj'])
    };
  }

  onClick = (event: MouseEvent): void => {
    if (!this.args.action.onClick) return;
    this.args.action.onClick(this.args.item, event);
  };

  <template>
    {{#if (isIcon @action)}}
      <EuiToolTip
        @content={{this.resolved.description}}
        @disableScreenReaderOutput={{this.resolved.disableScreenReaderOutput}}
      >
        <EuiButtonIcon
          @isDisabled={{if @enabled false true}}
          @color={{this.resolved.color}}
          @iconType={{this.resolved.icon}}
          @href={{this.resolved.href}}
          @target={{@action.target}}
          aria-labelledby={{this.ariaLabelId}}
          data-test-subj={{this.resolved.testSubj}}
          {{on "click" this.onClick}}
          ...attributes
        />
      </EuiToolTip>
      {{! SR text outside the tooltip, like upstream }}
      <EuiScreenReaderOnly><span id={{this.ariaLabelId}}>{{this.resolved.name}}</span></EuiScreenReaderOnly>
    {{else}}
      <EuiToolTip
        @content={{this.resolved.description}}
        @disableScreenReaderOutput={{this.resolved.disableScreenReaderOutput}}
      >
        <EuiButtonEmpty
          @size="s"
          @isDisabled={{if @enabled false true}}
          @color={{this.resolved.color}}
          @iconType={{this.resolved.icon}}
          @href={{this.resolved.href}}
          @target={{@action.target}}
          @flush="right"
          data-test-subj={{this.resolved.testSubj}}
          {{on "click" this.onClick}}
          ...attributes
        >{{this.resolved.name}}</EuiButtonEmpty>
      </EuiToolTip>
    {{/if}}
  </template>
}

function isIcon(action: { type?: string }): boolean {
  return action.type === 'icon';
}

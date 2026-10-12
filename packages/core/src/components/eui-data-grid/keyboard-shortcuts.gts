import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { guidFor } from '@ember/object/internals';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiDataGridKeyboardShortcutsStyles } from '../../utils/eui/styles.generated.ts';
import EuiButtonIcon from '../eui-button-icon.gts';
import EuiDescriptionList from '../eui-description-list.gts';
import EuiDescriptionListDescription from '../eui-description-list-description.gts';
import EuiDescriptionListTitle from '../eui-description-list-title.gts';
import EuiPopover from '../eui-popover.gts';
import EuiPopoverTitle from '../eui-popover-title.gts';
import EuiText from '../eui-text.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type EuiI18n from '../../services/eui-i18n.ts';

interface Shortcut {
  keys: string[];
  description: string;
}

export interface EuiDataGridKeyboardShortcutsSignature {
  Args: Record<string, never>;
}

/** Toolbar keyboard shortcuts popover. */
export default class EuiDataGridKeyboardShortcuts extends Component<EuiDataGridKeyboardShortcutsSignature> {
  @service declare euiI18n: EuiI18n;

  @tracked isOpen = false;
  readonly titleId = `euiDataGridKeyboardShortcuts-${guidFor(this)}`;

  t = (token: string, fallback: string): string => this.euiI18n.lookupToken(token, fallback);

  @cached
  get textCss() {
    return useEuiBorealisStyles(getEuiThemeContext(this), euiDataGridKeyboardShortcutsStyles)
      .euiDataGrid__keyboardShortcuts;
  }

  get title(): string {
    return this.t('euiKeyboardShortcuts.title', 'Keyboard shortcuts');
  }

  get copyModifier(): string {
    const isMac =
      typeof navigator !== 'undefined' && /Mac|iP(hone|od|ad)/.test(navigator.platform);
    return isMac
      ? this.t('euiKeyboardShortcuts.cmd', 'Cmd')
      : this.t('euiKeyboardShortcuts.ctrl', 'Ctrl');
  }

  get shortcuts(): Shortcut[] {
    const t = this.t;
    const ctrl = t('euiKeyboardShortcuts.ctrl', 'Ctrl');
    const home = t('euiKeyboardShortcuts.homeTitle', 'Home');
    const end = t('euiKeyboardShortcuts.endTitle', 'End');
    return [
      { keys: [t('euiKeyboardShortcuts.upArrowTitle', 'Up arrow')], description: t('euiKeyboardShortcuts.upArrowDescription', 'Move one cell up') },
      { keys: [t('euiKeyboardShortcuts.downArrowTitle', 'Down arrow')], description: t('euiKeyboardShortcuts.downArrowDescription', 'Move one cell down') },
      { keys: [t('euiKeyboardShortcuts.rightArrowTitle', 'Right arrow')], description: t('euiKeyboardShortcuts.rightArrowDescription', 'Move one cell right') },
      { keys: [t('euiKeyboardShortcuts.leftArrowTitle', 'Left arrow')], description: t('euiKeyboardShortcuts.leftArrowDescription', 'Move one cell left') },
      { keys: [home], description: t('euiKeyboardShortcuts.homeDescription', 'Move to the first cell of the current row') },
      { keys: [end], description: t('euiKeyboardShortcuts.endDescription', 'Move to the last cell of the current row') },
      { keys: [ctrl, home], description: t('euiKeyboardShortcuts.ctrlHomeDescription', 'Move to the first cell of the current page') },
      { keys: [ctrl, end], description: t('euiKeyboardShortcuts.ctrlEndDescription', 'Move to the last cell of the current page') },
      { keys: [t('euiKeyboardShortcuts.pageUpTitle', 'Page Up')], description: t('euiKeyboardShortcuts.pageUpDescription', 'Go to the last row of the previous page') },
      { keys: [t('euiKeyboardShortcuts.pageDownTitle', 'Page Down')], description: t('euiKeyboardShortcuts.pageDownDescription', 'Go to the first row of the next page') },
      { keys: [t('euiKeyboardShortcuts.enterTitle', 'Enter')], description: t('euiKeyboardShortcuts.enterDescription', 'Open cell details and actions') },
      { keys: [t('euiKeyboardShortcuts.escapeTitle', 'Escape')], description: t('euiKeyboardShortcuts.escapeDescription', 'Close cell details and actions') },
      { keys: [this.copyModifier, t('euiKeyboardShortcuts.copyTitle', 'C')], description: t('euiKeyboardShortcuts.copyDescription', 'Copy the focused cell value') }
    ];
  }

  @action
  toggle(): void {
    this.isOpen = !this.isOpen;
  }

  @action
  close(): void {
    this.isOpen = false;
  }

  <template>
    <EuiPopover
      data-test-subj="dataGridKeyboardShortcutsPopover"
      @isOpen={{this.isOpen}}
      @closePopover={{this.close}}
      @anchorPosition="downRight"
      @panelPaddingSize="none"
    >
      <:button>
        <EuiToolTip @content={{this.title}} @disableScreenReaderOutput={{true}}>
          <EuiButtonIcon
            @size="xs"
            @iconType="keyboard"
            @color="text"
            data-test-subj="dataGridKeyboardShortcutsButton"
            aria-label={{this.title}}
            {{on "click" this.toggle}}
          />
        </EuiToolTip>
      </:button>
      <:content>
        <EuiPopoverTitle @paddingSize="s">
          <h2 id={{this.titleId}}>{{this.title}}</h2>
        </EuiPopoverTitle>
        <EuiText class="euiDataGrid__keyboardShortcuts" @css={{this.textCss}} @size="xs">
          <EuiDescriptionList
            aria-labelledby={{this.titleId}}
            @type="column"
            @columnWidths={{array "auto" "auto"}}
            @align="center"
            @compressed={{true}}
          >
            {{#each this.shortcuts as |shortcut|}}
              <EuiDescriptionListTitle>
                {{#each shortcut.keys as |key index|}}{{if index " "}}<kbd>{{key}}</kbd>{{/each}}
              </EuiDescriptionListTitle>
              <EuiDescriptionListDescription>{{shortcut.description}}</EuiDescriptionListDescription>
            {{/each}}
          </EuiDescriptionList>
        </EuiText>
      </:content>
    </EuiPopover>
  </template>
}

function array<T>(...items: T[]): T[] {
  return items;
}

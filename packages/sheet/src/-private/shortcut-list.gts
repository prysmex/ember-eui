/**
 * The shortcut list (V03 5.5): an `EuiModal` beside the grid, opened by
 * Ctrl/Cmd+/ on the grid, `api.showShortcuts()` or a block's
 * `showShortcuts()`. Portaled, so it carries the sheet's theme class
 * itself (as `record-shells.gts`). Escape or the close button closes it;
 * the modal's focus trap returns focus to where it was (the cell).
 */
import Component from '@glimmer/component';
import { guidFor } from '@ember/object/internals';

import EuiModal from '@ember-eui/core/components/eui-modal';
import EuiModalBody from '@ember-eui/core/components/eui-modal-body';
import EuiModalHeader from '@ember-eui/core/components/eui-modal-header';
import EuiModalHeaderTitle from '@ember-eui/core/components/eui-modal-header-title';

import { shortcutList } from './shortcuts.ts';

import type EuiSheet from '../components/eui-sheet.gts';
import type { ShortcutListSection } from './shortcuts.ts';

interface ShortcutListSignature {
  Args: { sheet: EuiSheet<any> };
}

export default class ShortcutList extends Component<ShortcutListSignature> {
  titleId = `${guidFor(this)}-title`;

  get sheet(): EuiSheet<any> {
    return this.args.sheet;
  }

  get sections(): ShortcutListSection[] {
    return shortcutList(this.sheet.keys.shortcutContext, this.sheet.messages);
  }

  get title(): string {
    return this.sheet.messages.shortcuts();
  }

  get closeLabel(): string {
    return this.sheet.messages.close();
  }

  get or(): string {
    return this.sheet.messages.shortcutOr();
  }

  close = (): void => this.sheet.keys.closeShortcuts();

  <template>
    <EuiModal
      @onClose={{this.close}}
      @closeButtonAriaLabel={{this.closeLabel}}
      class="euiSheetShortcuts {{this.sheet.themeClass}}"
      aria-labelledby={{this.titleId}}
      data-test-subj="euiSheetShortcuts"
    >
      <EuiModalHeader>
        <EuiModalHeaderTitle
          id={{this.titleId}}
        >{{this.title}}</EuiModalHeaderTitle>
      </EuiModalHeader>
      <EuiModalBody>
        {{! focusable, so the keyboard scrolls a list taller than the modal }}
        {{! template-lint-disable no-noninteractive-tabindex }}
        <div
          class="euiSheetShortcuts__list"
          role="region"
          tabindex="0"
          aria-labelledby={{this.titleId}}
          data-test-subj="euiSheetShortcutList"
        >
          {{#each this.sections as |section|}}
            <table class="euiSheetShortcuts__section">
              <caption
                class="euiSheetShortcuts__title"
              >{{section.title}}</caption>
              <tbody>
                {{#each section.rows as |row|}}
                  <tr data-test-subj="euiSheetShortcut">
                    <td class="euiSheetShortcuts__keys">
                      {{#each row.keys as |combo index|}}
                        {{#if index}}
                          <span class="euiSheetShortcuts__or">{{this.or}}</span>
                        {{/if}}
                        {{#each combo as |key position|}}
                          {{#if position}}+{{/if}}<kbd
                            class="euiSheetShortcuts__key"
                          >{{key}}</kbd>
                        {{/each}}
                      {{/each}}
                    </td>
                    <td
                      class="euiSheetShortcuts__text"
                      data-test-subj="euiSheetShortcutText"
                    >{{row.text}}</td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
          {{/each}}
        </div>
      </EuiModalBody>
    </EuiModal>
  </template>
}

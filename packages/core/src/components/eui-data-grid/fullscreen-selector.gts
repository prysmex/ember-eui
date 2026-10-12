import Component from '@glimmer/component';
import { on } from '@ember/modifier';
import { service } from '@ember/service';

import EuiButtonIcon from '../eui-button-icon.gts';
import EuiToolTip from '../eui-tool-tip.gts';

import type EuiI18n from '../../services/eui-i18n.ts';
import type EuiDataGrid from '../eui-data-grid.gts';

export interface EuiDataGridFullScreenSelectorSignature {
  Args: { grid: EuiDataGrid };
}

/** Toolbar button toggling fullscreen (Escape also exits). */
export default class EuiDataGridFullScreenSelector extends Component<EuiDataGridFullScreenSelectorSignature> {
  @service declare euiI18n: EuiI18n;

  get label(): string {
    return this.args.grid.isFullScreen
      ? this.euiI18n.lookupToken('euiFullscreenSelector.fullscreenButtonActive', 'Exit fullscreen')
      : this.euiI18n.lookupToken('euiFullscreenSelector.fullscreenButton', 'Enter fullscreen');
  }

  <template>
    <EuiToolTip>
      <:content>
        {{this.label}}{{#if @grid.isFullScreen}} (<kbd>esc</kbd>){{/if}}
      </:content>
      <:anchor>
        <EuiButtonIcon
          @size="xs"
          @iconType={{if @grid.isFullScreen "fullScreenExit" "fullScreen"}}
          @color="text"
          aria-pressed={{if @grid.isFullScreen "true" "false"}}
          data-test-subj="dataGridFullScreenButton"
          aria-label={{this.label}}
          {{on "click" @grid.toggleFullScreen}}
        />
      </:anchor>
    </EuiToolTip>
  </template>
}

import { isArray as isEmberArray } from '@ember/array';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import willDestroy from '@ember/render-modifiers/modifiers/will-destroy';
import { inject as service } from '@ember/service';
import { htmlSafe } from '@ember/template';
import { isEqual } from '@ember/utils';
import { EnsureSafeComponentHelper } from '@embroider/util';

//@ts-expect-error
import VerticalCollection from '@html-next/vertical-collection/components/vertical-collection/component';
import EmberPowerSelectOptions from 'ember-power-select/components/power-select/options';
import emberPowerSelectIsGroupHelper, {
  emberPowerSelectIsGroup
} from 'ember-power-select/helpers/ember-power-select-is-group';
import { and, eq, not } from 'ember-truth-helpers';

import EuiBadge from '../eui-badge.gts';
import EuiFlexGroup from '../eui-flex-group.gts';
import EuiFlexItem from '../eui-flex-item.gts';
import EuiLoadingSpinner from '../eui-loading-spinner.gts';
import EuiText from '../eui-text.gts';

import type EuiConfigService from '../../services/eui-config';


//This was extracted from ember-power-select v7.2.0, becuase it was removed in v8.0.0... or renamed to ember-power-select-
function emberPowerSelectIsSelected([option, selected]: [any, any]/* , hash*/): boolean {
  if (selected === undefined || selected === null) {
    return false;
  }

  if (isEmberArray(selected)) {
    for (let i = 0; i < selected.length; i++) {
      if (isEqual(selected[i], option)) {
        return true;
      }
    }

    return false;
  } else {
    return isEqual(option, selected);
  }
}


export default class EuiComboBoxOptionsComponent extends EmberPowerSelectOptions {
  @service declare euiConfig: EuiConfigService;
  _optionsCache: any[] = [];

  get flattedOptions() {
    if (this._optionsCache !== this.args.options) {
      this._optionsCache = this.args.options;

      return this.args.options?.reduce((acc, curr) => {
        if (emberPowerSelectIsGroup([curr])) {
          acc.push(curr, ...curr.options);
        } else {
          acc.push(curr);
        }

        return acc;
      }, []);
    }

    return this._optionsCache;
  }

  _optionFromIndex(index: string) {
    let parts = index.split('.');
    let option = this.flattedOptions.at?.(parseInt(parts[0]!, 10));

    for (let i = 1; i < parts.length; i++) {
      option = option.options[parseInt(parts[i]!, 10)];
    }

    return option;
  }

  get configRowHeight() {
    return (
      (this.euiConfig.getConfig('euiComboBoxOptionsHeight') as number) || 29
    );
  }

  get rowHeight() {
    //@ts-expect-error
    return this.args.rowHeight ?? this.configRowHeight;
  }

  get rowHeightString() {
    return htmlSafe(`height:${this.rowHeight}px;`);
  }

  <template>
    {{! @glint-nocheck: not typesafe yet }}
    {{#let (component (EnsureSafeComponentHelper @groupComponent)) as |Group|}}
      {{#if @select.loading}}
        <EuiText @size="xs" class="euiComboBoxOptionsList__empty">
          <EuiFlexGroup
            @gutterSize="s"
            @justifyContent="center"
            @responsive={{false}}
          >
            <EuiFlexItem @grow={{false}}>
              <EuiLoadingSpinner @size="m" />
            </EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              {{@loadingMessage}}
            </EuiFlexItem>
          </EuiFlexGroup>
        </EuiText>
      {{else}}
        {{! template-lint-disable }}
        <VerticalCollection
          @items={{this.flattedOptions}}
          @tagName="div"
          @estimateHeight={{this.rowHeight}}
          @staticHeight={{true}}
          @bufferSize={{3}}
          style="max-height: 200px; overflow-y: auto;"
          role="listbox"
          aria-controls="ember-power-select-trigger-{{@select.uniqueId}}"
          class={{@class}}
          {{didInsert this.addHandlers}}
          {{willDestroy this.removeHandlers}}
          ...attributes
          as |opt index|
        >
          {{! template-lint-enable }}
          {{#if (emberPowerSelectIsGroupHelper opt)}}
            <Group
              @group={{opt}}
              @select={{@select}}
              @extra={{@extra}}
              style={{this.rowHeightString}}
              data-option-index="{{index}}"
            />
          {{else}}
            <li
              style={{this.rowHeightString}}
              class="euiFilterSelectItem
                {{if
                  (eq opt @select.highlighted)
                  ' euiFilterSelectItem-isFocused'
                }}"
              aria-selected="{{emberPowerSelectIsSelected
                opt
                @select.selected
              }}"
              aria-disabled={{if opt.disabled "true"}}
              aria-current="{{eq opt @select.highlighted}}"
              data-option-index="{{index}}"
              role="option"
              tabindex={{if opt.disabled "-1" "0"}}
            >
              <span class="euiComboBoxOption__contentWrapper">
                <span class="euiComboBoxOption__content">
                  {{yield opt index @select}}
                </span>
                {{#if (and (eq opt @select.highlighted) (not opt.disabled))}}
                  <EuiBadge
                    class="euiComboBoxOption__enterBadge"
                    @color="hollow"
                    @iconType="returnKey"
                    aria-hidden="true"
                  />
                {{/if}}
              </span>
            </li>
          {{/if}}
        </VerticalCollection>
      {{/if}}
    {{/let}}
  </template>
}

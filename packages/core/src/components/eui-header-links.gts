import Component from '@glimmer/component';
import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiShowFor from './eui-show-for';
import EuiHideFor from './eui-hide-for';
import EuiPopover from './eui-popover';
import EuiButtonEmpty from './eui-button-empty';
import EuiIcon from './eui-icon';
import { on } from '@ember/modifier';
import set from 'ember-set-helper/helpers/set';

interface EuiHeaderLinksArgs {
  popoverBreakpoints?: string[];
}
export default class EuiHeaderLinksComponent extends Component<EuiHeaderLinksArgs> {
  get popoverBreakpoints() {
    return this.args.popoverBreakpoints || ['xs', 's'];
  }

  get hasMobileVersion() {
    return this.popoverBreakpoints?.length > 0;
  }

  <template>
    {{! @glint-nocheck: not typesafe yet }}
    <nav class="euiHeaderLinks">
      <EuiHideFor @sizes={{this.popoverBreakpoints}}>
        <div
          class={{classNames
            "euiHeaderLinks__list"
            componentName="EuiHeaderLinks"
            gutterSize=(argOrDefault @gutterSize "xs")
          }}
        >
          {{yield}}
        </div>
      </EuiHideFor>

      {{#if this.hasMobileVersion}}
        <EuiShowFor @sizes={{this.popoverBreakpoints}}>
          <EuiPopover
            @isOpen={{this.pop1}}
            @anchorPosition="downRight"
            @panelPaddingSize={{argOrDefault @panelPaddingSize "none"}}
            @closePopover={{set this "pop1" false}}
          >
            <:button>
              <EuiButtonEmpty
                @color="text"
                {{on "click" (set this "pop1" true)}}
              >
                <EuiIcon @type="apps" />
              </EuiButtonEmpty>
            </:button>
            <:content>
              <div
                class={{classNames
                  "euiHeaderLinks__mobileList"
                  componentName="EuiHeaderLinks"
                  mobileGutterSize=(argOrDefault @gutterSize "xs")
                }}
              >
                {{yield}}
              </div>
            </:content>
          </EuiPopover>
        </EuiShowFor>
      {{/if}}
    </nav>
  </template>
}

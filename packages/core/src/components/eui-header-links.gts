import Component from '@glimmer/component';
import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';
import EuiShowFor from '@ember-eui/core/components/eui-show-for';
import EuiHideFor from '@ember-eui/core/components/eui-hide-for';
import EuiPopover from '@ember-eui/core/components/eui-popover';
import EuiButtonEmpty from '@ember-eui/core/components/eui-button-empty';
import EuiIcon from '@ember-eui/core/components/eui-icon';
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

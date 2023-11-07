import Component from '@glimmer/component';
import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiShowFor from './eui-show-for.gts';
import EuiHideFor from './eui-hide-for.gts';
import type { EuiHideForSignature } from './eui-hide-for.gts';
import EuiPopover from './eui-popover.gts';
import type { EuiPopoverSignature } from './eui-popover.gts';
import EuiButtonEmpty from './eui-button-empty.gts';
import EuiIcon from './eui-icon.gts';
import { on } from '@ember/modifier';
import set from 'ember-set-helper/helpers/set';
import { gutterSizeMapping } from '../utils/css-mappings/eui-header-links';
import { tracked } from '@glimmer/tracking';

export interface EuiHeaderLinkSignature {
  Args: {
    popoverBreakpoints?: EuiHideForSignature['Args']['sizes'];
    gutterSize?: keyof typeof gutterSizeMapping;
    panelPaddingSize?: EuiPopoverSignature['Args']['panelPaddingSize'];
  };
  Blocks: {
    default: [];
  };
}

export default class EuiHeaderLinksComponent extends Component<EuiHeaderLinkSignature> {
  @tracked pop1 = false;

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

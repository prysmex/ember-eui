import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';

import type { EuiFlexGroupSignature } from './eui-flex-group.gts';
import type { EuiFlexItemSignature } from './eui-flex-item.gts';
import type { EuiTitleSignature } from './eui-title.gts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiDescribedFormGroupSignature {
  Element: HTMLDivElement;
  Args: {
    fullWidth?: boolean;
    gutterSize?: EuiFlexGroupSignature['Args']['gutterSize'];
    titleSize?: EuiTitleSignature['Args']['size'];
    titleTagName?: EuiTitleSignature['Args']['tagName'];
    fieldFlexItemProps?: {
      grow?: EuiFlexItemSignature['Args']['grow'];
    };
    descriptionFlexItemProps?: {
      grow?: EuiFlexItemSignature['Args']['grow'];
    };
  };
  Blocks: {
    default: [];
    title?: [];
    description?: [];
  };
}

const EuiDescribedFormGroup: TemplateOnlyComponent<EuiDescribedFormGroupSignature> =
  <template>
    <div
      role="group"
      class={{classNames
        "euiDescribedFormGroup"
        (if @fullWidth "euiDescribedFormGroup--fullWidth")
      }}
      ...attributes
    >
      <EuiFlexGroup @gutterSize={{argOrDefault @gutterSize "l"}}>
        <EuiFlexItem @grow={{@descriptionFlexItemProps.grow}}>
          <EuiTitle
            class="euiDescribedFormGroup__title"
            @size={{@titleSize}}
            @tagName={{@titleTagName}}
          >
            {{yield to="title"}}
          </EuiTitle>
          <EuiText
            class="euiDescribedFormGroup__description"
            @size="s"
            @color="subdued"
          >
            {{yield to="description"}}
          </EuiText>
        </EuiFlexItem>
        <EuiFlexItem
          class={{classNames
            "euiDescribedFormGroup__fields"
            componentName="EuiDescribedFormGroup"
            paddingSize=(argOrDefault @titleSize "xs")
          }}
          @grow={{@fieldFlexItemProps.grow}}
        >
          {{yield}}
        </EuiFlexItem>
      </EuiFlexGroup>
    </div>
  </template>;

export default EuiDescribedFormGroup;

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';

import type { EuiFlexGroupSignature } from './eui-flex-group';
import type { EuiFlexItemSignature } from './eui-flex-item';
import type { EuiTitleSignature } from './eui-title';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A section of a long form: a title and description on the left, its
 * fields on the right (stacked on small screens).
 */
export interface EuiDescribedFormGroupSignature {
  Element: HTMLDivElement;
  Args: {
    /** Lets the fields column grow to the container's width. */
    fullWidth?: boolean;
    /** Space between the description and the fields. Defaults to `'l'`. */
    gutterSize?: EuiFlexGroupSignature['Args']['gutterSize'];
    /**
     * Size of the title, any `EuiTitle` size; also aligns the fields with
     * it. Defaults to `'xs'`.
     */
    titleSize?: EuiTitleSignature['Args']['size'];
    /** Tag of the title, e.g. `'h3'`. */
    titleTagName?: EuiTitleSignature['Args']['tagName'];
    /** Props for the fields column: `{ grow, class }`. */
    fieldFlexItemProps?: {
      grow?: EuiFlexItemSignature['Args']['grow'];
      class?: string;
    };
    /** Props for the title and description column: `{ grow, class }`. */
    descriptionFlexItemProps?: {
      grow?: EuiFlexItemSignature['Args']['grow'];
      class?: string;
    };
  };
  Blocks: {
    /** The fields, usually `EuiFormRow`s. */
    default: [];
    /**
     * Title of the group (on the left), as text: it is rendered in an
     * `EuiTitle` whose tag is `@titleTagName`.
     */
    title?: [];
    /** Explanation under the title. */
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
        <EuiFlexItem
          @grow={{@descriptionFlexItemProps.grow}}
          class={{@descriptionFlexItemProps.class}}
        >
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
            @fieldFlexItemProps.class
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

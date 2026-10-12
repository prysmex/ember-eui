import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { modifier } from 'ember-modifier';

import { euiFormFullWidth } from '../-private/eui-form-context.ts';
import { randomId } from '../-private/random-id.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiDescribedFormGroupStyles } from '../utils/eui/styles.generated.ts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';

import type { EuiFlexGroupSignature } from './eui-flex-group';
import type { EuiFlexItemSignature } from './eui-flex-item';
import type { EuiTitleSignature } from './eui-title';

/** Width of the fields column relative to the description column. */
export type EuiDescribedFormGroupRatio = 'half' | 'third' | 'quarter';

const FIELD_GROW: Record<EuiDescribedFormGroupRatio, EuiFlexItemGrow> = {
  half: 1,
  third: 2,
  quarter: 3
};

type EuiFlexItemGrow = NonNullable<EuiFlexItemSignature['Args']['grow']>;

/**
 * Upstream names the group by its title unless the caller labels it. An
 * `aria-label` attribute (which Ember passes through `...attributes`) must
 * win, so drop the default `aria-labelledby` in that case.
 */
const preferAriaLabel = modifier<{
  Element: HTMLElement;
  Args: { Positional: [titleId: string | undefined] };
}>((element, [titleId]) => {
  if (
    titleId &&
    element.hasAttribute('aria-label') &&
    element.getAttribute('aria-labelledby') === titleId
  ) {
    element.removeAttribute('aria-labelledby');
  }
});

/**
 * A section of a long form: a title and description on the left, its
 * fields on the right (stacked on small screens).
 */
export interface EuiDescribedFormGroupSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Lets the group grow to the container's width instead of twice the
     * theme's form max width. Defaults to the enclosing EuiForm's
     * `@fullWidth`, else `false`.
     */
    fullWidth?: boolean;
    /** Space between the description and the fields. Defaults to `'l'`. */
    gutterSize?: EuiFlexGroupSignature['Args']['gutterSize'];
    /**
     * Width of the fields column relative to the description: `'half'`
     * (1:1), `'third'` (fields 2:1) or `'quarter'` (fields 3:1).
     * Defaults to `'half'`.
     */
    ratio?: EuiDescribedFormGroupRatio;
    /**
     * Size of the title, any `EuiTitle` size. Defaults to `'xs'`.
     */
    titleSize?: EuiTitleSignature['Args']['size'];
    /** Tag of the title, e.g. `'h3'`. Defaults to `'h2'`. */
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
     * `EuiTitle` whose tag is `@titleTagName`, and names the group
     * (`aria-labelledby`) unless the group has its own `aria-label` or
     * `aria-labelledby`.
     */
    title?: [];
    /** Explanation under the title. */
    description?: [];
  };
}

export default class EuiDescribedFormGroup extends Component<EuiDescribedFormGroupSignature> {
  readonly titleId = `euiDescribedFormGroupTitle-${randomId()}`;

  @cached
  get styles() {
    return useEuiBorealisStyles(
      getEuiThemeContext(this),
      euiDescribedFormGroupStyles
    );
  }

  @cached
  get classes(): string {
    const { styles } = this;
    return euiClass(
      getEuiThemeContext(this),
      styles.euiDescribedFormGroup,
      euiFormFullWidth(this, this.args.fullWidth)
        ? styles.fullWidth
        : styles.formWidth
    );
  }

  @cached
  get descriptionColumnClasses(): string {
    return euiClass(
      getEuiThemeContext(this),
      this.styles.euiDescribedFormGroup__descriptionColumn
    );
  }

  @cached
  get descriptionClasses(): string {
    return euiClass(
      getEuiThemeContext(this),
      this.styles.euiDescribedFormGroup__description
    );
  }

  @cached
  get fieldsClasses(): string {
    return euiClass(
      getEuiThemeContext(this),
      this.styles.euiDescribedFormGroup__fields
    );
  }

  get descriptionGrow(): EuiFlexItemGrow {
    return this.args.descriptionFlexItemProps?.grow ?? 1;
  }

  get fieldGrow(): EuiFlexItemGrow {
    return (
      this.args.fieldFlexItemProps?.grow ??
      FIELD_GROW[this.args.ratio ?? 'half'] ??
      1
    );
  }

  <template>
    {{! Upstream renders the flex group as the root; Ember keeps a wrapper
        div so the root stays an HTMLDivElement for ...attributes. }}
    <div
      role="group"
      aria-labelledby={{if (has-block "title") this.titleId}}
      class="euiDescribedFormGroup {{this.classes}}"
      ...attributes
      {{preferAriaLabel (if (has-block "title") this.titleId)}}
    >
      <EuiFlexGroup
        @alignItems="baseline"
        @gutterSize={{if @gutterSize @gutterSize "l"}}
      >
        <EuiFlexItem
          class="euiDescribedFormGroup__descriptionColumn
            {{this.descriptionColumnClasses}}
            {{@descriptionFlexItemProps.class}}"
          @grow={{this.descriptionGrow}}
        >
          {{#if (has-block "title")}}
            <EuiTitle
              id={{this.titleId}}
              class="euiDescribedFormGroup__title"
              @size={{if @titleSize @titleSize "xs"}}
              @tagName={{@titleTagName}}
            >
              {{yield to="title"}}
            </EuiTitle>
          {{/if}}
          {{#if (has-block "description")}}
            <EuiText
              class="euiDescribedFormGroup__description
                {{this.descriptionClasses}}"
              @size="s"
              @color="subdued"
            >
              {{yield to="description"}}
            </EuiText>
          {{/if}}
        </EuiFlexItem>
        <EuiFlexItem
          class="euiDescribedFormGroup__fields
            {{this.fieldsClasses}}
            {{@fieldFlexItemProps.class}}"
          @grow={{this.fieldGrow}}
        >
          {{yield}}
        </EuiFlexItem>
      </EuiFlexGroup>
    </div>
  </template>
}

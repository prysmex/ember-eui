import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiEmptyPromptStyles,
  euiFlexGroupStyles
} from '../utils/eui/styles.generated.ts';
import { euiFlexRootReset } from './eui-flex-item.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';
import EuiPanel from './eui-panel.gts';
import EuiSpacer from './eui-spacer.gts';
import EuiText from './eui-text.gts';
import EuiTitle from './eui-title.gts';

import type { EuiIconSignature } from './eui-icon';
import type { EuiPanelSignature } from './eui-panel';
import type { EuiTitleSignature } from './eui-title';
import type { ComponentLike } from '@glint/template';

type Layout = 'vertical' | 'horizontal';
type PaddingSize = 'none' | 's' | 'm' | 'l';

const FLEX_RESET = euiFlexRootReset(undefined);

/** Upstream's named EuiIcon colors (`icon/named_colors.js`). */
const NAMED_ICON_COLORS = [
  'default',
  'primary',
  'neutral',
  'success',
  'accent',
  'accentSecondary',
  'warning',
  'risk',
  'danger',
  'text',
  'subdued',
  'ghost',
  'inherit'
];

/**
 * A message filling an empty page or section: an icon, a title, some text
 * and actions, e.g. when a list has no items yet or a page failed to load.
 */
export interface EuiEmptyPromptSignature {
  Element: EuiPanelSignature['Element'];
  Args: {
    /**
     * `'vertical'` centers everything in a column; `'horizontal'` puts the
     * icon beside the text on large screens (it stacks below the `l`
     * breakpoint). Defaults to `'vertical'`.
     */
    layout?: Layout;
    /** Padding around the content: `'none'`, `'s'`, `'m'` or `'l'`. Defaults to `'l'`. */
    paddingSize?: PaddingSize;
    /**
     * Background, any `EuiPanel` color (`'plain'`, `'subdued'`, `'danger'`,
     * …). Defaults to `'transparent'`.
     */
    color?: EuiPanelSignature['Args']['color'];
    /** Adds a border around the prompt. Defaults to `true` for `'plain'`, `false` otherwise. */
    hasBorder?: boolean;
    /** Large icon above the title, e.g. `'magnify'` or `'logoKibana'`. */
    iconType?: EuiIconSignature['Args']['type'];
    /**
     * Color of the icon. Defaults to `@color` when it is a named icon color
     * (e.g. `'danger'`), or `'subdued'`.
     */
    iconColor?: EuiIconSignature['Args']['color'];
    /** Title, e.g. "No dashboards yet". */
    title?: string;
    /** Size of the title, any `EuiTitle` size. Defaults to `'m'`. */
    titleSize?: EuiTitleSignature['Args']['size'];
    /** Text explaining the situation and what to do. */
    body?: string;
    /**
     * Components rendered as the prompt's actions (e.g. a primary
     * `EuiButton` and an `EuiButtonEmpty`), laid out in a column (vertical)
     * or row (horizontal). Use the `<:content>` block for full control.
     */
    actions?: ComponentLike[];
    /** Text in a footer, e.g. a link to the docs. Use the `<:footer>` block for markup. */
    footer?: string;
  };
  Blocks: {
    /** Custom content instead of the `@iconType` icon, e.g. an `EuiImage`. */
    icon?: [];
    /** Replaces the title, body and actions with your own content. */
    content?: [];
    /** The footer, instead of `@footer`. */
    footer?: [];
  };
}

/** Native Ember empty prompt on the upstream EUI 123 / Borealis factories. */
export default class EuiEmptyPrompt extends Component<EuiEmptyPromptSignature> {
  @cached
  get context() {
    return getEuiThemeContext(this);
  }

  @cached
  get styles() {
    return useEuiBorealisStyles(this.context, euiEmptyPromptStyles);
  }

  get layout(): Layout {
    return this.args.layout === 'horizontal' ? 'horizontal' : 'vertical';
  }

  get paddingSize(): PaddingSize {
    return this.args.paddingSize ?? 'l';
  }

  get color(): string {
    return this.args.color ?? 'transparent';
  }

  get panelColor(): EuiPanelSignature['Args']['color'] {
    return this.color as EuiPanelSignature['Args']['color'];
  }

  get hasBorder(): boolean {
    return this.args.hasBorder ?? this.color === 'plain';
  }

  /** Upstream: an EuiPanel with the prompt's styles as its `css`. */
  @cached
  get panelCss(): EuiCss {
    return [this.styles.euiEmptyPrompt, this.styles[this.layout]];
  }

  @cached
  get mainClass() {
    const main = this.styles.main;
    return euiClass(
      this.context,
      main.euiEmptyPrompt__main,
      main[this.layout],
      main[this.paddingSize],
      this.layout === 'horizontal' && main.horizontalPadding[this.paddingSize]
    );
  }

  @cached
  get iconClass() {
    const icon = this.styles.icon;
    return euiClass(this.context, icon.euiEmptyPrompt__icon, icon[this.layout]);
  }

  @cached
  get contentClass() {
    const content = this.styles.content;
    return euiClass(
      this.context,
      content.euiEmptyPrompt__content,
      content[this.layout]
    );
  }

  /** Upstream's EuiFlexGroup (gutter m, centered, column/row) plus the prompt's actions `css`, as one class. */
  @cached
  get actionsClass() {
    const flex = useEuiBorealisStyles(this.context, euiFlexGroupStyles);
    const actions = this.styles.actions;
    const vertical = this.layout === 'vertical';
    return euiClass(
      this.context,
      FLEX_RESET,
      flex.euiFlexGroup,
      vertical ? undefined : flex.responsive,
      flex.gutterSizes.m,
      flex.justifyContent.center,
      flex.alignItems.center,
      flex.direction[vertical ? 'column' : 'row'],
      actions.euiEmptyPrompt__actions,
      actions[this.layout]
    );
  }

  @cached
  get footerClass() {
    const footer = this.styles.footer as Record<string, unknown>;
    return euiClass(
      this.context,
      this.styles.footer.euiEmptyPrompt__footer,
      footer[this.paddingSize] as never,
      footer[this.color] as never,
      this.color === 'transparent' &&
        !this.hasBorder &&
        this.styles.footer.roundedBorders
    );
  }

  get iconColor(): string {
    if (this.args.iconColor) return this.args.iconColor;
    return NAMED_ICON_COLORS.includes(this.color) ? this.color : 'subdued';
  }

  get hasActions(): boolean {
    return Boolean(this.args.actions?.length);
  }

  <template>
    <EuiPanel
      class="euiEmptyPrompt"
      @color={{this.panelColor}}
      @hasBorder={{this.hasBorder}}
      @hasShadow={{false}}
      @paddingSize="none"
      @borderRadius="m"
      @grow={{false}}
      @css={{this.panelCss}}
      ...attributes
    >
      <div class="euiEmptyPrompt__main {{this.mainClass}}">
        {{#if (has-block "icon")}}
          <div class="euiEmptyPrompt__icon {{this.iconClass}}">{{yield
              to="icon"
            }}</div>
        {{else if @iconType}}
          <div class="euiEmptyPrompt__icon {{this.iconClass}}">
            <EuiIcon
              @type={{@iconType}}
              @size="xxl"
              @color={{this.iconColor}}
            />
          </div>
        {{/if}}
        <div class="euiEmptyPrompt__content {{this.contentClass}}">
          {{#if (has-block "content")}}
            {{yield to="content"}}
          {{else}}
            {{#if @title}}
              <EuiTitle @size={{if @titleSize @titleSize "m"}}>{{@title}}</EuiTitle>
            {{/if}}
            {{#if @body}}
              {{#if @title}}
                <EuiSpacer @size="s" />
              {{/if}}
              <EuiText @color="subdued">{{@body}}</EuiText>
            {{/if}}
            {{#if this.hasActions}}
              {{#if @body}}
                <EuiSpacer @size="l" />
              {{else if @title}}
                <EuiSpacer @size="l" />
              {{/if}}
              <div class="euiFlexGroup euiEmptyPrompt__actions {{this.actionsClass}}">
                {{#each @actions as |Action|}}
                  <EuiFlexItem @grow={{false}}>
                    <Action />
                  </EuiFlexItem>
                {{/each}}
              </div>
            {{/if}}
          {{/if}}
        </div>
      </div>
      {{#if (has-block "footer")}}
        <div class="euiEmptyPrompt__footer {{this.footerClass}}">
          {{yield to="footer"}}
        </div>
      {{else if @footer}}
        <div class="euiEmptyPrompt__footer {{this.footerClass}}">
          {{@footer}}
        </div>
      {{/if}}
    </EuiPanel>
  </template>
}

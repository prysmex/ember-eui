import Component from '@glimmer/component';

import argOrDefault from '../../helpers/arg-or-default.ts';
import EuiEmptyPrompt from '../eui-empty-prompt.gts';
import EuiPageSection from '../eui-page-section.gts';

import type {
  EuiPagePaddingSize,
  EuiPageRestrictWidth
} from '../../utils/eui/page-layout.ts';
import type { EuiEmptyPromptSignature } from '../eui-empty-prompt';
import type {
  EuiPageSectionAlignment,
  EuiPageSectionColor
} from '../eui-page-section';

type PromptArgs = EuiEmptyPromptSignature['Args'];
type PromptColor = NonNullable<PromptArgs['color']>;

/**
 * `T.EmptyPrompt` of `EuiPageTemplate` (upstream
 * `EuiPageTemplate.EmptyPrompt`): an `EuiEmptyPrompt` centered in a growing
 * `EuiPageSection`. The default block is the prompt's body.
 */
export interface EuiPageTemplateEmptyPromptSignature {
  Element: EuiEmptyPromptSignature['Element'];
  Args: {
    /**
     * Shows the prompt as a panel on a plain section: the prompt is
     * `'subdued'` unless `@color` says otherwise. The template sets it
     * when its content is panelled (e.g. with a sidebar).
     */
    panelled?: boolean;
    /**
     * Color of the prompt (any `EuiEmptyPrompt` color). Defaults to
     * `'subdued'` when panelled, `'plain'` otherwise.
     */
    color?: PromptColor;
    /**
     * Padding of the section and the prompt: `'none'`, `'xs'`, `'s'`,
     * `'m'`, `'l'` or `'xl'`. Defaults to `'l'`.
     */
    paddingSize?: EuiPagePaddingSize;
    /** Grows the section to fill the page's height. Defaults to `true`. */
    grow?: boolean;
    /**
     * Max width of the section's content: `true` for EUI's default
     * (1200px), a number in px or any CSS width. Defaults to `false`.
     */
    restrictWidth?: EuiPageRestrictWidth;
    /**
     * Alignment of the prompt in the section: `'top'`, `'center'` or
     * `'horizontalCenter'`. Defaults to `'center'`.
     */
    alignment?: EuiPageSectionAlignment;
    /** `'vertical'` or `'horizontal'`, see `EuiEmptyPrompt`. */
    layout?: PromptArgs['layout'];
    /** Large icon above the title. */
    iconType?: PromptArgs['iconType'];
    /** Color of the icon. */
    iconColor?: PromptArgs['iconColor'];
    /** Title text; use the `<:title>` block for a heading. */
    title?: PromptArgs['title'];
    /** Size of the title. Defaults to `'m'`. */
    titleSize?: PromptArgs['titleSize'];
    /** Body text, when there is no default block. */
    body?: PromptArgs['body'];
    /** Action components, see `EuiEmptyPrompt`. */
    actions?: PromptArgs['actions'];
    /** Footer text; use the `<:footer>` block for markup. */
    footer?: PromptArgs['footer'];
    /** Adds a border. Defaults to `true` for a `'plain'` prompt. */
    hasBorder?: PromptArgs['hasBorder'];
  };
  Blocks: {
    /** The prompt's body (upstream's `children`). */
    default: [];
    /** Custom content instead of the `@iconType` icon. */
    icon: [];
    /** The title, inside an `EuiTitle`, e.g. `<h2>No spice</h2>`. */
    title: [];
    /** Actions; wrap each in the yielded item, see `EuiEmptyPrompt`. */
    actions: NonNullable<EuiEmptyPromptSignature['Blocks']['actions']>;
    /** The footer, e.g. a link or a button. */
    footer: [];
  };
}

/** Upstream `_EuiPageEmptyPrompt` (page_template/empty_prompt). */
export default class EuiPageTemplateEmptyPrompt extends Component<EuiPageTemplateEmptyPromptSignature> {
  /**
   * Upstream: a panelled prompt needs either the section or the prompt to
   * be plain. An undefined color makes the prompt subdued; any other color
   * than plain stays on the prompt. Otherwise the section is transparent.
   */
  get colors(): { section: EuiPageSectionColor; prompt: PromptColor } {
    const { panelled, color } = this.args;

    if (panelled && color === undefined) {
      return { section: 'plain', prompt: 'subdued' };
    }

    if (panelled && color !== 'plain') {
      return { section: 'plain', prompt: color! };
    }

    return { section: 'transparent', prompt: color ?? 'plain' };
  }

  get paddingSize(): EuiPagePaddingSize {
    return this.args.paddingSize ?? 'l';
  }

  /** Upstream passes the section's size on; `xs`/`xl` add no prompt padding. */
  get promptPaddingSize() {
    return this.paddingSize as PromptArgs['paddingSize'];
  }

  <template>
    <EuiPageSection
      @paddingSize={{this.paddingSize}}
      @color={{this.colors.section}}
      @grow={{argOrDefault @grow true}}
      @restrictWidth={{argOrDefault @restrictWidth false}}
      @alignment={{argOrDefault @alignment "center"}}
    >
      <EuiEmptyPrompt
        @paddingSize={{this.promptPaddingSize}}
        @color={{this.colors.prompt}}
        @layout={{@layout}}
        @iconType={{@iconType}}
        @iconColor={{@iconColor}}
        @title={{@title}}
        @titleSize={{@titleSize}}
        @body={{@body}}
        @actions={{@actions}}
        @footer={{@footer}}
        @hasBorder={{@hasBorder}}
        @hasIconBlock={{has-block "icon"}}
        @hasTitleBlock={{has-block "title"}}
        @hasBodyBlock={{has-block "default"}}
        @hasActionsBlock={{has-block "actions"}}
        @hasFooterBlock={{has-block "footer"}}
        ...attributes
      >
        <:icon>{{yield to="icon"}}</:icon>
        <:title>{{yield to="title"}}</:title>
        <:body>{{yield}}</:body>
        <:actions as |Item|>{{yield Item to="actions"}}</:actions>
        <:footer>{{yield to="footer"}}</:footer>
      </EuiEmptyPrompt>
    </EuiPageSection>
  </template>
}

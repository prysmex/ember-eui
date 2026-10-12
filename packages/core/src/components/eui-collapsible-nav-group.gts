import Component from '@glimmer/component';
import { concat } from '@ember/helper';

import { and, eq } from 'ember-truth-helpers';

import randomId from '../-private/random-id.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import type { EuiCss } from '../utils/eui/styles.ts';
import {
  euiCollapsibleNavGroupStyles,
  euiTitleStyles
} from '../utils/eui/styles.generated.ts';
import EuiAccordion from './eui-accordion.gts';
import EuiEmotionProvider from './eui-emotion-provider.gts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';

import type { EuiThemeContext } from '../utils/emotion/context.ts';
import type { EuiAccordionSignature } from './eui-accordion';
import type { EuiIconSignature } from './eui-icon';
import type { EuiTitleSignature } from './eui-title';

export type EuiCollapsibleNavGroupBackground = 'none' | 'light' | 'dark';

export interface EuiCollapsibleNavGroupSignature {
  Element: EuiAccordionSignature['Element'];
  Args: {
    /** Id of the group. Defaults to a random id. */
    id?: string;
    /** Tag of the title, e.g. `'h2'` or `'div'`. Defaults to `'h3'`. */
    titleElement?: string;
    /**
     * Makes the group an accordion that opens and closes from its title
     * (needs a `<:title>` block).
     */
    isCollapsible?: boolean;
    /** Whether a collapsible group starts open. Defaults to `true`. */
    initialIsOpen?: boolean;
    /** Icon before the title; anything `EuiIcon`'s `@type` accepts. */
    iconType?: EuiIconSignature['Args']['type'];
    /** Size of the icon. Defaults to `'l'`. */
    iconSize?: EuiIconSignature['Args']['size'];
    /** Same as `@titleElement`, limited to `EuiTitle`'s tags. Defaults to `'h3'`. */
    titleTagName?: EuiTitleSignature['Args']['tagName'];
    /** Size of the title, any `EuiTitle` size. Defaults to `'xxs'`. */
    titleSize?: EuiTitleSignature['Args']['size'];
    /**
     * Background of the group: `'none'`, `'light'` or `'dark'`. A dark
     * group renders its content in dark mode (a nested dark provider), as
     * upstream. Defaults to `'none'`.
     */
    background?: EuiCollapsibleNavGroupBackground | (string & {});
  };
  Blocks: {
    /** Unused, use `<:title>` and `<:content>`. */
    default: [];
    /** The group's title; without it the group has no heading. */
    title: [];
    /** The group's links, e.g. an `EuiListGroup`. */
    content: [];
  };
}

/**
 * Upstream `EuiCollapsibleNavGroup` (`euiCollapsibleNavGroupStyles`). Like
 * upstream, a `'dark'` group sits in a dark theme provider whose paragraph
 * color goes on the group itself (no wrapper element).
 */
export default class EuiCollapsibleNavGroup extends Component<EuiCollapsibleNavGroupSignature> {
  get background(): EuiCollapsibleNavGroupBackground {
    const { background } = this.args;
    return background === 'light' || background === 'dark'
      ? (background as EuiCollapsibleNavGroupBackground)
      : 'none';
  }

  get colorMode() {
    return this.background === 'dark' ? 'dark' : undefined;
  }

  get titleElement() {
    return this.args.titleElement ?? this.args.titleTagName ?? 'h3';
  }

  /**
   * Classes from the group's own theme context (dark for a dark group).
   * Called from the template, so Glimmer only re-runs it when the context
   * or the args it reads change.
   */
  classesFor = (context: EuiThemeContext) => {
    const styles = useEuiBorealisStyles(context, euiCollapsibleNavGroupStyles);
    const title = useEuiBorealisStyles(context, euiTitleStyles);
    const { childrenWrapper } = styles;
    // Upstream's `css` on EuiAccordion (or the plain div).
    const rootCss: EuiCss = [
      { boxSizing: 'border-box' },
      styles.euiCollapsibleNavGroup,
      this.args.isCollapsible ? styles.isCollapsible : styles.notCollapsible,
      styles[this.background],
      // Upstream's dark provider clones its paragraph color onto the group.
      this.background === 'dark' && {
        color: context.upstream.euiTheme.colors.textParagraph
      }
    ];
    return {
      rootCss,
      root: euiClass(context, rootCss),
      children: euiClass(
        context,
        { boxSizing: 'border-box' },
        childrenWrapper.euiCollapsibleNavGroup__children
      ),
      childrenWithHeading: euiClass(
        context,
        { boxSizing: 'border-box' },
        childrenWrapper.euiCollapsibleNavGroup__children,
        childrenWrapper.withHeading
      ),
      title: euiClass(
        context,
        // React's global reset for headings.
        {
          boxSizing: 'border-box',
          margin: 0,
          padding: 0,
          fontFamily: context.upstream.euiTheme.font.family
        },
        title.euiTitle,
        title[this.args.titleSize ?? 'xxs']
      )
    };
  };

  <template>
    {{#let
      (if @id @id (randomId)) (element this.titleElement)
      as |groupID TitleElement|
    }}
      {{#let (concat groupID "__title") as |titleID|}}
        <EuiEmotionProvider
          @colorMode={{this.colorMode}}
          @wrapper={{false}}
          @globalStyles={{false}}
          as |provider|
        >
          {{#let (this.classesFor provider.context) as |classes|}}
            {{#if (and @isCollapsible (has-block "title"))}}
              <EuiAccordion
                id={{groupID}}
                class="euiCollapsibleNavGroup"
                @css={{classes.rootCss}}
                @buttonClassName="euiCollapsibleNavGroup__heading"
                @initialIsOpen={{if
                  (eq @initialIsOpen undefined)
                  true
                  @initialIsOpen
                }}
                @arrowDisplay="right"
                ...attributes
              >
                <:buttonContent>
                  <EuiFlexGroup
                    @gutterSize="m"
                    @alignItems="center"
                    @responsive={{false}}
                  >
                    {{#if @iconType}}
                      <EuiFlexItem @grow={{false}}>
                        <EuiIcon
                          @type={{@iconType}}
                          @size={{if @iconSize @iconSize "l"}}
                        />
                      </EuiFlexItem>
                    {{/if}}
                    <EuiFlexItem>
                      <TitleElement
                        id={{titleID}}
                        class="euiTitle euiCollapsibleNavGroup__title
                          {{classes.title}}"
                      >
                        {{yield to="title"}}
                      </TitleElement>
                    </EuiFlexItem>
                  </EuiFlexGroup>
                </:buttonContent>
                <:content>
                  {{#if (has-block "content")}}
                    <div
                      class="euiCollapsibleNavGroup__children
                        {{classes.childrenWithHeading}}"
                    >
                      {{yield to="content"}}
                    </div>
                  {{/if}}
                </:content>
              </EuiAccordion>
            {{else}}
              <div
                id={{groupID}}
                class="euiCollapsibleNavGroup {{classes.root}}"
                ...attributes
              >
                {{#if (has-block "title")}}
                  <div class="euiCollapsibleNavGroup__heading">
                    <EuiFlexGroup
                      @gutterSize="m"
                      @alignItems="center"
                      @responsive={{false}}
                    >
                      {{#if @iconType}}
                        <EuiFlexItem @grow={{false}}>
                          <EuiIcon
                            @type={{@iconType}}
                            @size={{if @iconSize @iconSize "l"}}
                          />
                        </EuiFlexItem>
                      {{/if}}
                      <EuiFlexItem>
                        <TitleElement
                          id={{titleID}}
                          class="euiTitle euiCollapsibleNavGroup__title
                            {{classes.title}}"
                        >
                          {{yield to="title"}}
                        </TitleElement>
                      </EuiFlexItem>
                    </EuiFlexGroup>
                  </div>
                {{/if}}
                {{#if (has-block "content")}}
                  <div
                    class="euiCollapsibleNavGroup__children
                      {{if
                        (has-block 'title')
                        classes.childrenWithHeading
                        classes.children
                      }}"
                  >
                    {{yield to="content"}}
                  </div>
                {{/if}}
              </div>
            {{/if}}
          {{/let}}
        </EuiEmotionProvider>
      {{/let}}
    {{/let}}
  </template>
}

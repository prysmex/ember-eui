import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { or } from 'ember-truth-helpers';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import {
  euiBorderColor,
  euiCommentEventBodyStyles,
  euiCommentEventHeaderStyles,
  euiCommentEventStyles,
  euiTimelineItemEventStyles,
  euiTimelineItemIconStyles,
  euiTimelineItemStyles
} from '../utils/eui/styles.generated.ts';
import EuiAvatar from './eui-avatar.gts';
import EuiCommentTimeline from './eui-comment-timeline.gts';
import EuiPanel from './eui-panel.gts';

import type { EuiIconSignature } from './eui-icon';
import type { EuiPanelSignature } from './eui-panel';

export type EuiCommentEventColor =
  | NonNullable<EuiPanelSignature['Args']['color']>
  | 'highlighted';
type EuiCommentType = 'regular' | 'update' | 'custom';

/** Theme-less upstream factories (static, shared by every comment). */
const ITEM_STYLES = euiTimelineItemStyles();
const ITEM_EVENT_STYLES = euiTimelineItemEventStyles();
const NO_BORDER = { border: 'none' } as const;

export interface EuiCommentSignature {
  Element: HTMLLIElement;
  Args: {
    /**
     * @deprecated Has no effect: like upstream, the type follows the blocks.
     * A comment with a `<:body>` and header content is `regular` (a bordered
     * `<figure>`), one without a body is a compact `update`, and one with
     * only a body is `custom` (no header).
     */
    type?: 'regular' | 'update';
    /**
     * Icon of the timeline avatar (upstream `timelineAvatar` as a string).
     * Defaults to `'user'`. Use the `<:timelineIcon>` block for custom
     * content such as `<EuiAvatar @name="Jane" />`.
     */
    timelineIcon?: EuiIconSignature['Args']['type'];
    /** Accessible name of the default timeline avatar. */
    timelineAvatarAriaLabel?: string;
    /**
     * Background of the header panel: `'highlighted'`, `'subdued'`,
     * `'transparent'`, `'plain'`, `'accent'`, `'primary'`, `'success'`,
     * `'warning'` or `'danger'`. Defaults to `'highlighted'` for regular
     * comments and `'transparent'` for updates. Regular comments also get a
     * border of this color (`'subdued'` for highlighted).
     */
    eventColor?: EuiCommentEventColor;
    /** Icon in a small avatar before the username, e.g. `'pencil'`. */
    eventIcon?: EuiIconSignature['Args']['type'];
    /** Accessible name of `@eventIcon`; without it the icon is decorative. */
    eventIconAriaLabel?: string;
  };
  Blocks: {
    /** Custom timeline content, e.g. `<EuiAvatar @name="Jane" />`. */
    timelineIcon: [];
    /** Who wrote it. */
    username: [];
    /** What happened, e.g. "added a comment" or "closed the issue". */
    event: [];
    /** When, e.g. "on Jan 1st, 2024"; wrapped in `<time>`. */
    timestamp: [];
    /** Actions at the end of the header, e.g. an `EuiButtonIcon`. */
    actions: [];
    /** The comment's content. */
    body: [];
  };
}

interface CommentItemSignature {
  Element: HTMLLIElement;
  Args: EuiCommentSignature['Args'] & {
    hasBody: boolean;
    /** Truthy when the header has more than a username (upstream). */
    hasEventElements: unknown;
    hasTimelineIcon: boolean;
    hasUsername: boolean;
    hasEvent: boolean;
    hasTimestamp: boolean;
    hasActions: boolean;
  };
  Blocks: EuiCommentSignature['Blocks'];
}

/**
 * @private The timeline item (upstream `EuiTimelineItem` + `EuiCommentEvent`)
 * behind EuiComment, which passes which blocks it was given.
 */
class EuiCommentItem extends Component<CommentItemSignature> {
  get context() {
    return getEuiThemeContext(this);
  }

  /** Upstream `EuiCommentEvent` branching. */
  get type(): EuiCommentType {
    const hasBody = this.args.hasBody;
    const hasEventElements = Boolean(this.args.hasEventElements);
    if (hasBody && hasEventElements) return 'regular';
    if (!hasBody && hasEventElements) return 'update';
    return 'custom';
  }

  get eventColor(): EuiCommentEventColor | undefined {
    const color = this.args.eventColor;
    if (color) return color;
    if (this.type === 'regular') return 'highlighted';
    if (this.type === 'update') return 'transparent';
    return undefined;
  }

  get verticalAlign(): 'center' | 'top' {
    return this.args.hasBody ? 'top' : 'center';
  }

  get isFigure(): boolean {
    return this.type === 'regular';
  }

  get panelColor() {
    return (
      this.type === 'custom' ? 'transparent' : this.eventColor
    ) as EuiPanelSignature['Args']['color'];
  }

  get panelPadding(): 'none' | 's' {
    return this.type === 'custom' ? 'none' : 's';
  }

  get panelRadius(): 'none' | 'm' {
    return this.type === 'regular' ? 'none' : 'm';
  }

  /** Upstream `EuiTimelineItem` (`li`), labelled `euiTimelineItem-<align>`. */
  @cached
  get itemClass(): string {
    return euiClass(
      this.context,
      ITEM_STYLES.euiTimelineItem,
      ITEM_STYLES[this.verticalAlign]
    );
  }

  @cached
  get iconClass(): string {
    const styles = useEuiBorealisStyles(this.context, euiTimelineItemIconStyles);
    return euiClass(
      this.context,
      styles.euiTimelineItemIcon,
      styles[this.verticalAlign]
    );
  }

  @cached
  get iconContentClass(): string {
    const styles = useEuiBorealisStyles(this.context, euiTimelineItemIconStyles);
    return euiClass(this.context, styles.euiTimelineItemIcon__content);
  }

  @cached
  get eventWrapperClass(): string {
    return euiClass(
      this.context,
      ITEM_EVENT_STYLES.euiTimelineItemEvent,
      ITEM_EVENT_STYLES[this.verticalAlign]
    );
  }

  get borderColor() {
    const color = this.eventColor;
    return euiBorderColor(
      this.context.upstream,
      color === 'highlighted' ? 'subdued' : (color ?? 'transparent')
    );
  }

  @cached
  get eventClass(): string {
    const styles = useEuiBorealisStyles(this.context, euiCommentEventStyles);
    const showBorders =
      this.type === 'regular' ||
      (this.type === 'update' && Boolean(this.context.upstream.highContrastMode));
    return euiClass(
      this.context,
      // Reset for the `<figure>` (React's global reset zeroes its margin).
      { boxSizing: 'border-box', margin: 0 },
      styles.euiCommentEvent,
      showBorders && styles.border,
      showBorders && { borderColor: this.borderColor }
    );
  }

  @cached
  get headerStyles() {
    return useEuiBorealisStyles(this.context, euiCommentEventHeaderStyles);
  }

  @cached
  get headerClass(): string {
    const styles = this.headerStyles;
    const showBorders = this.type === 'regular';
    return euiClass(
      this.context,
      styles.euiCommentEvent__header,
      showBorders && styles.border,
      showBorders && { borderColor: this.borderColor }
    );
  }

  @cached
  get headerMainClass(): string {
    return euiClass(this.context, this.headerStyles.euiCommentEvent__headerMain);
  }

  @cached
  get headerDataClass(): string {
    return euiClass(this.context, this.headerStyles.euiCommentEvent__headerData);
  }

  @cached
  get usernameClass(): string {
    return euiClass(
      this.context,
      this.headerStyles.euiCommentEvent__headerUsername
    );
  }

  @cached
  get headerEventClass(): string {
    return euiClass(this.context, this.headerStyles.euiCommentEvent__headerEvent);
  }

  @cached
  get actionsClass(): string {
    return euiClass(
      this.context,
      this.headerStyles.euiCommentEvent__headerActions
    );
  }

  @cached
  get bodyClass(): string {
    const styles = useEuiBorealisStyles(this.context, euiCommentEventBodyStyles);
    return euiClass(
      this.context,
      styles.euiCommentEvent__body,
      styles[this.type]
    );
  }

  /**
   * Upstream removes the header panel's high contrast border (`& > .euiPanel`
   * in the header styles; Ember's panel root class differs), here through
   * the panel's own `@css`.
   */
  get panelCss() {
    return this.context.upstream.highContrastMode ? NO_BORDER : undefined;
  }

  get eventIconAriaHidden(): 'true' | undefined {
    return this.args.eventIconAriaLabel ? undefined : 'true';
  }

  <template>
    <li class="euiComment {{this.itemClass}}" ...attributes>
      <div class={{this.iconClass}}>
        <div class={{this.iconContentClass}}>
          {{#if @hasTimelineIcon}}
            <EuiCommentTimeline>
              <:timelineIcon>{{yield to="timelineIcon"}}</:timelineIcon>
            </EuiCommentTimeline>
          {{else}}
            <EuiCommentTimeline
              @timelineIcon={{@timelineIcon}}
              @timelineAvatarAriaLabel={{@timelineAvatarAriaLabel}}
            />
          {{/if}}
        </div>
      </div>
      <div class={{this.eventWrapperClass}}>
        {{#let
          (element (if this.isFigure "figure" "div"))
          (element (if this.isFigure "figcaption" "div"))
          as |Event Header|
        }}
          <Event
            class="euiCommentEvent {{this.eventClass}}"
            data-type={{this.type}}
          >
            {{#if @hasEventElements}}
              <Header class="euiCommentEvent__header {{this.headerClass}}">
                <EuiPanel
                  @color={{this.panelColor}}
                  @paddingSize={{this.panelPadding}}
                  @borderRadius={{this.panelRadius}}
                  @hasShadow={{false}}
                  @hasBorder={{false}}
                  @css={{this.panelCss}}
                >
                  <div
                    class="euiCommentEvent__headerMain {{this.headerMainClass}}"
                  >
                    <div
                      class="euiCommentEvent__headerData {{this.headerDataClass}}"
                    >
                      {{#if @eventIcon}}
                        <EuiAvatar
                          class="euiCommentEvent__headerEventIcon"
                          @css={{this.headerStyles.euiCommentEvent__headerEventIcon}}
                          @size="s"
                          @iconType={{@eventIcon}}
                          @name={{if @eventIconAriaLabel @eventIconAriaLabel ""}}
                          @color="subdued"
                          aria-hidden={{this.eventIconAriaHidden}}
                        />
                      {{/if}}
                      {{#if @hasUsername}}
                        <div
                          class="euiCommentEvent__headerUsername {{this.usernameClass}}"
                        >{{yield to="username"}}</div>
                      {{/if}}
                      {{#if @hasEvent}}
                        <div
                          class="euiCommentEvent__headerEvent {{this.headerEventClass}}"
                        >{{yield to="event"}}</div>
                      {{/if}}
                      {{#if @hasTimestamp}}
                        <div class="euiCommentEvent__headerTimestamp">
                          <time>{{yield to="timestamp"}}</time>
                        </div>
                      {{/if}}
                    </div>
                    {{#if @hasActions}}
                      <div
                        class="euiCommentEvent__headerActions {{this.actionsClass}}"
                      >{{yield to="actions"}}</div>
                    {{/if}}
                  </div>
                </EuiPanel>
              </Header>
            {{/if}}
            {{#if @hasBody}}
              <div class="euiCommentEvent__body {{this.bodyClass}}">
                {{yield to="body"}}
              </div>
            {{/if}}
          </Event>
        {{/let}}
      </div>
    </li>
  </template>
}

/**
 * One comment or event on a timeline (upstream `EuiComment`): an avatar,
 * a header (username, event, timestamp, actions) and an optional body.
 * Place it in an `EuiCommentList`.
 */
const EuiComment: import('@ember/component/template-only').TemplateOnlyComponent<EuiCommentSignature> =
  <template>
    <EuiCommentItem
      @timelineIcon={{@timelineIcon}}
      @timelineAvatarAriaLabel={{@timelineAvatarAriaLabel}}
      @eventColor={{@eventColor}}
      @eventIcon={{@eventIcon}}
      @eventIconAriaLabel={{@eventIconAriaLabel}}
      @hasBody={{has-block "body"}}
      @hasEventElements={{or
        @eventIcon
        (has-block "timestamp")
        (has-block "event")
        (has-block "actions")
      }}
      @hasTimelineIcon={{has-block "timelineIcon"}}
      @hasUsername={{has-block "username"}}
      @hasEvent={{has-block "event"}}
      @hasTimestamp={{has-block "timestamp"}}
      @hasActions={{has-block "actions"}}
      ...attributes
    >
      <:timelineIcon>{{yield to="timelineIcon"}}</:timelineIcon>
      <:username>{{yield to="username"}}</:username>
      <:event>{{yield to="event"}}</:event>
      <:timestamp>{{yield to="timestamp"}}</:timestamp>
      <:actions>{{yield to="actions"}}</:actions>
      <:body>{{yield to="body"}}</:body>
    </EuiCommentItem>
  </template>;

export default EuiComment;

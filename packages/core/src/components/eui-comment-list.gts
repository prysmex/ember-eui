import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import EuiRenderNode from '../-private/eui-render-node.gts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiTimelineStyles } from '../utils/eui/styles.generated.ts';
import { EuiCommentItem } from './eui-comment.gts';

import type { EuiRenderNode as EuiRenderNodeType } from '../-private/eui-render-node.gts';
import type { EuiCommentSignature } from './eui-comment.gts';

const truthy = (value: unknown) => Boolean(value);
/** A string `timelineIcon` is an icon type; anything else is custom content. */
const iconType = (value: unknown) =>
  typeof value === 'string' ? value : undefined;
const customIcon = (value: unknown) => Boolean(value) && typeof value !== 'string';
const nodeIcon = (value: unknown) =>
  customIcon(value) ? (value as EuiRenderNodeType) : undefined;
/** Upstream: the header has more than a username. */
const eventElements = (comment: EuiCommentListItem) =>
  Boolean(
    comment.eventIcon ||
      comment.timestamp ||
      comment.event ||
      comment.actions
  );

/** React's global list reset, scoped to the timeline list. */
const LIST_RESET = {
  boxSizing: 'border-box',
  margin: 0,
  padding: 0,
  listStyle: 'none'
} as const;

/**
 * One comment of `@comments`: upstream's `EuiCommentProps` with Ember's
 * nodes. Every node is text or a component (`(component …)` or any
 * component); `body` is upstream's `children`.
 */
export interface EuiCommentListItem {
  username?: EuiRenderNodeType;
  event?: EuiRenderNodeType;
  timestamp?: EuiRenderNodeType;
  actions?: EuiRenderNodeType;
  /** The comment's content (upstream's `children`). */
  body?: EuiRenderNodeType;
  /**
   * Icon of the timeline avatar (a string) or custom content (a
   * component); upstream's `timelineAvatar`.
   */
  timelineIcon?: EuiCommentSignature['Args']['timelineIcon'] | EuiRenderNodeType;
  timelineAvatarAriaLabel?: EuiCommentSignature['Args']['timelineAvatarAriaLabel'];
  eventColor?: EuiCommentSignature['Args']['eventColor'];
  eventIcon?: EuiCommentSignature['Args']['eventIcon'];
  eventIconAriaLabel?: EuiCommentSignature['Args']['eventIconAriaLabel'];
}

/** Stacks EuiComments along a shared timeline (an ordered list). */
export interface EuiCommentListSignature {
  Element: HTMLOListElement;
  Args: {
    /**
     * Vertical space between comments: `'m'`, `'l'` or `'xl'`.
     * Defaults to `'l'`.
     */
    gutterSize?: 'm' | 'l' | 'xl';
    /**
     * Comments to render from data (see `EuiCommentListItem`), before the
     * block's content. Give the list an `aria-label` or `aria-labelledby`
     * attribute.
     */
    comments?: EuiCommentListItem[];
  };
  Blocks: {
    /** The `EuiComment`s. */
    default: [];
  };
}

/**
 * Native Ember comment list: upstream renders it as an `EuiTimeline`
 * (`<ol role="list">`) with the vertical line between the avatars.
 */
export default class EuiCommentList extends Component<EuiCommentListSignature> {
  @cached
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiTimelineStyles);
    const gutter = this.args.gutterSize;
    return euiClass(
      context,
      LIST_RESET,
      styles.euiTimeline,
      styles[gutter === 'm' || gutter === 'xl' ? gutter : 'l']
    );
  }

  <template>
    {{! template-lint-disable no-redundant-role }}
    <ol class="euiCommentList euiTimeline {{this.classes}}" role="list" ...attributes>
      {{#each @comments as |comment|}}
        <EuiCommentItem
          @timelineIcon={{iconType comment.timelineIcon}}
          @timelineAvatarAriaLabel={{comment.timelineAvatarAriaLabel}}
          @eventColor={{comment.eventColor}}
          @eventIcon={{comment.eventIcon}}
          @eventIconAriaLabel={{comment.eventIconAriaLabel}}
          @hasBody={{truthy comment.body}}
          @hasEventElements={{eventElements comment}}
          @hasTimelineIcon={{customIcon comment.timelineIcon}}
          @hasUsername={{truthy comment.username}}
          @hasEvent={{truthy comment.event}}
          @hasTimestamp={{truthy comment.timestamp}}
          @hasActions={{truthy comment.actions}}
        >
          <:timelineIcon><EuiRenderNode @value={{nodeIcon comment.timelineIcon}} /></:timelineIcon>
          <:username><EuiRenderNode @value={{comment.username}} /></:username>
          <:event><EuiRenderNode @value={{comment.event}} /></:event>
          <:timestamp><EuiRenderNode @value={{comment.timestamp}} /></:timestamp>
          <:actions><EuiRenderNode @value={{comment.actions}} /></:actions>
          <:body><EuiRenderNode @value={{comment.body}} /></:body>
        </EuiCommentItem>
      {{/each}}
      {{yield}}
    </ol>
  </template>
}

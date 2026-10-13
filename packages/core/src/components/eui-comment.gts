import { or } from 'ember-truth-helpers';

import { EuiCommentItem } from '../-private/eui-comment-item.gts';

import type { EuiIconSignature } from './eui-icon';
import type { EuiPanelSignature } from './eui-panel';

export type EuiCommentEventColor =
  | NonNullable<EuiPanelSignature['Args']['color']>
  | 'highlighted';

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
    /**
     * Vertical alignment of the avatar with the event: `'top'` or
     * `'center'`. Defaults to `'top'` with a `<:body>`, else `'center'`.
     */
    verticalAlign?: 'top' | 'center';
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
      @verticalAlign={{@verticalAlign}}
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

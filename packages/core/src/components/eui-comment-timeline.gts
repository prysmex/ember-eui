import EuiAvatar from './eui-avatar.gts';

import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * @private The avatar on an EuiComment's timeline: upstream's
 * `EuiCommentTimeline` (a subdued `EuiAvatar` with an icon, `user` by
 * default) or custom content.
 */
export interface EuiCommentTimelineSignature {
  Element: HTMLDivElement;
  Args: {
    /** Icon of the avatar. Defaults to `'user'`. */
    timelineIcon?: EuiIconSignature['Args']['type'];
    /** Accessible name of the avatar (its `aria-label`/`title`). */
    timelineAvatarAriaLabel?: string;
    /**
     * @deprecated Has no effect: upstream shows the same avatar for regular
     * and update comments.
     */
    type?: 'regular' | 'update';
  };
  Blocks: {
    /** Custom content instead of the avatar, e.g. an `EuiAvatar`. */
    timelineIcon: [];
  };
}

const EuiCommentTimeline: TemplateOnlyComponent<EuiCommentTimelineSignature> =
  <template>
    {{#if (has-block "timelineIcon")}}
      {{yield to="timelineIcon"}}
    {{else}}
      <EuiAvatar
        class="euiCommentAvatar"
        @name={{if @timelineAvatarAriaLabel @timelineAvatarAriaLabel ""}}
        @iconType={{if @timelineIcon @timelineIcon "user"}}
        @color="subdued"
        ...attributes
      />
    {{/if}}
  </template>;

export default EuiCommentTimeline;

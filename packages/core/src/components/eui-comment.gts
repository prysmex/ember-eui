import { and, eq, not } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiCommentTimeline from './eui-comment-timeline.gts';

import type { EuiCommentTimelineSignature } from './eui-comment-timeline';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiCommentSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * `'regular'` for a comment with a body in a panel, `'update'` for a
     * compact one-line event (e.g. "added a tag"). Defaults to `'regular'`.
     */
    type?: EuiCommentTimelineSignature['Args']['type'];
    /**
     * Icon on the timeline, e.g. an `EuiAvatar` alternative. Defaults to a
     * user icon (`'dot'` for updates). Use the `<:timelineIcon>` block for
     * custom content such as `<EuiAvatar>`.
     */
    timelineIcon?: EuiCommentTimelineSignature['Args']['timelineIcon'];
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
    /** Actions on the right of the header, e.g. an `EuiButtonIcon`. */
    actions: [];
    /** The comment's content. */
    body: [];
  };
}

const EuiComment: TemplateOnlyComponent<EuiCommentSignature> = <template>
  <div
    class={{classNames
      "euiComment"
      (if (eq @type "update") "euiComment--update")
      (if (has-block "body") "euiComment--hasBody")
    }}
    ...attributes
  >
    {{#if (has-block "timelineIcon")}}
      <EuiCommentTimeline @type={{@type}}>
        <:timelineIcon>
          {{yield to="timelineIcon"}}
        </:timelineIcon>
      </EuiCommentTimeline>
    {{else}}
      <EuiCommentTimeline @type={{@type}} @timelineIcon={{@timelineIcon}} />
    {{/if}}
    {{! Basically the same, just to avoid using dynamic tag we use figure and figcaption instead of divs when it doesn't have body}}
    {{#if (and (eq @type "update") (not (has-block "body")))}}
      <figure
        class={{classNames
          componentName="EuiCommentEvent"
          type=(argOrDefault @type "regular")
        }}
      >
        <figcaption class="euiCommentEvent__header">
          <div class="euiCommentEvent__headerData">
            <div class="euiCommentEvent__headerUsername">
              {{yield to="username"}}
            </div>
            <div class="euiCommentEvent__headerEvent">
              {{yield to="event"}}
            </div>
            {{#if (has-block "timestamp")}}
              <div class="euiCommentEvent__headerTimestamp">
                <time>
                  {{yield to="timestamp"}}
                </time>
              </div>
            {{/if}}
          </div>
          <div class="euiCommentEvent__headerActions">
            {{yield to="actions"}}
          </div>
        </figcaption>
        <div class="euiCommentEvent__body">
          {{yield to="body"}}
        </div>
      </figure>
    {{else}}
      <div
        class={{classNames
          componentName="EuiCommentEvent"
          type=(argOrDefault @type "regular")
        }}
      >
        <div class="euiCommentEvent__header">
          <div class="euiCommentEvent__headerData">
            <div class="euiCommentEvent__headerUsername">
              {{yield to="username"}}
            </div>
            <div class="euiCommentEvent__headerEvent">
              {{yield to="event"}}
            </div>
            {{#if (has-block "timestamp")}}
              <div class="euiCommentEvent__headerTimestamp">
                <time>
                  {{yield to="timestamp"}}
                </time>
              </div>
            {{/if}}
          </div>
          <div class="euiCommentEvent__headerActions">
            {{yield to="actions"}}
          </div>
        </div>
        <div class="euiCommentEvent__body">
          {{yield to="body"}}
        </div>
      </div>
    {{/if}}
  </div>
</template>;

export default EuiComment;

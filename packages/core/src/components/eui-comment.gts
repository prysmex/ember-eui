import { and, eq, not } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiCommentTimeline from './eui-comment-timeline.gts';

import type { EuiCommentTimelineSignature } from './eui-comment-timeline';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiCommentSignature {
  Element: HTMLDivElement;
  Args: {
    type: EuiCommentTimelineSignature['Args']['type'];
    timelineIcon?: EuiCommentTimelineSignature['Args']['timelineIcon'];
  };
  Blocks: {
    timelineIcon: [];
    username: [];
    event: [];
    timestamp: [];
    actions: [];
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

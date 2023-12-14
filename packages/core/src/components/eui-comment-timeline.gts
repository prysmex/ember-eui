import { eq, not,or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiIcon from './eui-icon.gts';

import type { commentTimelineTypeMapping } from '../utils/css-mappings/eui-comment-timeline-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiCommentTimelineSignature {
  Element: HTMLDivElement;
  Args: {
    timelineIcon?: string;
    type?: keyof typeof commentTimelineTypeMapping;
  };
  Blocks: {
    timelineIcon: [];
  };
}

const EuiCommentTimeline: TemplateOnlyComponent<EuiCommentTimelineSignature> =
  <template>
    <div class="euiCommentTimeline" ...attributes>
      <div class="euiCommentTimeline__content">
        <div
          class={{classNames
            (if
              (or @timelineIcon (not (has-block "timelineIcon")))
              "euiCommentTimeline__icon--default"
            )
            componentName="EuiCommentTimelineIcon"
            type=(argOrDefault @type "regular")
          }}
        >
          {{#if @timelineIcon}}
            <EuiIcon
              @size={{if (eq @type "update") "m" "l"}}
              @type={{@timelineIcon}}
            />
          {{else if (has-block "timelineIcon")}}
            {{yield to="timelineIcon"}}
          {{else}}
            <EuiIcon
              @type={{if (eq @type "update") "dot" "user"}}
              @size={{if (eq @type "update") "m" "l"}}
            />
          {{/if}}
        </div>
      </div>
    </div>
  </template>;

export default EuiCommentTimeline;

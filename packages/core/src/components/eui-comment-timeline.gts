import { eq, not,or } from 'ember-truth-helpers';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';
import EuiIcon from './eui-icon.gts';

import type { commentTimelineTypeMapping } from '../utils/css-mappings/eui-comment-timeline-icon.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private The icon column of an EuiComment. */
export interface EuiCommentTimelineSignature {
  Element: HTMLDivElement;
  Args: {
    /** Icon on the timeline. Defaults to `'user'` (`'dot'` for updates). */
    timelineIcon?: string;
    /** `'regular'` or `'update'`, see `EuiComment`. Defaults to `'regular'`. */
    type?: keyof typeof commentTimelineTypeMapping;
  };
  Blocks: {
    /** Custom content instead of the icon, e.g. an `EuiAvatar`. */
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

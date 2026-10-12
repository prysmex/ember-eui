import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { concat } from '@ember/helper';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiNotificationEventStyles } from '../utils/eui/notification-event.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiIcon from './eui-icon.gts';

import type { EuiIconSignature } from './eui-icon';

/** @private Dot showing an EuiNotificationEvent's read state. */
export interface EuiNotificationEventReadIconSignature {
  Element: HTMLDivElement;
  Args: {
    /** Id of the event. */
    id?: string;
    /** The event's title, for the accessible label. */
    eventName?: string;
    /** Read state: unread is a filled dot, read a hollow one. */
    isRead?: boolean;
    /** Color of the dot. Defaults to `'primary'`. */
    readIconColor?: EuiIconSignature['Args']['color'];
  };
}

export default class EuiNotificationEventReadIcon extends Component<EuiNotificationEventReadIconSignature> {
  /** Read styles composed into EuiIcon's own class (`@css`). */
  @cached
  get iconCss() {
    if (!this.args.isRead) return undefined;
    const context = getEuiThemeContext(this);
    return useEuiBorealisStyles(context, euiNotificationEventStyles)
      .readIconIsRead;
  }

  <template>
    {{! ToDo: title and aria-label translations }}
    <div class="euiNotificationEventReadIcon" ...attributes>
      <EuiIcon
        @type="dot"
        @aria-label={{if
          @isRead
          (concat @eventName " is read")
          (concat @eventName " is unread")
        }}
        @color={{if @readIconColor @readIconColor "primary"}}
        @css={{this.iconCss}}
        title={{if @isRead "Read" "Unread"}}
        data-test-subj={{concat @id "-notificationEventReadIcon"}}
        id={{@id}}
      />
    </div>
  </template>
}

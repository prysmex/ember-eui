import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { concat } from '@ember/helper';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiNotificationEventStyles } from '../utils/eui/notification-event.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiButtonIcon from './eui-button-icon.gts';

import type { EuiButtonIconSignature } from './eui-button-icon';

/** @private Button toggling an EuiNotificationEvent's read state. */
export interface EuiNotificationEventReadButtonSignature {
  Element: EuiButtonIconSignature['Element'];
  Args: {
    /** Id of the event. */
    id?: string;
    /** The event's title, for the accessible label. */
    eventName?: string;
    /** Read state: unread is a filled dot, read a hollow one. */
    isRead?: boolean;
  };
}

export default class EuiNotificationEventReadButton extends Component<EuiNotificationEventReadButtonSignature> {
  /** Read styles composed into EuiButtonIcon's own class (`@css`). */
  @cached
  get buttonCss() {
    if (!this.args.isRead) return undefined;
    const context = getEuiThemeContext(this);
    return useEuiBorealisStyles(context, euiNotificationEventStyles)
      .readButtonIsRead;
  }

  <template>
    {{! ToDo: title and aria-label translations }}
    <EuiButtonIcon
      @iconType="dot"
      @css={{this.buttonCss}}
      aria-label={{if
        @isRead
        (concat "Mark " @eventName " as unread")
        (concat "Mark " @eventName " as read")
      }}
      title={{if @isRead "Read" "Unread"}}
      class="euiNotificationEventReadButton"
      data-test-subj={{concat @id "-notificationEventReadButton"}}
      id={{@id}}
      ...attributes
    />
  </template>
}

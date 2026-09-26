import { concat } from '@ember/helper';

import classNames from '../helpers/class-names.ts';
import EuiButtonIcon from './eui-button-icon.gts';

import type { EuiButtonIconSignature } from './eui-button-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** @private Button toggling an EuiNotificationEvent's read state. */
export interface EuiNotificationEventReadButtonSignature {
  Element: EuiButtonIconSignature['Element'];
  Args: {
    /** Id of the event. */
    id?: string;
    /** The event's title, for the accessible label. */
    eventName?: string;
    /** Read state. */
    isRead?: boolean;
  };
}

const EuiNotificationEventReadButton: TemplateOnlyComponent<EuiNotificationEventReadButtonSignature> =
  <template>
    {{! ToDo: title and aria-label translations }}
    <EuiButtonIcon
      @iconType="dot"
      aria-label={{if
        @isRead
        (concat "Mark " @eventName " as unread")
        (concat "Mark " @eventName " as read")
      }}
      title={{if @isRead "Read" "Unread"}}
      class={{classNames
        "euiNotificationEventReadButton"
        (if @isRead "euiNotificationEventReadButton--isRead")
      }}
      data-test-subj={{concat @id "-notificationEventReadButton"}}
      id={{@id}}
      ...attributes
    />
  </template>;

export default EuiNotificationEventReadButton;

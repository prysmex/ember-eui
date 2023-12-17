import { concat } from '@ember/helper';

import classNames from '../helpers/class-names';
import EuiButtonIcon from './eui-button-icon.gts';

import type { EuiButtonIconSignature } from './eui-button-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiNotificationEventReadButtonSignature {
  Element: EuiButtonIconSignature['Element'];
  Args: {
    id?: string;
    eventName?: string;
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

import { concat } from '@ember/helper';

import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import EuiIcon from './eui-icon.gts';

import type { EuiIconSignature } from './eui-icon';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

export interface EuiNotificationEventReadIconSignature {
  Element: HTMLDivElement;
  Args: {
    id?: string;
    eventName?: string;
    isRead?: boolean;
    readIconColor?: EuiIconSignature['Args']['color'];
  };
}

const EuiNotificationEventReadIcon: TemplateOnlyComponent<EuiNotificationEventReadIconSignature> =
  <template>
    {{! ToDo: title and aria-label translations }}
    <div
      class={{classNames
        "euiNotificationEventReadIcon"
        (if @isRead "euiNotificationEventReadIcon--isRead")
      }}
      ...attributes
    >
      <EuiIcon
        @type="dot"
        aria-label={{if
          @isRead
          (concat @eventName " is read")
          (concat @eventName " is unread")
        }}
        title={{if @isRead "Read" "Unread"}}
        @color={{argOrDefault @readIconColor "primary"}}
        data-test-subj={{concat @id "-notificationEventReadIcon"}}
        id={{@id}}
      />
    </div>
  </template>;

export default EuiNotificationEventReadIcon;

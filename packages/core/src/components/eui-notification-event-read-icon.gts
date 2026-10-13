import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';
import { concat } from '@ember/helper';

import { deprecateRemovedUpstream } from '../-private/removed-upstream.ts';
import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiNotificationEventStyles } from '../utils/eui/notification-event.ts';
import { useEuiBorealisStyles } from '../utils/eui/styles.ts';
import EuiIcon from './eui-icon.gts';

import type { EuiIconSignature } from './eui-icon';
import type Owner from '@ember/owner';

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
  constructor(owner: Owner, args: EuiNotificationEventReadIconSignature['Args']) {
    super(owner, args);
    deprecateRemovedUpstream(
      'eui-notification-event-read-icon',
      'EuiNotificationEventReadIcon',
      'Compose notifications from EuiPanel, EuiTitle, EuiText and EuiContextMenu instead.'
    );
  }

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

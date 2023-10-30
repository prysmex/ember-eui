import argOrDefault from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';
import { concat } from '@ember/helper';

import EuiIcon from './eui-icon';

<template>
  {{! @glint-nocheck: not typesafe yet }}
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
</template>

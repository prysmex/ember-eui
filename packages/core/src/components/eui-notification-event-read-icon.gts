import argOrDefault from '@ember-eui/core/helpers/arg-or-default';
import classNames from '@ember-eui/core/helpers/class-names';
import { concat } from '@ember/helper';

import EuiIcon from '@ember-eui/core/components/eui-icon';

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
</template>

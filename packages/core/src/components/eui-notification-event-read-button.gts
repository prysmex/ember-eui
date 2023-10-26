import EuiButtonIcon from './eui-button-icon';
import classNames from '../helpers/class-names';
import { concat } from '@ember/helper';

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
</template>

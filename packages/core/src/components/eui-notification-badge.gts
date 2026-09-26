import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type {
  colorMapping,
  sizeMapping
} from '../utils/css-mappings/eui-notification-badge.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** A small count badge, e.g. unread notifications on a header button. */
export interface EuiNotificationBadgeSignature {
  Element: HTMLSpanElement;
  Args: {
    /** `'s'` or `'m'`. Defaults to `'s'`. */
    size?: keyof typeof sizeMapping;
    /** `'accent'` or `'subdued'`. Defaults to `'accent'`. */
    color?: keyof typeof colorMapping;
  };
  Blocks: {
    /** The count, e.g. `3`. */
    default: [];
  };
}

const EuiNotificationBadge: TemplateOnlyComponent<EuiNotificationBadgeSignature> =
  <template>
    <span
      class={{classNames
        componentName="EuiNotificationBadge"
        size=(argOrDefault @size "s")
        color=(argOrDefault @color "accent")
      }}
      ...attributes
    >
      {{yield}}
    </span>
  </template>;

export default EuiNotificationBadge;

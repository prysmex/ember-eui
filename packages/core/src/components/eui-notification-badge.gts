import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type {
  colorMapping,
  sizeMapping
} from '../utils/css-mappings/eui-notification-badge.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

interface EuiNotificationBadgeSignature {
  Element: HTMLSpanElement;
  Args: {
    size?: keyof typeof sizeMapping;
    color?: keyof typeof colorMapping;
  };
  Blocks: {
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

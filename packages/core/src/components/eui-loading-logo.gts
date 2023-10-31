import type { TemplateOnlyComponent } from '@ember/component/template-only';
import classNames from '../helpers/class-names';
import argOrDefault from '../helpers/arg-or-default';
import { eq } from 'ember-truth-helpers';
import EuiIcon from './eui-icon';

export interface EuiLoadingLogoSignature {
  Args: {
    logo?: string;
    size?: 'm' | 'l' | 'xl';
  };
  Yields: {
    default: [];
  };
}

const EuiLoadingLogo: TemplateOnlyComponent<EuiLoadingLogoSignature> =
  <template>
    <span
      class={{classNames
        "euiLoadingLogo"
        (if
          (eq @size "m")
          "euiLoadingLogo--medium"
          (if (eq @size "l") "euiLoadingLogo--large" "euiLoadingLogo--xLarge")
        )
      }}
    >
      <span class="euiLoadingLogo__icon">
        <EuiIcon
          @type={{argOrDefault @logo "logoKibana"}}
          @size={{argOrDefault @size "m"}}
        />
      </span>
    </span>
  </template>;

export default EuiLoadingLogo;

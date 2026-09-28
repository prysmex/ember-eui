import { hash } from '@ember/helper';

import cssStyle from '../-private/css-style.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';

/**
 * A pulsing dot that draws attention to something new, e.g. next to a
 * feature a tour points at.
 */
export interface EuiBeaconSignature {
  Element: HTMLDivElement;
  Args: {
    /** Diameter of the center dot in px. Defaults to `12`. */
    size?: number;
  };
}

const EuiBeacon: TemplateOnlyComponent<EuiBeaconSignature> = <template>
  <div
    class="euiBeacon"
    style={{cssStyle
      (hash height=(if @size @size 12) width=(if @size @size 12))
    }}
    ...attributes
  ></div>
</template>;

export default EuiBeacon;

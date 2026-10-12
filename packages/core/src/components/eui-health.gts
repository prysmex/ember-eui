import Component from '@glimmer/component';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiHealthStyles } from '../utils/eui/styles.generated.ts';
import EuiFlexGroup from './eui-flex-group.gts';
import EuiFlexItem from './eui-flex-item.gts';
import EuiIcon from './eui-icon.gts';

import type { SerializedStyles } from '@emotion/serialize';

export const TEXT_SIZES = ['xs', 's', 'm', 'inherit'] as const;

export type EuiHealthTextSize = (typeof TEXT_SIZES)[number];

/** A status: a colored dot followed by text, e.g. "Healthy" or "Down". */
export interface EuiHealthSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Color of the dot: `'success'`, `'warning'`, `'danger'`, `'subdued'`,
     * any `EuiIcon` color or a CSS color.
     */
    color?: string;

    /**
     * Text size: `'xs'`, `'s'`, `'m'` or `'inherit'`. Defaults to `'s'`.
     */
    textSize?: EuiHealthTextSize;
  };
  Blocks: {
    /** The status text. */
    default: [];
  };
}

/** Native Ember health status using the upstream EUI 123 / Borealis styles. */
export default class EuiHealth extends Component<EuiHealthSignature> {
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(
      context,
      euiHealthStyles as (
        ...args: Parameters<typeof euiHealthStyles>
      ) => Record<string, SerializedStyles>
    );
    const size = this.args.textSize;
    const textSize =
      size && (TEXT_SIZES as readonly string[]).includes(size) ? size : 's';

    return `euiHealth ${euiClass(context, styles['euiHealth'], styles[textSize])}`;
  }

  <template>
    <div class={{this.classes}} ...attributes>
      <EuiFlexGroup
        @gutterSize="xs"
        @alignItems="center"
        @responsive={{false}}
      >
        <EuiFlexItem @grow={{false}}>
          <EuiIcon @type="dot" @color={{@color}} />
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          {{yield}}
        </EuiFlexItem>
      </EuiFlexGroup>
    </div>
  </template>
}

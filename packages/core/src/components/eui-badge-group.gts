import { hash } from '@ember/helper';

import argOrDefault from '../helpers/arg-or-default.ts';
import classNames from '../helpers/class-names.ts';

import type { gutterSize } from '../utils/css-mappings/eui-badge-group.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

const BadgeGroupItem: TemplateOnlyComponent<{
  Blocks: {
    default: [];
  };
}> = <template>
  <span class="euiBadgeGroup__item">
    {{yield}}
  </span>
</template>;

export interface EuiBadgeGroupSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Space between the badges, `'xs'` or `'s'`. Defaults to `'xs'`.
     */
    gutterSize?: keyof typeof gutterSize;
  };
  Blocks: {
    /**
     * Wrap each badge in the yielded `item` so the group can space and wrap
     * them: `<group.item><EuiBadge>…</EuiBadge></group.item>`.
     */
    default: [
      {
        item: typeof BadgeGroupItem;
      }
    ];
  };
}

const EuiBadgeGroup: TemplateOnlyComponent<EuiBadgeGroupSignature> = <template>
  <div
    class={{classNames
      componentName="EuiBadgeGroup"
      gutterSize=(argOrDefault @gutterSize "xs")
    }}
    ...attributes
  >
    {{yield (hash item=BadgeGroupItem)}}
  </div>
</template>;

export default EuiBadgeGroup;

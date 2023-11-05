import argOrDefault from '../helpers/arg-or-default';
import { hash } from '@ember/helper';
import classNames from '../helpers/class-names';
import { gutterSize } from '../utils/css-mappings/eui-badge-group';

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
    gutterSize: keyof typeof gutterSize;
  };
  Blocks: {
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

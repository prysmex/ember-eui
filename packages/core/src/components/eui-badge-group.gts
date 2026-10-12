import Component from '@glimmer/component';
import { hash } from '@ember/helper';

import { getEuiThemeContext } from '../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../utils/eui/styles.ts';
import { euiBadgeGroupStyles } from '../utils/eui/styles.generated.ts';

import type { TemplateOnlyComponent } from '@ember/component/template-only';
import type { WithBoundArgs } from '@glint/template';

/**
 * Ember-only wrapper (upstream groups the badges directly). It may shrink to
 * the group's width so long badges truncate instead of overflowing.
 */
const BadgeGroupItem: TemplateOnlyComponent<{
  Args: { class: string };
  Blocks: {
    default: [];
  };
}> = <template>
  <span class="euiBadgeGroup__item {{@class}}">
    {{yield}}
  </span>
</template>;

export interface EuiBadgeGroupSignature {
  Element: HTMLDivElement;
  Args: {
    /**
     * Space between the badges, `'none'`, `'xs'` or `'s'`. Defaults to
     * `'xs'`.
     */
    gutterSize?: 'none' | 'xs' | 's';
  };
  Blocks: {
    /**
     * Wrap each badge in the yielded `item` so the group can space and wrap
     * them: `<group.item><EuiBadge>…</EuiBadge></group.item>`.
     */
    default: [
      {
        item: WithBoundArgs<typeof BadgeGroupItem, 'class'>;
      }
    ];
  };
}

export default class EuiBadgeGroup extends Component<EuiBadgeGroupSignature> {
  get classes(): string {
    const context = getEuiThemeContext(this);
    const styles = useEuiBorealisStyles(context, euiBadgeGroupStyles);
    return euiClass(
      context,
      { boxSizing: 'border-box' },
      styles.euiBadgeGroup,
      styles[this.args.gutterSize ?? 'xs']
    );
  }

  get itemClass(): string {
    return euiClass(getEuiThemeContext(this), {
      boxSizing: 'border-box',
      minInlineSize: 0,
      maxInlineSize: '100%'
    });
  }

  <template>
    <div class="euiBadgeGroup {{this.classes}}" ...attributes>
      {{yield (hash item=(component BadgeGroupItem class=this.itemClass))}}
    </div>
  </template>
}

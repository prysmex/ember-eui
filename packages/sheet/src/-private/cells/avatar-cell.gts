/** The user cell: an `EuiAvatar` (size s) and the name per user, at most three, then "+N". */
import Component from '@glimmer/component';

import EuiAvatar from '@ember-eui/core/components/eui-avatar';
import EuiHighlight from '@ember-eui/core/components/eui-highlight';

import { safeFileUrl } from '../../core/index.ts';
import { MAX_CHIPS } from './chips-cell.gts';

import type { SheetCellSignature } from '../../types.ts';
import type { SheetUser } from '../../core/index.ts';

interface Person {
  key: string;
  label: string;
  imageUrl: string | undefined;
}

export default class AvatarCell extends Component<
  SheetCellSignature<any, any>
> {
  get users(): SheetUser[] {
    const value = this.args.value as SheetUser | SheetUser[] | null;
    if (Array.isArray(value)) return value;
    return value && typeof value === 'object' ? [value] : [];
  }

  get people(): Person[] {
    return this.users.slice(0, MAX_CHIPS).map((user, i) => ({
      key: `${i}:${String(user.id)}`,
      label: String(user.label ?? user.id),
      imageUrl: safeFileUrl(user.avatarUrl)
    }));
  }

  get more(): number {
    return Math.max(0, this.users.length - MAX_CHIPS);
  }

  <template>
    <span class="euiSheet__people">
      {{#each this.people key="key" as |person|}}
        <span class="euiSheet__person" data-test-subj="euiSheetPerson">
          <EuiAvatar
            @size="s"
            @name={{person.label}}
            @imageUrl={{person.imageUrl}}
          />
          <span class="euiSheet__personName">{{#if @highlight}}<EuiHighlight
                @text={{person.label}}
                @search={{@highlight}}
                @highlightAll={{true}}
              />{{else}}{{person.label}}{{/if}}</span>
        </span>
      {{/each}}
      {{#if this.more}}
        <span
          class="euiSheet__more"
          data-test-subj="euiSheetMore"
        >+{{this.more}}</span>
      {{/if}}
    </span>
  </template>
}

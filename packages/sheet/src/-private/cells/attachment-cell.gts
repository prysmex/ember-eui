/**
 * The attachment cell: a thumbnail per file (`thumbnailUrl`, or `url` for an
 * `image/*` file), else a file icon and the name; at most three, then "+N".
 * Only http(s), blob and `data:image/` URLs are used as `src`.
 */
import Component from '@glimmer/component';

import EuiIcon from '@ember-eui/core/components/eui-icon';

import { safeFileUrl } from '../../core/index.ts';
import { MAX_CHIPS } from './chips-cell.gts';

import type { SheetCellSignature } from '../../types.ts';
import type { SheetAttachment } from '../../core/index.ts';

interface Thumb {
  key: string;
  name: string;
  src: string | undefined;
}

export function thumbnailOf(file: SheetAttachment): string | undefined {
  const thumb = safeFileUrl(file.thumbnailUrl);
  if (thumb) return thumb;
  return file.type?.startsWith('image/') ? safeFileUrl(file.url) : undefined;
}

export default class AttachmentCell extends Component<
  SheetCellSignature<any, any>
> {
  get files(): SheetAttachment[] {
    return Array.isArray(this.args.value) ? this.args.value : [];
  }

  get thumbs(): Thumb[] {
    return this.files.slice(0, MAX_CHIPS).map((file, i) => ({
      key: `${i}:${file.id}`,
      name: file.name,
      src: thumbnailOf(file)
    }));
  }

  get more(): number {
    return Math.max(0, this.files.length - MAX_CHIPS);
  }

  <template>
    <span class="euiSheet__files">
      {{#each this.thumbs key="key" as |thumb|}}
        {{#if thumb.src}}
          <img
            class="euiSheet__thumb"
            src={{thumb.src}}
            alt={{thumb.name}}
            title={{thumb.name}}
            draggable="false"
            data-test-subj="euiSheetThumb"
          />
        {{else}}
          <span
            class="euiSheet__file"
            title={{thumb.name}}
            data-test-subj="euiSheetFile"
          ><EuiIcon @type="document" @size="s" /><span
              class="euiSheet__fileName"
            >{{thumb.name}}</span></span>
        {{/if}}
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

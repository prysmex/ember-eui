/**
 * The attachment editor (a panel): the cell's files, each with a link that
 * opens it in a new tab and a remove button, and an `EuiFilePicker` when
 * the field has `upload`. Each removal or finished upload is saved at once
 * and the editor stays open (`@onSave`, `@onUpload`); Escape or focus
 * leaving closes it. The panel is beside the grid, so its buttons and links
 * may be tabbable; the type claims Tab, Enter and Space (`handlesKey`).
 */
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { modifier } from 'ember-modifier';

import EuiButtonIcon from '@ember-eui/core/components/eui-button-icon';
import EuiFilePicker from '@ember-eui/core/components/eui-file-picker';
import EuiIcon from '@ember-eui/core/components/eui-icon';
import EuiPanel from '@ember-eui/core/components/eui-panel';
import EuiProgress from '@ember-eui/core/components/eui-progress';

import { safeFileUrl } from '../../core/index.ts';
import { thumbnailOf } from '../cells/attachment-cell.gts';

import type { SheetAttachment } from '../../core/index.ts';
import type { SheetEditorSignature } from '../../types.ts';

const isNumber = (value: unknown): boolean => typeof value === 'number';

interface Row {
  file: SheetAttachment;
  href: string | undefined;
  thumb: string | undefined;
}

export default class AttachmentEditor extends Component<
  SheetEditorSignature<any, any>
> {
  @tracked uploading = false;
  @tracked failed = false;
  picker: { removeFiles(): void } | null = null;

  get files(): SheetAttachment[] {
    return Array.isArray(this.args.value) ? this.args.value : [];
  }

  get rows(): Row[] {
    return this.files.map((file) => ({
      file,
      href: safeFileUrl(file.url),
      thumb: thumbnailOf(file)
    }));
  }

  get label(): string {
    return this.args.field.label ?? this.args.field.id;
  }

  get accept(): string | undefined {
    return this.args.field['accept'] as string | undefined;
  }

  get messages() {
    return this.args.messages;
  }

  get removeLabel(): string {
    return this.messages.removeFile();
  }

  get addLabel(): string {
    return this.messages.addFiles();
  }

  get failedLabel(): string {
    return this.messages.uploadFailed();
  }

  /** The upload's progress in percent, while the uploader reports one (V03 11.4). */
  get percent(): number | undefined {
    const progress = this.args.progress;
    return progress === undefined ? undefined : Math.round(progress * 100);
  }

  get progressLabel(): string {
    return this.percent === undefined
      ? ''
      : this.messages.uploading(this.percent);
  }

  /** A new array without the file: values are never mutated. */
  remove = (file: SheetAttachment): void => {
    this.args.onSave?.(this.files.filter((f) => f !== file));
  };

  setPicker = (picker: unknown): void => {
    this.picker = picker as { removeFiles(): void };
  };

  onFiles = (list: FileList | null): void => {
    const upload = this.args.onUpload;
    const files = list ? [...list] : [];
    if (!upload || !files.length) return;
    this.uploading = true;
    this.failed = false;
    upload(files).then(
      () => {
        if (this.isDestroying || this.isDestroyed) return;
        this.uploading = false;
        this.picker?.removeFiles();
      },
      () => {
        if (this.isDestroying || this.isDestroyed) return;
        this.uploading = false;
        this.failed = true;
      }
    );
  };

  /** Focus goes into the panel, so the sheet's keys reach the editor. */
  focusFirst = modifier((element: HTMLElement) => {
    const first = element.querySelector<HTMLElement>(
      'input[type=file], button, a[href]'
    );
    (first ?? element).focus();
  });

  <template>
    <div
      class="euiSheet__attachments"
      tabindex="-1"
      aria-label={{this.label}}
      data-test-subj="euiSheetAttachmentEditor"
      {{this.focusFirst}}
    >
      <EuiPanel @paddingSize="s" @hasShadow={{true}}>
        {{#each this.rows as |row|}}
          <div class="euiSheet__attachment" data-test-subj="euiSheetAttachment">
            {{#if row.thumb}}
              <img
                class="euiSheet__thumb"
                src={{row.thumb}}
                alt=""
                draggable="false"
              />
            {{else}}
              <EuiIcon @type="document" @size="m" />
            {{/if}}
            {{#if row.href}}
              <a
                class="euiSheet__attachmentName"
                href={{row.href}}
                target="_blank"
                rel="noopener noreferrer"
              >{{row.file.name}}</a>
            {{else}}
              <span class="euiSheet__attachmentName">{{row.file.name}}</span>
            {{/if}}
            {{#if @onSave}}
              <EuiButtonIcon
                @iconType="cross"
                @size="xs"
                @color="danger"
                aria-label={{this.removeLabel}}
                title={{this.removeLabel}}
                data-test-subj="euiSheetRemoveFile"
                {{on "click" (fn this.remove row.file)}}
              />
            {{/if}}
          </div>
        {{/each}}
        {{#if (isNumber this.percent)}}
          <EuiProgress
            @value={{this.percent}}
            @max={{100}}
            @size="xs"
            @color="primary"
            class="euiSheet__uploadProgress"
            aria-label={{this.progressLabel}}
            title={{this.progressLabel}}
            data-test-subj="euiSheetUploadProgress"
          />
        {{/if}}
        {{#if @onUpload}}
          <EuiFilePicker
            @multiple={{true}}
            @compressed={{true}}
            @fullWidth={{true}}
            @isLoading={{this.uploading}}
            @isInvalid={{this.failed}}
            @initialPromptText={{this.addLabel}}
            @onChange={{this.onFiles}}
            @ref={{this.setPicker}}
            accept={{this.accept}}
            aria-label={{this.addLabel}}
            data-test-subj="euiSheetFilePicker"
          />
          {{#if this.failed}}
            <div
              class="euiSheet__attachmentError"
              role="alert"
              data-test-subj="euiSheetUploadError"
            >{{this.failedLabel}}</div>
          {{/if}}
        {{/if}}
      </EuiPanel>
    </div>
  </template>
}

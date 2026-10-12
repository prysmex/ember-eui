import Component from '@glimmer/component';

import type Owner from '@ember/owner';

import { deprecateUnusedAfterBorealis } from '../../../-private/unused-after-borealis.ts';

/**
 * @private The former task list icon of the markdown toolbar.
 * @deprecated The toolbar uses the upstream `listCheck` icon; removed in 16.0.0.
 */
export interface EuiMarkdownToolbarIconsMarkdownCheckmarkSignature {
  Element: SVGElement;
  Args: {
    /** Accessible title. */
    title?: string;
    /** Id of the title element. */
    titleId?: string;
  };
}

export default class MarkdownCheckmark extends Component<EuiMarkdownToolbarIconsMarkdownCheckmarkSignature> {
  constructor(
    owner: Owner,
    args: EuiMarkdownToolbarIconsMarkdownCheckmarkSignature['Args']
  ) {
    super(owner, args);
    deprecateUnusedAfterBorealis(
      'markdown-checkmark',
      'The markdown toolbar `MarkdownCheckmark` icon component (`eui-markdown-editor-toolbar/icons/markdown-checkmark`) is deprecated. Use `<EuiIcon @type="listCheck" />` instead.'
    );
  }

  <template>
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="16"
      height="16"
      fill="none"
      viewBox="0 0 16 16"
      aria-labelledby={{@titleId}}
      ...attributes
    >
      {{#if @title}}
        <title id={{@titleId}}>{{@title}}</title>
      {{/if}}
      <path
        d="M11.828 13H4.172A1.173 1.173 0 013 11.828V4.172C3 3.526 3.526 3 4.172 3h7.656C12.474 3 13 3.526 13 4.172v7.656c0 .646-.526 1.172-1.172 1.172zM4.172 3.781a.391.391 0 00-.39.39v7.657c0 .216.175.39.39.39h7.656a.39.39 0 00.39-.39V4.172a.391.391 0 00-.39-.39H4.172zm7.244 2.175l-.582-.521L7.22 9.469 5.125 7.476l-.539.566 2.68 2.548 4.15-4.634z"
      ></path>
    </svg>
  </template>
}

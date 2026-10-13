---
order: 7
---

# Understanding max-width

<EuiText>
  <p>
    By default, flyouts will continue to grow with the width of the window. To
    stop this growth at an ideal width, set <EuiCode>@maxWidth</EuiCode> to
    <EuiCode>\{{true}}</EuiCode>, or pass your own custom size.
  </p>
</EuiText>

<EuiSpacer />

<EuiCallOut @title="Caveats" @color="warning" @iconType="warning">
  Note that there are some caveats to providing a
  <EuiCode>@maxWidth</EuiCode> that is smaller than the min-width.
</EuiCallOut>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import { EuiFieldText, EuiFilePicker, EuiFlyout, EuiFlyoutBody, EuiFlyoutHeader, EuiForm, EuiFormRow, EuiLink, EuiRange, EuiSelect, EuiSpacer, EuiText, EuiTitle } from '@ember-eui/core/components';

const NOTE_SMALL = ' -- minWidth wins except for on small screens';
const NOTE_BIG = ' -- minWidth wins and full 100vw wins on small screens';

function option(size, sizeLabel, maxWidth, maxWidthLabel, color = 'success', note = '') {
  return { size, sizeLabel, maxWidth, maxWidthLabel, color, note };
}

export default class FlyoutMaxWidthComponent extends Component {
  @tracked isFlyoutVisible = false;
  @tracked flyoutSize = 'm';
  @tracked flyoutMaxWidth = false;

  selectOptions = [
    { value: 'option_one', text: 'Option one' },
    { value: 'option_two', text: 'Option two' },
    { value: 'option_three', text: 'Option three' }
  ];

  groups = [
    [
      option('s', 'small', false, 'no max-width'),
      option('s', 'small', true, 'default max-width'),
      option('s', 'small', 200, 'smaller custom max-width', 'danger', NOTE_SMALL),
      option('s', 'small', 448, 'larger custom max-width', 'danger', NOTE_SMALL)
    ],
    [
      option('m', 'medium', false, 'no max-width'),
      option('m', 'medium', true, 'default max-width'),
      option('m', 'medium', 448, 'smaller custom max-width', 'danger', NOTE_BIG),
      option('m', 'medium', 900, 'larger custom max-width')
    ],
    [
      option('l', 'large', false, 'no max-width'),
      option('l', 'large', true, 'default max-width'),
      option('l', 'large', 448, 'smaller custom max-width', 'danger', NOTE_BIG),
      option('l', 'large', 1600, 'larger custom max-width')
    ],
    [
      option(240, '240', false, 'no max-width'),
      option(240, '240', true, 'default max-width'),
      option(240, '240', 110, 'smaller custom max-width', 'danger', ' -- max-width wins but width wins on small screens'),
      option(240, '240', 1600, 'larger custom max-width')
    ]
  ];

  get maxWidthTitle() {
    switch (this.flyoutMaxWidth) {
      case true:
        return 'Default';
      case false:
        return 'No';
      default:
        return `${this.flyoutMaxWidth}px`;
    }
  }

  @action
  showFlyout(size, maxWidth) {
    this.flyoutSize = size;
    this.flyoutMaxWidth = maxWidth;
    this.isFlyoutVisible = true;
  }

  @action
  closeFlyout() {
    this.isFlyoutVisible = false;
  }

  <template>
  {{#each this.groups as |group|}}
    {{#each group as |option|}}
      <EuiLink @color={{option.color}} {{on "click" (fn this.showFlyout option.size option.maxWidth)}}>
        Show <strong>{{option.sizeLabel}}</strong> flyout with
        <strong>{{option.maxWidthLabel}}</strong>{{option.note}}
      </EuiLink>
      <EuiSpacer @size="s" />
    {{/each}}
    <EuiSpacer />
  {{/each}}

  <EuiLink @color="primary" {{on "click" (fn this.showFlyout "m" 0)}}>
    Trick for forms: <strong>Medium</strong> flyout with
    <strong>0 as max-width</strong>
  </EuiLink>

  {{#if this.isFlyoutVisible}}
    <EuiFlyout
      @ownFocus={{true}}
      @onClose={{this.closeFlyout}}
      @size={{this.flyoutSize}}
      @maxWidth={{this.flyoutMaxWidth}}
      aria-labelledby="maxWidthFlyoutTitle"
    >
      <EuiFlyoutHeader @hasBorder={{true}}>
        <EuiTitle @size="m" id="maxWidthFlyoutTitle">{{this.maxWidthTitle}} maxWidth</EuiTitle>
      </EuiFlyoutHeader>
      <EuiFlyoutBody>
        <EuiText>
          <p>
            In many cases, you&rsquo;ll want to set a custom width that&rsquo;s
            tailored to your content. In this case, the flyout is an ideal width
            for form elements.
          </p>
        </EuiText>

        <EuiSpacer />

        <EuiForm @component="form">
          <EuiFormRow @label="Text field" @helpText="I am some friendly help text.">
            <EuiFieldText name="first" />
          </EuiFormRow>

          <EuiFormRow @label="Select (with no initial selection)">
            <EuiSelect @hasNoInitialSelection={{true}} @options={{this.selectOptions}} />
          </EuiFormRow>

          <EuiFormRow @label="File picker">
            <EuiFilePicker />
          </EuiFormRow>

          <EuiFormRow @label="Range">
            <EuiRange @min={{0}} @max={{100}} @name="range" @id="maxWidthFlyoutRange" @value={{50}} />
          </EuiFormRow>
        </EuiForm>
      </EuiFlyoutBody>
    </EuiFlyout>
  {{/if}}
  </template>
}
```

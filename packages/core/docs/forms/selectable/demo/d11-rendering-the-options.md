---
order: 11
---

# Rendering the options

<EuiText>

There are two object properties you can add to enhance the content of your options, `option.prepend` and `option.append`. These will add text before and after the option label respectively. They will not be included in the searchable content, as this only matches against the label. For markup, use the `<:optionPrepend>` and `<:optionAppend>` blocks.

### Selection icons

You can choose not to display the check and cross icons indicating selection by setting `@listProps.showIcons` to false. This is useful for instances that navigate elsewhere on selection or hide their selected options from the list.

### Group labels

An option is allowed to be passed that is just a header for the options that follow it. It takes no mouse handlers and renders similar to a title. Add one of these by setting `option.isGroupLabel` to true.

### Row height and virtualization

When virtualization is on, **every row must be the same height** in order for the list to know how to scroll to the selected or highlighted option. It applies `@listProps.rowHeight` (in pixels) directly to each option, hiding any overflow.

If `@listProps.isVirtualized` is set to `false`, each row will fit its content. You can also remove truncation by setting `textWrap: 'wrap'` when virtualization is off. Ember EUI renders every option either way (it has no react-window); "virtualized" means fixed row heights and a computed list height.

### Custom content

While it is best to stick to `option.label`, `option.append`, `option.prepend` and `@listProps.showIcons`, you can pass an `<:option>` block, which is called with the option and the search value for highlighting.

To provide data that can be used by the `<:option>` block that does not match the standard option API, use `option.data`, which is available on the yielded option. See the `secondaryContent` configuration in the following example; `searchableLabel` makes it searchable too.

Also, if your custom content is taller than the default `@listProps.rowHeight` of 32px, you will need to pass in a custom value to this argument.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { EuiBadge, EuiHighlight, EuiSelectable, EuiSpacer, EuiSwitch, EuiText } from '@ember-eui/core/components';

const countryData = [
  { code: 'NL', name: 'Netherlands', flag: '🇳🇱' },
  { code: 'CZ', name: 'Czech Republic', flag: '🇨🇿' },
  { code: 'ZA', name: 'South Africa', flag: '🇿🇦' },
  { code: 'US', name: 'United States', flag: '🇺🇲' },
  { code: 'AU', name: 'Australia', flag: '🇦🇺' },
  { code: 'IL', name: 'Israel', flag: '🇮🇱' },
  { code: 'NO', name: 'Norway', flag: '🇳🇴' },
  { code: 'IT', name: 'Italy', flag: '🇮🇹' },
  { code: 'CA', name: 'Canada', flag: '🇨🇦' },
  { code: 'CG', name: 'Congo', flag: '🇨🇬' },
  { code: 'CL', name: 'Chile', flag: '🇨🇱' },
  { code: 'FJ', name: 'Fiji', flag: '🇫🇯' },
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧' },
  { code: 'GR', name: 'Greece', flag: '🇬🇷' },
  { code: 'HT', name: 'Haiti', flag: '🇭🇹' },
  { code: 'LB', name: 'Lebanon', flag: '🇱🇧' },
  { code: 'MM', name: 'Myanmar', flag: '🇲🇲' },
  { code: 'MX', name: 'Mexico', flag: '🇲🇽' },
  { code: 'NG', name: 'Nigeria', flag: '🇳🇬' },
  { code: 'SG', name: 'Singapore', flag: '🇸🇬' },
  { code: 'SO', name: 'Somalia', flag: '🇸🇴' },
  { code: 'TN', name: 'Tunisia', flag: '🇹🇳' },
  { code: 'VE', name: 'Venezuela', flag: '🇻🇪' },
  { code: 'ZM', name: 'Zambia', flag: '🇿🇲' },
];


export default class SelectableRenderingDemo extends Component {
  @tracked useCustomContent = true;
  @tracked isVirtualized = true;
  @tracked options = [
    { label: 'Country options', isGroupLabel: true },
    ...countryData.map((country) => ({
      label: country.name,
      searchableLabel: `${country.name} I am secondary content, I am!`,
      prepend: country.flag,
      code: country.code,
      data: { secondaryContent: 'I am secondary content, I am!' },
    })),
  ];

  get listProps() {
    return {
      isVirtualized: this.isVirtualized,
      rowHeight: this.useCustomContent ? 57 : undefined,
      showIcons: false,
    };
  }

  @action
  setIsVirtualized(event) {
    this.isVirtualized = event.target.checked;
  }

  @action
  setOptions(options) {
    this.options = options;
  }

  @action
  setUseCustomContent(event) {
    this.useCustomContent = event.target.checked;
  }

  <template>
    <EuiSwitch
      @label="Virtualized"
      @checked={{this.isVirtualized}}
      @onChange={{this.setIsVirtualized}}
    />
    &emsp;&emsp;
    <EuiSwitch
      @label="Custom content"
      @checked={{this.useCustomContent}}
      @onChange={{this.setUseCustomContent}}
    />
    <EuiSpacer />
    <EuiSelectable
      aria-label="Selectable example with custom list items"
      @searchable={{true}}
      @options={{this.options}}
      @onChange={{this.setOptions}}
      @listProps={{this.listProps}}
      @height={{240}}
    >
      <:optionAppend as |option|>
        {{#if option.code}}<EuiBadge>{{option.code}}</EuiBadge>{{/if}}
      </:optionAppend>
      <:option as |option search|>
        <EuiHighlight @text={{option.label}} @search={{search}} />
        {{#if this.useCustomContent}}
          <EuiText @size="xs" @color="subdued" class="eui-displayBlock">
            <small><EuiHighlight @text={{option.data.secondaryContent}} @search={{search}} /></small>
          </EuiText>
        {{/if}}
      </:option>
    </EuiSelectable>
  </template>
}
```

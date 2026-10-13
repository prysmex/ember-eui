---
order: 10
---

# Locale

<EuiText>

Locale formatting is achieved by using `@locale`, `@timeFormat`, and `@dateFormat`. The latter will take any `moment()` notation. Check [Date format by country](https://en.wikipedia.org/wiki/Date_format_by_country) for more information on locale formats.

Moment will try to load the locale on demand when it is used. Bundlers that do not support dynamic require statements will need to explicitly import the locale, e.g. `import 'moment/locale/zh-cn'`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { hash } from '@ember/helper';
import {
  EuiButtonGroup,
  EuiComboBox,
  EuiFlexGroup,
  EuiFlexItem,
  EuiSpacer,
  EuiSuperDatePicker,
} from '@ember-eui/core/components';

const LOCALES = [
  { id: 'locale-en', label: 'en' },
  { id: 'locale-zh', label: 'zh-CN' },
  { id: 'locale-ja', label: 'ja-JP' },
  { id: 'locale-fr', label: 'fr-FR' },
];

const DATE_FORMATS = [
  { label: 'MMM D, YYYY @ HH:mm:ss.SSS' },
  { label: 'dddd, MMMM Do YYYY, h:mm:ss a' },
  { label: 'YYYY-MM-DDTHH:mm:ss.SSSZ' },
];

export default class SuperDatePickerLocaleDemo extends Component {
  locales = LOCALES;
  dateFormats = DATE_FORMATS;

  @tracked start = 'now-1h';
  @tracked end = 'now-15m';
  @tracked locale;
  @tracked localeSelected = LOCALES[0].id;
  @tracked dateFormat;
  @tracked dateFormatsSelected = [DATE_FORMATS[0]];

  @action
  onTimeChange({ start, end }) {
    this.start = start;
    this.end = end;
  }

  @action
  onLocaleChange(optionId) {
    this.locale = LOCALES.find(({ id }) => id === optionId).label;
    this.localeSelected = optionId;
  }

  @action
  onDateFormatChange(selectedOptions) {
    this.dateFormat = selectedOptions.length ? selectedOptions[0].label : '';
    this.dateFormatsSelected = selectedOptions;
  }

  @action
  onDateFormatCreate(searchValue) {
    const normalizedSearchValue = searchValue.trim().toLowerCase();

    if (!normalizedSearchValue) return;

    this.dateFormat = searchValue;
    this.dateFormatsSelected = [{ label: searchValue }];
  }

  <template>
    <EuiFlexGroup @alignItems="center">
      <EuiFlexItem @grow={{false}}>
        <EuiButtonGroup
          @legend="Locale"
          @options={{this.locales}}
          @idSelected={{this.localeSelected}}
          @onChange={{this.onLocaleChange}}
        />
      </EuiFlexItem>
      <EuiFlexItem>
        <EuiComboBox
          @placeholder="Select a dateFormat"
          @customOptionText="Add {searchText} as a dateFormat"
          @singleSelection={{hash asPlainText=true}}
          @options={{this.dateFormats}}
          @searchField="label"
          @selectedOptions={{this.dateFormatsSelected}}
          @onChange={{this.onDateFormatChange}}
          @onCreateOption={{this.onDateFormatCreate}}
          as |option|
        >
          {{option.label}}
        </EuiComboBox>
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer />
    <EuiSuperDatePicker
      @showUpdateButton={{false}}
      @start={{this.start}}
      @end={{this.end}}
      @locale={{this.locale}}
      @dateFormat={{this.dateFormat}}
      @onTimeChange={{this.onTimeChange}}
    />
  </template>
}
```

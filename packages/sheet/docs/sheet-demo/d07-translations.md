---
order: 7
---

# Translations

<EuiText>

The sheet's messages go through `@ember-eui/core`'s `euiI18n` service,
like EUI's own texts, with the tokens `euiSheet.required`,
`euiSheet.notANumber` and so on (`sheetMessageTokens` lists them with
their English defaults). An app adds its translations once, e.g. in the
application route. `@messages` wins over the translations, for one
sheet:

```js
this.euiI18n.addTranslations({
  euiSheet: { required: 'Obligatorio', notANumber: '"{text}" no es un número' },
});
```

```hbs
<EuiSheet @messages={{hash required=this.missing}} … />
```

The service is global, so this demo adds the Spanish texts while
**Español** is on and puts the English ones back when it is off (and
when you leave the page); another sheet on the page also uses them
meanwhile. The service's translations are not tracked: the demo
re-creates its sheet when the language changes. Hover the red cells,
or paste `abc` on Quantity.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { service } from '@ember/service';
import { EuiButtonGroup, EuiFlexGroup, EuiFlexItem, EuiSpacer, EuiSwitch } from '@ember-eui/core/components';
import { EuiSheet, localRecords, sheetMessageTokens } from '@ember-eui/sheet';

const SPANISH = {
  required: 'Obligatorio',
  notANumber: '"{text}" no es un número',
  notACheckbox: '"{text}" no es un valor de casilla',
  notAnOption: '"{text}" no es una opción',
  notADate: '"{text}" no es una fecha',
  min: 'Debe ser {min} o más',
  max: 'Debe ser {max} o menos',
  maxLength: 'Debe tener {max} caracteres o menos',
  pattern: 'Formato no válido',
  unresolved: 'No se encontró "{text}"',
};

// the English defaults, to put back
const ENGLISH = Object.fromEntries(
  Object.entries(sheetMessageTokens).map(([name, { defaultMessage }]) => [name, defaultMessage]),
);

const FIELDS = [
  { id: 'item', label: 'Item', required: true },
  { id: 'quantity', label: 'Quantity', type: 'number', min: 1, max: 50 },
  {
    id: 'unit',
    label: 'Unit',
    type: 'singleSelect',
    options: [
      { value: 'pz', label: 'Pieces' },
      { value: 'box', label: 'Boxes' },
    ],
  },
  { id: 'due', label: 'Due', type: 'date', max: '2026-12-31' },
];

const RECORDS = [
  { id: 't1', item: 'Gloves', quantity: 0, unit: 'pz', due: '2026-11-30' },
  { id: 't2', item: '', quantity: 12, unit: 'kg', due: '2027-01-15' },
  { id: 't3', item: 'Masks', quantity: 80, unit: 'box', due: null },
];

const LANGUAGES = [
  { id: 'en', label: 'English' },
  { id: 'es', label: 'Español' },
];

export default class SheetTranslations extends Component {
  @service euiI18n;

  @tracked language = 'en';
  @tracked override = false;

  languages = LANGUAGES;
  getId = (record) => record.id;
  store = localRecords(RECORDS, { getRecordId: this.getId });
  missing = () => 'Falta este dato';

  // one item per language: a new language re-creates the sheet
  get sheets() {
    return [this.language];
  }

  get messages() {
    return this.override ? { required: this.missing } : undefined;
  }

  setLanguage = (language) => {
    this.euiI18n.addTranslations({ euiSheet: language === 'es' ? SPANISH : ENGLISH });
    this.language = language;
  };

  toggleOverride = (event) => {
    this.override = event.target.checked;
  };

  willDestroy() {
    super.willDestroy();
    if (this.language === 'es') this.euiI18n.addTranslations({ euiSheet: ENGLISH });
  }

  <template>
    <EuiFlexGroup @gutterSize='m' @alignItems='center' @responsive={{false}} @wrap={{true}}>
      <EuiFlexItem @grow={{false}}>
        <EuiButtonGroup
          @legend='Language'
          @options={{this.languages}}
          @idSelected={{this.language}}
          @onChange={{this.setLanguage}}
          @buttonSize='compressed'
        />
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiSwitch
          @label='@messages: required is "Falta este dato"'
          @checked={{this.override}}
          @onChange={{this.toggleOverride}}
          @compressed={{true}}
        />
      </EuiFlexItem>
    </EuiFlexGroup>
    <EuiSpacer @size='s' />
    {{#each this.sheets key='@identity' as |language|}}
      <EuiSheet
        lang={{language}}
        @fields={{FIELDS}}
        @records={{this.store.records}}
        @getRecordId={{this.getId}}
        @onChange={{this.store.apply}}
        @messages={{this.messages}}
        @height={{200}}
        @ariaLabel='Supplies'
      />
    {{/each}}
  </template>
}
```

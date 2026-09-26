<EuiSpacer/>
<EuiPageHeader @pageTitle="Pikaday"/>
<EuiSpacer @size="l" />

<EuiText>

`@ember-eui/pikaday` is a date input with a
[Pikaday](https://github.com/Pikaday/Pikaday) calendar (through
ember-pikaday), styled as an EUI text field.

```bash
pnpm add @ember-eui/pikaday moment
```

Load the calendar's styles once, e.g. in `app/app.js`:

```js
import '@ember-eui/pikaday/pikaday.css';
```

```hbs
<EuiFormRow @label="Due date">
  <EuiPikaday @value={{this.dueDate}} @onSelection={{this.setDueDate}} @format="YYYY-MM-DD" />
</EuiFormRow>
```

`@value` is a `Date`; `@onSelection` receives the chosen `Date` (or
`null` when cleared). `@format` is a moment format, `@minDate` /
`@maxDate` limit the choice, and `@i18n` translates the calendar. It also
takes `EuiFieldText`'s args (`@clear`, `@isInvalid`, `@compressed`, …).

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiPikaday

A date input with a Pikaday calendar, styled as an EuiFieldText (its
args, like `@clear`, `@compressed` or `@isInvalid`, apply too). Load the
calendar's styles with `import '@ember-eui/pikaday/pikaday.css'`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@format` | `string` | `'DD.MM.YYYY'` | moment format of the date in the input. |
| `@value` | `Date` |  | The selected date. Update it in `@onSelection`. |
| `@yearRange` | `string` |  | Years in the year dropdown: a number of years around the current one (`'10'`, the default), or a range `'1990,2030'` (`'1990,currentYear'` ends at this year). |
| `@i18n` | `{ t: (key: string) => string; }` |  | Translations: Pikaday's i18n object (`{ previousMonth, nextMonth, months, weekdays, weekdaysShort }`), or `{ t }` with a function looking these keys up (e.g. ember-intl's `t`, with comma separated lists for months and weekdays). |
| `@firstDay` | `string` | `1` (Monday) | First day of the week, `'0'` (Sunday) to `'6'`. |
| `@onClose` | `() => void` |  | Called when the calendar closes. |
| `@onOpen` | `() => void` |  | Called when the calendar opens. |
| `@onDraw` | `() => void` |  | Called when the calendar redraws (e.g. changing month). |
| `@onSelection` | `(date: Date \| null) => void` |  | Called with the selected `Date`, or `null` when the input is cleared. Update `@value` here. |
| `@register` | `(pikaday: any) => void` |  | Called with the Pikaday instance, e.g. to call its methods. |
| `@defaultDate` | `Date` |  | Date shown when there is no `@value`. |
| `@minDate` | `Date` |  | Earliest selectable date. |
| `@maxDate` | `Date` |  | Latest selectable date. |
| `@theme` | `string` |  | Class added to the calendar, for custom themes. |
| `@container` | `HTMLElement` |  | Element to render the calendar in (instead of `<body>`). |
| `@bound` | `boolean` |  | Positions the calendar under the input (`true`, the default) or renders it inline where `@container` is. |
| `@moment` | `any` |  | The `moment` instance to parse and format dates with. |

Also takes the args of `EuiFieldText`.

| Block | Description |
| --- | --- |
| `<:prepend>` | Content before the input; yields the class to put on it and the input id. |
| `<:append>` | Content after the input; yields the class to put on it and the input id. |

</EuiText>
<!-- api:end -->

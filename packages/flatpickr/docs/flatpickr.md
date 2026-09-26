<!-- empty on purpose -->

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiFlatpickr

EUI text field wired to flatpickr (https://flatpickr.js.org): a date,
time, date range or multiple dates picker. Load flatpickr's styles once,
e.g. `import 'flatpickr/dist/flatpickr.css'` in `app/app.js`.

Arguments:
- `@date` (required): the selected date(s): a `Date`, a string in
  `@dateFormat`, an array for ranges / multiple dates, or `null`.
- `@onChange` (required, or `null`): called with
  `(selectedDates: Date[], dateStr: string, instance)`; update `@date`.
- `@onOpen`, `@onClose`, `@onReady`: flatpickr's hooks, same arguments.
- `@locale`: a flatpickr locale object, or a key such as `'es'` (loaded
  lazily). Changing it recreates the picker.
- `@disabled`: disables the input.
- `@clear`: shows a clear button (while there is a `@date`) calling
  `@clear(null)`.
- `@ariaLabel`: accessible label of the input.
- Any other flatpickr option is passed through, e.g. `@mode` (`'single'`,
  `'multiple'`, `'range'`), `@enableTime`, `@noCalendar`, `@dateFormat`,
  `@altInput` / `@altFormat` / `@altInputClass`, `@minDate`, `@maxDate`,
  `@inline`, `@weekNumbers`. `@minDate`, `@maxDate`, `@altFormat`,
  `@altInputClass` and `@date` also update a rendered picker.
- EuiFieldText's args style the input: `@icon` (defaults to
  `'calendar'`), `@fullWidth`, `@compressed`, `@isInvalid`,
  `@isLoading`, `@readOnly`, `@controlOnly`, `@inputRef`, `@id`, plus the
  `<:prepend>` / `<:append>` blocks.

`@wrap` is not supported.

</EuiText>
<!-- api:end -->

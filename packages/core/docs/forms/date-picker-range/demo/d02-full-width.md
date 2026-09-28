---
order: 2
---

# Full width and read only

<EuiText>

`@fullWidth` lets it grow past its 400px maximum; `@readOnly` gives it the
read-only background (make the inputs `readonly` too).

</EuiText>

```hbs template
<EuiDatePickerRange @fullWidth={{true}}>
  <:start as |className|>
    <EuiFieldText @controlOnly={{true}} type="date" class={{className}} aria-label="Start date" />
  </:start>
  <:end as |className|>
    <EuiFieldText @controlOnly={{true}} type="date" class={{className}} aria-label="End date" />
  </:end>
</EuiDatePickerRange>
<EuiSpacer />
<EuiDatePickerRange @readOnly={{true}}>
  <:start as |className|>
    <EuiFieldText @controlOnly={{true}} @value="2026-01-01" readonly type="date" class={{className}} aria-label="Start date" />
  </:start>
  <:end as |className|>
    <EuiFieldText @controlOnly={{true}} @value="2026-12-31" readonly type="date" class={{className}} aria-label="End date" />
  </:end>
</EuiDatePickerRange>
```

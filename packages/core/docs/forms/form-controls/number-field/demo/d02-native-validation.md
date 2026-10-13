---
order: 2
---

# Native validation

<EuiText>

When passed the `@min`, `@max` or `@step` arguments, `EuiFieldNumber` will automatically show an invalid/error state if the user inputs a number outside the `@min`/`@max` range, or a number that is not a multiple of `@step`.

Any native error messages will be visible as a browser tooltip on mouseover.

</EuiText>

```hbs template
<EuiFormRow @label="Number validation" @helpText="Must be between 0 and 20, and a multiple of 5.">
  <EuiFieldNumber
    placeholder="Try typing an invalid number, e.g. 3, or 30"
    @min={{0}}
    @max={{20}}
    @step={{5}}
    aria-label="EuiFieldNumber with native validation"
  />
</EuiFormRow>
```

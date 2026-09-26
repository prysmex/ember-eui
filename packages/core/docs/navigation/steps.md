<EuiSpacer/>
<EuiPageHeader @pageTitle="Steps"/>
<EuiSpacer @size="l" />

<EuiText>

Steps guide users through a sequence:

- **`EuiSteps`** lists numbered `EuiStep`s vertically, e.g. setup
  instructions. Each step has a `@title` and its content; `@status`
  marks it `complete`, `incomplete` or `disabled`.
- **`EuiStepsHorizontal`** shows the steps of a wizard as clickable
  `EuiStepHorizontal`s, with the current one `@isSelected`.

```hbs
<EuiSteps>
  <EuiStep @step={{1}} @title="Install the agent" @status="complete">…</EuiStep>
  <EuiStep @step={{2}} @title="Configure it">…</EuiStep>
</EuiSteps>
```

`EuiSubSteps` is a shaded box inside a step for nested instructions.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiSteps

A vertical list of numbered steps (`EuiStep`), e.g. setup instructions.

| Block | Description |
| --- | --- |
| default block | The `EuiStep`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiStep

One step of an EuiSteps list.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@step` (required) | `number` |  | The step's number, shown in its circle. |
| `@title` (required) | `string` |  | The step's title. |
| `@status` | `'incomplete' \| 'complete' \| 'disabled'` | the number | `'complete'` shows a check, `'incomplete'` a hollow circle, `'disabled'` greys it out. |
| `@titleSize` |  | `'s'` | Size of the title: `'xs'`, `'s'` or `'m'`. |
| `@headingElement` | `'h1' \| 'h2' \| 'h3' \| 'h4' \| 'h5' \| 'h6' \| 'p'` | `'p'` | Tag of the title, e.g. `'h3'`. |

| Block | Description |
| --- | --- |
| default block | The step's instructions, e.g. text, code blocks or EuiSubSteps. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiSubSteps

A shaded box inside an EuiStep for nested instructions.

| Block | Description |
| --- | --- |
| default block | The content. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiStepsHorizontal

A horizontal progress of steps (`EuiStepHorizontal`), e.g. a wizard's header.

| Block | Description |
| --- | --- |
| default block | The `EuiStepHorizontal`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<ol>`.

### EuiStepHorizontal

One step of an EuiStepsHorizontal, a clickable button.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@title` | `string` |  | The title of the step |
| `@step` | `number` |  | The number of the step |
| `@isSelected` | `boolean` |  | Whether or not the step is selected |
| `@isComplete` | `boolean` |  | Whether or not the step is complete |
| `@disabled` | `boolean` |  | Whether or not the step is disabled |
| `@status` |  | `'incomplete'` | `'complete'`, `'incomplete'`, `'disabled'`, `'loading'`, `'warning'` or `'danger'`. |
| `@onStepClick` | `(event: MouseEvent) => void` |  | A callback for when the step is clicked |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

</EuiText>
<!-- api:end -->

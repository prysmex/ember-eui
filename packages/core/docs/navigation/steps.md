---
title: Steps
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Steps"/>
<EuiSpacer @size="l" />

<EuiText>

Steps guide users through a sequence:

- **`EuiSteps`** lists numbered `EuiStep`s vertically, e.g. setup
  instructions. Each step has a `@title` and its content; `@status`
  marks it `complete`, `incomplete` or `disabled`. Steps are numbered by
  their order, from `@firstStepNumber` (default `1`); `@titleSize` and
  `@headingElement` on `EuiSteps` apply to every step.
- **`EuiStepsHorizontal`** shows the steps of a wizard as clickable
  `EuiStepHorizontal`s, with the current one `@isSelected`.

```hbs
<EuiSteps>
  <EuiStep @title="Install the agent" @status="complete">…</EuiStep>
  <EuiStep @title="Configure it">…</EuiStep>
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

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@firstStepNumber` | `number` | `1` | The number the first step starts from; the following steps count up from it. A step with its own `@step` keeps that number. |
| `@headingElement` | `EuiStepHeadingElement` | `'p'` | Tag of the steps' titles, e.g. `'h3'`. A step's own `@headingElement` wins. |
| `@titleSize` | `EuiStepTitleSize` | `'s'` | Title size of the steps: `'xxs'`, `'xs'`, `'s'` or `'m'`. A step's own `@titleSize` wins. |

| Block | Description |
| --- | --- |
| default block | The `EuiStep`s, numbered automatically by their order. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiStep

One step of an EuiSteps list.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@step` | `number` |  | The step's number, shown in its circle. Inside an `EuiSteps` it defaults to the step's position (from `@firstStepNumber`), otherwise `1`. |
| `@title` (required) | `string` |  | The step's title. |
| `@status` | `EuiStepStatus` | the number | `'complete'` shows a check, `'warning'`/`'danger'` an icon, `'loading'` a spinner, `'incomplete'` a hollow circle, `'current'` an enlarged ringed circle, and `'disabled'` greys it out. |
| `@titleSize` | `EuiStepTitleSize` | `'s'` | Size of the title: `'xxs'` (small dot instead of a number), `'xs'`, `'s'` or `'m'`. |
| `@headingElement` | `EuiStepHeadingElement` | `'p'` | Tag of the title, e.g. `'h3'`. |

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

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@size` | `EuiStepsHorizontalSize` | `'m'` | Size of the steps' numbers and connecting lines: `'xs'` (16px dot), `'s'` (24px) or `'m'` (32px). |

| Block | Description |
| --- | --- |
| default block | The `EuiStepHorizontal`s. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<ol>`.

### EuiStepHorizontal

One step of an EuiStepsHorizontal, a clickable button in an `<li>`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@title` | `string` |  | The title of the step |
| `@step` | `number` | `1` | The number of the step. |
| `@isSelected` | `boolean` |  | Marks the current step (status `'current'`, `aria-current="step"`). Same as `@status="current"`. |
| `@isComplete` | `boolean` |  | Same as `@status="complete"`. |
| `@disabled` | `boolean` |  | Disables the step (status `'disabled'`): clicks are ignored. |
| `@status` | `EuiStepStatus` | `'incomplete'` | `'complete'`, `'current'`, `'incomplete'`, `'disabled'`, `'loading'`, `'warning'` or `'danger'`. |
| `@size` | `EuiStepsHorizontalSize` | the EuiStepsHorizontal's `@size`, else `'m'` | `'xs'`, `'s'` or `'m'`. |
| `@onStepClick` | `(event: MouseEvent) => void` |  | A callback for when the step is clicked (not called while disabled) |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<button>`.

</EuiText>
<!-- api:end -->

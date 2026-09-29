---
title: Tour
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Tour"/>
<EuiSpacer @size="l" />

<EuiText>

A tour walks users through a page step by step: each step is a popover
with a pulsing beacon next to the element it explains, a title, text, the
progress, and a button to skip or end the tour.

```hbs
<EuiTour @initialState={{this.tourState}} @steps={{this.steps}} as |tour|>
  <tour.Step @step={{1}}>
    <EuiFieldSearch aria-label="Search" />
  </tour.Step>
  <tour.Step @step={{2}}>
    <EuiButton>Save</EuiButton>
  </tour.Step>
</EuiTour>
```

```js
tourState = { currentTourStep: 1, isTourActive: true, tourSubtitle: 'Getting started' };
steps = [
  { step: 1, title: 'Search', content: 'Find anything from here.' },
  { step: 2, title: 'Save', content: 'Your changes are kept.' },
];
```

`EuiTour` keeps the tour's state and yields `{ Step, actions, state }`:
`Step` shows when it is the current step, `actions` move through the tour
(`incrementStep`, `decrementStep`, `goToStep`, `finishTour`, `resetTour`),
and `state` has `currentTourStep` and `isTourActive`, e.g. to save the
progress. The `<:footerAction>` block of a step replaces its "Skip tour"
button, e.g. with a "Next" button.

`EuiTourStep` also works on its own, opened with `@isStepOpen`.

</EuiText>

<EuiHorizontalRule />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiTour

A guided tour: a series of `EuiTourStep` popovers shown one at a time.
It keeps the tour's state and yields `{ Step, actions, state }`: render
a `<tour.Step @step={{n}}>` around each element the tour points at, and
move with `tour.actions`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@initialState` (required) | `EuiTourState` |  | Where the tour starts (and whether it runs at first). |
| `@steps` | `EuiTourStepConfig[]` |  | The steps' titles and contents: `[{ step, title, content }]`. Each `<tour.Step @step={{n}}>` uses the entry with its number. Optional when the steps get their text directly. |
| `@stepsTotal` | `number` |  | Number of steps, when `@steps` is not given. |

### EuiTourStep

One step of a guided tour: a popover with a pulsing beacon next to the
element it explains (the block), a title, content, the progress and a
button to skip or end the tour. Render it through `EuiTour`, which opens
the current step, or on its own with `@isStepOpen`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@isStepOpen` | `boolean` | whether it is the tour's current step | Shows the popover. |
| `@step` | `number` | `1` | The step's number (1-based). |
| `@stepsTotal` | `number` |  | Number of steps in the tour, for the progress dots. |
| `@title` | `string` |  | Title of the step. |
| `@subtitle` | `string` |  | Small title above it, e.g. the tour's name. |
| `@content` | `string` |  | Text of the step. Use the `<:content>` block for markup. |
| `@anchorPosition` |  | `'leftUp'` | Where the popover opens. |
| `@minWidth` | `number` | `300` | Minimum width in px. |
| `@maxWidth` | `number` | `600` | Maximum width in px. |
| `@onFinish` | `() => void` |  | Called by the "Skip / End / Close tour" button. |
| `@closePopover` | `() => void` |  | Called when clicking outside or pressing Escape. |
| `@decoration` | `'beacon' \| 'none'` | `'beacon'` | `'beacon'` (a pulsing dot on the arrow) or `'none'`. |

| Block | Description |
| --- | --- |
| default block | The element the step points at. |
| `<:content>` | Markup for the step's content, instead of `@content`. |
| `<:footerAction>` | Replaces the "Skip tour" button, e.g. with "Next" / "Back" buttons. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

### EuiTourStepIndicator

One dot of a tour's progress: `'complete'`, `'active'` or `'incomplete'`.

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@number` (required) | `number` |  | The step's number (1-based). |
| `@status` | `'complete' \| 'active' \| 'incomplete'` |  | `'complete'`, `'active'` or `'incomplete'`. |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<li>`.

</EuiText>
<!-- api:end -->

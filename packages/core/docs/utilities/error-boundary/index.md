---
title: Error boundary
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Error boundary"/>
<EuiSpacer @size="l" />

<EuiText>

Upstream's **EuiErrorBoundary** is a React class component (`componentDidCatch`) that stops a component's render error from taking down the whole app and renders **EuiErrorMessage** in its place: a danger-striped panel with an "Error" title and the error's message and stack. Glimmer has no error boundaries, so Ember EUI ships the fallback, `EuiErrorMessage`, and you render it where an error is caught.

### In a route's error template

Ember's own boundary is the route `error` substate: an error thrown while a route loads (`model`, `beforeModel`, …) renders that route's `error` template (or `application_error`) instead of the page, with the error as `@model`. Pass it to `EuiErrorMessage` with `@error`, which formats it like upstream's boundary does (message, then the stack):

```gjs
// app/templates/users/error.gjs
import { EuiErrorMessage } from '@ember-eui/core/components';

<template>
  <EuiErrorMessage @error={{@model}} />
</template>
```

In production you may prefer a friendlier `EuiEmptyPrompt` and keep `EuiErrorMessage` for development or internal tools; `@errorMessage` takes any text instead of an error.

### Elsewhere

* **Catch errors where they can happen.** A component that can throw while preparing data (parsing, formatting, user supplied callbacks) should catch the error itself and render a message, `EuiErrorMessage` or a specific `EuiCallOut @color="danger"` that helps the user fix it, as upstream recommends for the content inside a boundary.
* **`Ember.onerror` / your error reporter** for errors you cannot recover from; upstream's `onError` callback has no equivalent because nothing catches render errors.

Keep controls that change server side data out of an errored area, as upstream recommends: render the error message instead of the form.

</EuiText>

<EuiSpacer />

<!-- api:start -->
<EuiSpacer @size="xl" />

<EuiText>

## API reference

Generated from the components' TypeScript signatures by
`scripts/generate-api-docs.mjs`.

### EuiErrorMessage

| Argument | Type | Default | Description |
| --- | --- | --- | --- |
| `@errorMessage` | `string` |  | The text to show, as upstream's `errorMessage` (e.g. a message and stack). |
| `@error` | `unknown` |  | Ember EUI: an error to show instead, formatted like upstream's `EuiErrorBoundary` formats a caught error (message and stack). Handy in a route's `error` template: `<EuiErrorMessage @error={{@model}} />`. |
| `@css` | `EuiCss` |  | Extra styles composed last into the panel's class (upstream's `css`). |

HTML attributes and modifiers (`class`, `data-test-*`, `{{on …}}`) are applied to its `<div>`.

</EuiText>
<!-- api:end -->

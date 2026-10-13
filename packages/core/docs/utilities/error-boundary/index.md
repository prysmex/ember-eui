---
title: Error boundary
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Error boundary"/>
<EuiSpacer @size="l" />

<EuiText>

Upstream's **EuiErrorBoundary** is a React class component (`componentDidCatch`) that stops a component's render error from taking down the whole app. Glimmer has no equivalent of an error boundary component, so Ember EUI does not ship one, and there is nothing to import.

Use these instead:

* **Catch errors where they can happen.** A component that can throw while preparing data (parsing, formatting, user supplied callbacks) should catch the error itself and render a specific message that helps the user understand and fix it, for example an `EuiCallOut` with `@color="danger"`. This is the same guidance upstream gives for the content that goes inside a boundary.
* **Route error substates.** An error thrown while a route loads (`model`, `beforeModel`) renders that route's `error` template (or `application_error`) instead of the page. This is Ember's own error boundary: put an `EuiEmptyPrompt` or `EuiCallOut` in it.
* **`Ember.onerror` / your error reporter** for errors you cannot recover from.

Keep controls that change server side data out of an errored area, as upstream recommends: render the error message instead of the form.

</EuiText>

<EuiSpacer />

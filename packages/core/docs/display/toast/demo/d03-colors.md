---
order: 3
---

# Colors

<EuiText>

Each `@color` variant displays a specific visual type toast and renders by default a corresponding icon.

* Use `primary` for general information.
* Use `success` to let the user know that something completed successfully. Show a success message when the program detects that **something completed successfully**.
* Use `warning` to warn the user against decisions they might regret. Show a warning message when the program detects that **something is not behaving right, but it didn't cause any termination.**
* Use `danger` to let the user know that something went wrong. For example if you want to communicate an error. You should show an error message when the issue is **terminal, this doesn't always mean that the operation stops completely, but the task is not complete**.

If you need to use a custom icon, use the `@iconType` argument to override it.

</EuiText>

```gjs component
import { EuiSpacer, EuiToast } from '@ember-eui/core/components';

<template>
<div style='max-width: 320px'>
  <EuiToast @title='3 new messages' @color='primary' />
  <EuiSpacer @size='s' />
  <EuiToast @title='Your report is complete' @color='success' />
  <EuiSpacer @size='s' />
  <EuiToast @title='Node 726 is having trouble' @color='warning' />
  <EuiSpacer @size='s' />
  <EuiToast @title="Couldn't complete the search" @color='danger' />
</div>
</template>
```

---
order: 1
title: Checkbox
---

<EuiPageHeader @pageTitle="Checkbox"/>

<EuiSpacer />

<EuiText>
  <p>
    This component renders a basic HTML <EuiCode @language="html">{{'<input type="checkbox">'}}</EuiCode> element.
    Use checkboxes to allow users to select multiple options from a list.
  </p>
  <p>
    Use the <EuiCode>@checked</EuiCode> argument to handle the checked and
    unchecked state. You can also use the <EuiCode>@indeterminate</EuiCode> argument to set an indeterminate state.
    This state is commonly used in hierarchical checkboxes to indicate that only some of the checkbox's descendants are checked.
  </p>
  <p>
    Make sure to pass a <EuiCode>@label</EuiCode> to ensure a larger
    clickable area and ensure that screen readers will read out the
    label when the user is focused on the input.
    You can also use the <EuiCode>:label</EuiCode> block for a more complex label.
  </p>
</EuiText>

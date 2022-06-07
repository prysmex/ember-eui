---
order: 3
title: Radio
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Radio"/>

<EuiSpacer />

<EuiText>
  <p>
    This component renders a basic HTML <EuiCode @language="html">{{'<input type="radio">'}}</EuiCode> element.
    Use radio buttons to allow users to choose one option out of a list.
    They are ideal for a list of more than 2 options, and usually no more than 6 options.
  </p>
  <p>
    When creating a list, each input should have the same <EuiCode>@name</EuiCode> to ensure a group is established.
    This way when you select a radio button in that group, the other options are automatically deselected.
  </p>
  <p>
    Make sure to pass a <EuiCode>@label</EuiCode> to ensure a larger clickable area and ensure that screen readers will read out the label when the user is focused on the input.
    You can also use the <EuiCode>:label</EuiCode> block for a more complex label.
  </p>
</EuiText>

---
title: Form control layout
---

<EuiPageHeader @pageTitle="Form control layout"/>

<EuiSpacer />

<EuiText>
  <p>
    <EuiBadge @color="warning">Building block only</EuiBadge>
  </p>
  <p>
    <strong>EuiFormControlLayout</strong> is generally used internally
    to consistently style form controls, but it's published in
    case you want to create your own form control which matches those of
    EUI.
  </p>
  <EuiCallOut @title="Additional padding required" @color="warning">
    <:body>
      <p>
      The padding on the <EuiCode>input</EuiCode> itself doesn't
      take into account the presence of the various icons supported by
      <strong>EuiFormControlLayout</strong>. Any input component
      provided to <strong>EuiFormControlLayout</strong> is responsible
      for its own padding.
      </p>
    </:body>
  </EuiCallOut>
</EuiText>

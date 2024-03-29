---
title: Form control layout delimited
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Form control layout delimited"/>

<EuiSpacer />

<EuiText>
  <p>
    <EuiBadge @color="warning">Building block only</EuiBadge>
  </p>

  <p>
    Like <strong>EuiFormControlLayout</strong>,
    <strong>EuiFormControlLayoutDelimited</strong> is generally used
    internally to consistently style form controls. This component
    specifically lays out two form controls with center text or icon.
  </p>
  <p>
    It requires both a <EuiCode>:startControl</EuiCode> and a <EuiCode>:endControl</EuiCode> block.
    You can optionally change the center content to a different string or node (like an EuiIcon).
  </p>
</EuiText>

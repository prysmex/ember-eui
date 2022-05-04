---
title: Accordion
---

<EuiPageHeader @pageTitle="Accordion"/>
<EuiSpacer @size="l" />
<EuiCallOut
  @title='Take care when including flex group content within accordions'>
  <:body>
    <EuiText @size='s'>
      <strong>EuiFlexGroup's</strong>
      negative margins can sometimes create scrollbars within
      <strong>EuiAccordion</strong>
      because of the overflow tricks used to hide content. If you run into this
      issue make sure your paddingSize prop is large enough to account for the
      <EuiCode>gutterSize</EuiCode>
      of any nested flex groups.
    </EuiText>
  </:body>
</EuiCallOut>

<EuiHorizontalRule/>
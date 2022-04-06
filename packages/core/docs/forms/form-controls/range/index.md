---
title: Range
---

<EuiPageHeader>
  <EuiPageHeaderSection>
    <EuiTitle @size="l">
      <h1>
        Range
      </h1>
    </EuiTitle>
  </EuiPageHeaderSection>
</EuiPageHeader>

<EuiSpacer />

<EuiText>
  <EuiCallOut @color="warning" @title="Understanding precision">
    <:body>
      <p>
        Range sliders should only be used when <strong>the precise value is not considered important</strong>.
        If the precise value does matter, add the <EuiCode>@showInput</EuiCode> arg or use a <strong>EuiFieldNumber</strong> instead.
      </p>
    </:body>
  </EuiCallOut>
</EuiText>

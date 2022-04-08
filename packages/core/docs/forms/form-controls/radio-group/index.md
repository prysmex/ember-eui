---
title: Radio group
---

<EuiPageHeader @pageTitle="Radio group"/>

<EuiSpacer />

<EuiText>
  <p>
    This component is different yet simplier from what you'd expect in ember in a way that you don't control the rendering of each checkbox, you just pass in an array of <EuiCode>@options</EuiCode> and <EuiCode>@idSelected</EuiCode> which you are in charge to calculate on subsequent <EuiCode>@onChange</EuiCode>'s, refer to the javascript snippet.
  </p>

  <p>
    You can optionally pass <EuiCode>@valueKey</EuiCode> and <EuiCode>@labelKey</EuiCode> for a more flexible and ergonomic API, so you don't actually have to map your options to
    <EuiCode>{ id: '', label: '' }</EuiCode> which are the default <EuiCode>@valueKey</EuiCode> and <EuiCode>@labelKey</EuiCode>.
  </p>
</EuiText>

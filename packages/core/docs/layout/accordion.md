<EuiPageHeader @pageTitle="Accordion"/>
<EuiCallOut>
  <:body>
    <EuiText>
      Take care when including flex group content within accordions<br />
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

<EuiSpacer />
<EuiTitle>
  Simple and unstyled
</EuiTitle>
<EuiSpacer />

<EuiText>
  <strong>EuiAccordion</strong>
  has been purposely designed with minimal styles, allowing you to visually
  enhance it as needed (see the accordion form example). The only styling
  enforced by EUI is the caret icon, which indicates to users that the item can
  be opened.<br /><br />
  A
  <EuiCode>buttonContent</EuiCode>
  prop defines the content of the clickable area. On click it will expose the
  children and animate based on the height of those children.<br /><br />
  For styling needs, classes can be individually applied with
  <EuiCode>className</EuiCode>
  (for the entire accordion), and
  <EuiCode>buttonClassName</EuiCode>
  (for the clickable area).
</EuiText>
<EuiSpacer />

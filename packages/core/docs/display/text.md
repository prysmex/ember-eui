<EuiPageHeader>
  <EuiPageHeaderSection>
    <EuiTitle @size="l">
      <h1>
        Text
      </h1>
    </EuiTitle>
    <EuiHorizontalRule @margin="m" />
    <EuiSpacer></EuiSpacer>
    <EuiText>
  <p>
<strong>EuiText</strong> is a generic catchall wrapper that will apply our standard typography styling and spacing to naked HTML. Because of its forced style it <strong>only accepts raw XHTML</strong> and can not / should not be used to wrap React components (which would break their styling).

EuiText can ensure proper line-length for readability by setting a <EuiCode>max-width</EuiCode> on the entire component. To add the max-width setting, set <EuiCode>grow=false</EuiCode>.

  </p>
</EuiText>

  </EuiPageHeaderSection>
</EuiPageHeader>

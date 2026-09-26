<EuiText>
  <p>
<strong>EuiTitle</strong> styles the page, section, and content headings we use in Kibana. They can contain any markup, but usually contain a heading tag of some sort. Unlike <strong>EuiText</strong> they are margin neutral and more suitable for general layout design.
  </p>
</EuiText>

```hbs template
<div>
  <EuiTitle @size='l' @tagName="h1">This is a large title, only one should exist per page</EuiTitle>
  <EuiCode @language='js'>size=&quot;l&quot;</EuiCode>

  <EuiSpacer />
  <EuiTitle @tagName="h2">This is the default size for title</EuiTitle>
  <EuiCode @language='js'>size=&quot;m&quot;</EuiCode>

  <EuiSpacer />
  <EuiTitle @size='s' @tagName="h3">This is a small title</EuiTitle>
  <EuiCode @language='js'>size=&quot;s&quot;</EuiCode>

  <EuiSpacer />
  <EuiTitle @size='xs' @tagName="h4">This is an extra small title</EuiTitle>
  <EuiCode @language='js'>size=&quot;xs&quot;</EuiCode>

  <EuiSpacer />
  <EuiTitle @size='xxs' @tagName="h5">This is an extra extra small title</EuiTitle>
  <EuiCode @language='js'>size=&quot;xxs&quot;</EuiCode>

  <EuiSpacer />
  <EuiTitle @size='xxxs' @tagName="h6">This is an extra extra extra small title and should only be used when the
      title is inconsequential (like a label)</EuiTitle>
  <EuiCode @language='js'>size=&quot;xxxs&quot;</EuiCode>

  <EuiHorizontalRule />

  <EuiTitle @size='l'>
    <span>Titles are markup agnostic, they only confer style</span>
  </EuiTitle>
</div>
```

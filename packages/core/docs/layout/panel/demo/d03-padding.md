---
order: 3
---

# Padding

<EuiText>
  <p>
The most basic use is to simply add padding around your content. The preferred padding options are <EuiCode>none</EuiCode>, <EuiCode>s</EuiCode>, <EuiCode>m</EuiCode> (default) and <EuiCode>l</EuiCode>.
  </p>
</EuiText>

```hbs template
<EuiSpacer @size='l' />
<EuiPanel @paddingSize='none'>
  <EuiCode>paddingSize=&quot;none&quot;</EuiCode>
</EuiPanel>
<EuiSpacer @size='l' />
<EuiPanel @paddingSize='s'>
  <EuiCode>paddingSize=&quot;s&quot;</EuiCode>
</EuiPanel>
<EuiSpacer @size='l' />
<EuiPanel @paddingSize='m'>
  <EuiCode>paddingSize=&quot;m&quot; (default)</EuiCode>
</EuiPanel>
<EuiSpacer @size='l' />
<EuiPanel @paddingSize='l'>
  <EuiCode>paddingSize=&quot;l&quot;</EuiCode>
</EuiPanel>
```

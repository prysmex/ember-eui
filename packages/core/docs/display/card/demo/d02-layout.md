---
order: 2
---

# Layout

<EuiText>
<p>At its core an <strong>EuiCard</strong> should contain a <EuiCode @language="text">title</EuiCode>,<EuiCode @language="text">description</EuiCode>, and an <EuiCode @language="text">icon</EuiCode>. You can make the whole card clickable by giving it an <EuiCode @language="text">onClick</EuiCode> handler or <EuiCode @language="text">href</EuiCode>.</p>
</EuiText>

```hbs template
<EuiFlexGroup @gutterSize='l'>

  <EuiFlexItem>
    <EuiCard
      @layout='horizontal'
      @icon='logoBeats'
      @title='logoBeats'
      @iconSize='xl'
      @description="This card adds uses an 'xl' size icon which works well in a horizontal layout."
    />
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard
      @layout='horizontal'
      @icon='logoCloud'
      @iconSize='l'
      @titleSize='xs'
      @title='Elastic Cloud'
      @description="This card uses an 'l' size icon but also shrinks the 'titleSize' to 'xs'."
    />
  </EuiFlexItem>

  <EuiFlexItem>
    <EuiCard
      @layout='horizontal'
      @title='No icon example'
      @description="Example of a card's description. Stick to one or two sentences."
      @href='#'
    />
  </EuiFlexItem>

</EuiFlexGroup>
```

---
order: 1
---

# Images

<EuiText>
<p>Images can be added in place of, or in conjuction with, icons. Just pass a url into the <EuiCode @language="text">image</EuiCode> prop and it will expand to the edges of the card.</p>
</EuiText>

```hbs template
<EuiFlexGroup @gutterSize='l'>
  <EuiFlexItem>
    <EuiCard
      @textAlign='left'
      @title='Elastic in Nature'
      @description="Example of a card's description. Stick to one or two sentences."
      @image='https://source.unsplash.com/400x200/?Nature'
    >
      <:footer>
        <EuiFlexGroup @justifyContent='flexEnd'>
          <EuiFlexItem @grow={{false}}>
            <EuiButton>Go for it</EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:footer>
    </EuiCard>
  </EuiFlexItem>

  <EuiFlexItem>
    <EuiCard
      @textAlign='left'
      @title='Elastic in Nature'
      @description="Example of a card's description. Stick to one or two sentences."
      @image='https://source.unsplash.com/400x200/?Water'
    >

      <:footer>
        <EuiFlexGroup @justifyContent='flexEnd'>
          <EuiFlexItem @grow={{false}}>
            <EuiButton>Go for it</EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:footer>
    </EuiCard>
  </EuiFlexItem>

  <EuiFlexItem>
    <EuiCard
      @textAlign='left'
      @title='Elastic in Nature'
      @description="Example of a card's description. Stick to one or two sentences."
      @image='https://source.unsplash.com/400x200/?Cit'
    />
  </EuiFlexItem>
</EuiFlexGroup>
```

---
order: 2
---

# Images

<EuiText>

Images can be added in place of, or in conjunction with, icons. Just pass a url into the `@image` argument and it will expand to the edges of the card.

</EuiText>
<EuiSpacer />
<EuiCallOut @color="success" @size="s" @title="Make sure that all images are the same proportions when used in a singular row.">
  <p>Ember EUI's <code>@image</code> takes a URL only; upstream also accepts an element.</p>
</EuiCallOut>
<EuiSpacer />

```hbs template
<EuiFlexGroup @gutterSize="l">
  <EuiFlexItem>
    <EuiCard
      @textAlign="left"
      @image="https://picsum.photos/id/13/400/200"
      @title="Elastic in Nature"
      @description="Example of a card's description. Stick to one or two sentences."
    >
      <:footer>
        <EuiFlexGroup @justifyContent="flexEnd">
          <EuiFlexItem @grow={{false}}>
            <EuiButton>Go for it</EuiButton>
          </EuiFlexItem>
        </EuiFlexGroup>
      </:footer>
    </EuiCard>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard
      @textAlign="left"
      @image="https://picsum.photos/400/200"
      @title="Elastic in Water"
      @description="Example of a card's description. Stick to one or two sentences."
      @isDisabled={{true}}
    />
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard
      @textAlign="left"
      @href="https://elastic.github.io/eui/"
      @image="https://picsum.photos/id/57/400/200"
      @icon="logoBeats"
      @iconSize="xxl"
      @title="Beats in the City"
      @description="This card has an href and should be a link."
    />
  </EuiFlexItem>
</EuiFlexGroup>
```

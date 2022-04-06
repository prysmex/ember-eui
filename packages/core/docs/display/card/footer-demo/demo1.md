# Footer

<EuiText>
<p>Footers can contain any number of elements and will always align to the bottom of the card. However, if you supply a footer containing a <strong>EuiButton</strong> you <strong>must not</strong> also give it an <EuiCode @language="text">onClick</EuiCode>.</p>
</EuiText>

```hbs template
<EuiFlexGroup @gutterSize='l'>

  <EuiFlexItem>
    <EuiCard
      @icon='devToolsApp'
      @iconSize='xxl'
      @title='Developers Tools'
      @description='Example of a short card description.'
    >
      <:footer>
        <div>
          <EuiButton @aria-label='Go to Developers Tools'>Go for it</EuiButton>
          <EuiSpacer @size='xs' />
          <EuiText @size='s'>
            <p>
              Or try
              <EuiLink @href='http://google.com'>this</EuiLink>
            </p>
          </EuiText>
        </div>
      </:footer>
    </EuiCard>
  </EuiFlexItem>

  <EuiFlexItem>
    <EuiCard
      @icon='dashboardApp'
      @iconSize='xxl'
      @title='Dashboards'
      @description='Example of a longer card description. See how the footers stay lined up.'
    >
      <:footer>
        <div>
          <EuiButton @aria-label='Go to Developers Tools'>Go for it</EuiButton>
          <EuiSpacer @size='xs' />
          <EuiText @size='s'>
            <p>
              Or try
              <EuiLink @href='http://google.com'>this</EuiLink>
            </p>
          </EuiText>
        </div>
      </:footer>
    </EuiCard>
  </EuiFlexItem>

  <EuiFlexItem>
    <EuiCard
      @icon='savedObjectsApp'
      @iconSize='xxl'
      @title='Save Objects'
      @description='Example of a short card description.'
    >
      <:footer>
        <div>
          <EuiButton @aria-label='Go to Developers Tools'>Go for it</EuiButton>
          <EuiSpacer @size='xs' />
          <EuiText @size='s'>
            <p>
              Or try
              <EuiLink @href='http://google.com'>this</EuiLink>
            </p>
          </EuiText>
        </div>
      </:footer>
    </EuiCard>
  </EuiFlexItem>

</EuiFlexGroup>
```

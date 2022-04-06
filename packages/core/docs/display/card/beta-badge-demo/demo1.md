# Beta Badge

<EuiText>
<p>Footers can contain any number of elements and will always align to the bottom of the card. However, if you supply a footer containing a <strong>EuiButton</strong> you <strong>must not</strong> also give it an <EuiCode @language="text">onClick</EuiCode>.</p>
</EuiText>

```hbs template
<EuiFlexGroup @gutterSize='l'>

  <EuiFlexItem>
    <EuiCard
      @icon='dashboardApp'
      @iconSize='xxl'
      @title='Dashboard'
      @description='Example of a short card description.'
    />
  </EuiFlexItem>

  <EuiFlexItem>
    <EuiCard
      @betaBadgeProps={{hash
        label='Beta'
        tooltipContent='This feature requires a Basic License'
      }}
      @icon='monitoringApp'
      @iconSize='xxl'
      @title='Monitoring'
      @description='Example of a longer card description. See how the footers stay lined up.'
    />
  </EuiFlexItem>

  <EuiFlexItem>
    <EuiCard
      @betaBadgeProps={{hash
        label='Basic'
        tooltipContent='This feature requires a Basic License'
      }}
      @isDisabled={{true}}
      @icon='lensApp'
      @iconSize='xxl'
      @title='Lens'
      @description='Disabled cards can have active links using EuiBetaBadge.'
    />
  </EuiFlexItem>

</EuiFlexGroup>
```

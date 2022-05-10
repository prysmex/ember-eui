---
order: 6
---

# Buttons as links


```hbs template
<EuiFlexGroup @responsive={{false}} @wrap={{true}} @gutterSize="s" @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <EuiButton @href="#/navigation/button">Link to elastic.co</EuiButton>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty @href="#/navigation/button">
      Link to elastic.co
    </EuiButtonEmpty>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButtonIcon
      @href="#/navigation/button"
      @iconType="link"
      aria-label="This is a link"
    />
  </EuiFlexItem>
</EuiFlexGroup>

<EuiFlexGroup @responsive={{false}} @wrap={{true}} @gutterSize="s" @alignItems="center">
  <EuiFlexItem @grow={{false}}>
    <EuiButton @href="#/navigation/button" @isDisabled={{true}}>
      Disabled link
    </EuiButton>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButtonEmpty @href="#/navigation/button" @isDisabled={{true}}>
      Disabled empty link
    </EuiButtonEmpty>
  </EuiFlexItem>

  <EuiFlexItem @grow={{false}}>
    <EuiButtonIcon
      @href="#/navigation/button"
      @iconType="link"
      aria-label="This is a link"
      @isDisabled={{true}}
    />
  </EuiFlexItem>
</EuiFlexGroup>
```
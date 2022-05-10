---
order: 4
---

# Growing height

<EuiText>
  <p>
Using <strong>EuiPanel</strong> in an <strong>EuiFlexItems</strong> will always grow its height to match. This is great for rows of panels. However, you can also turn this feature off by setting <EuiCode>grow={false}</EuiCode>.
  </p>
</EuiText>

```hbs template
<EuiSpacer @size='l' />
<EuiFlexGroup @gutterSize='l'>
  <EuiFlexItem>
    <EuiPanel>
      <EuiText>
        <p>
          I am some panel content...
          <br />
          ...
          <br />
          ...
          <br />
          whose content is tall
        </p>
      </EuiText>
    </EuiPanel>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiPanel @grow={{true}}>
      <EuiText>
        <p>I am some panel content... whose content will grow</p>
      </EuiText>
    </EuiPanel>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiPanel @grow={{false}}>
      <EuiText>
        <p>I am some panel content... whose content did not grow</p>
      </EuiText>
    </EuiPanel>
  </EuiFlexItem>
</EuiFlexGroup>
```

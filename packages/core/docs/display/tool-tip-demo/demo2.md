---
order: 2
---

# Demo

```hbs template
<EuiFlexGroup @alignItems="center" @gutterSize="s" @responsive={{false}}>
 <EuiFlexItem @grow={{false}}>
    <EuiIconTip
      @content="Source maps allow browser dev tools to map minified code to the original source code"
      @position="right"
    />
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiIconTip
  @ariaLabel="Warning"
  @size="xl"
  @type="alert"
  @color="warning"
  @content="I do not think it means what you think it means"
/>
<EuiSpacer />
<EuiText>
  <p>
    Pass a position utility class via iconProps to shift for better alignment.
    <EuiIconTip
      @type="iInCircle"
      @color="subdued"
      @iconProps={{hash className="eui-alignTop"}}
    >
      <:content>
        <span>
          This was passed .eui-alignTop
        </span>
      </:content>
    </EuiIconTip>
  </p>
</EuiText>
```

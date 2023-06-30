---
order: 3
---

# IconTip

<EuiText>
  <p>
You can use <strong>EuiIconTip</strong> to explain options, other controls, or entire parts of the user interface. When possible, surface explanations inline within the UI, and only hide them behind a <strong>EuiIconTip</strong> as a last resort.

It accepts all the same props as <strong>EuiToolTip</strong>. For convenience, you can also specify optional icon <EuiCode>size</EuiCode>, <EuiCode>type</EuiCode>, and <EuiCode>color</EuiCode> props.

  </p>
</EuiText>

```hbs template
<EuiFlexGroup @alignItems='center' @gutterSize='s' @responsive={{false}}>
  <EuiFlexItem @grow={{false}}>
    <EuiIconTip
      @content='Source maps allow browser dev tools to map minified code to the original source code'
      @position='right'
    />
  </EuiFlexItem>
</EuiFlexGroup>
<EuiSpacer />
<EuiIconTip
  @ariaLabel='Warning'
  @size='xl'
  @type='warning'
  @color='warning'
  @content='I do not think it means what you think it means'
/>
<EuiSpacer />
<EuiText>
  <p>
    Pass a position utility class via iconProps to shift for better alignment.
    <EuiIconTip
      @type='iInCircle'
      @color='subdued'
      @iconProps={{hash className='eui-alignTop'}}
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

# Indefinite Progress

<EuiMarkdownFormat @value="Indefinite progress bar is displayed whenever the component DOES NOT have the \`@max\` prop. When in indefinite mode, the component will ignore the \`@value\`, \`@valueText\`, and \`@label\` props you can still define \`@size\` and \`@color\` props."/>

```hbs template
<EuiProgress @color="accent" @size="s" />
<EuiSpacer @size="xl" />
<EuiTitle>
  Colors
</EuiTitle>
<EuiProgress @color="primary" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    primary
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="success" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    Success
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="danger" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    danger
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="warning" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    warning
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="subdued" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    subdued
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="accent" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    accent
  </:label>
</EuiProgress>
<EuiSpacer @size="xl" />
<EuiProgress @color="vis0" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis0
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="vis1" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis1
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="vis2" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis2
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="vis3" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis3
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="vis4" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis4
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="vis4" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis4
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="vis5" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis5
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="vis6" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis6
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="vis7" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis7
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="vis8" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis8
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
<EuiProgress @color="vis9" @size="m" @value="80" @max="100" @valueText={{true}}>
 <:label>
    vis9
  </:label>
</EuiProgress>
<EuiSpacer @size="s" />
```

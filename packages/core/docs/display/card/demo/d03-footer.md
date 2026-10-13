---
order: 3
---

# Footer

<EuiText>

Footers can contain any number of elements and will always align to the bottom of the card. However, if you supply a footer containing a **EuiButton** you **must not** also give it an `@onClick`.

</EuiText>
<EuiSpacer />
<EuiCallOut @color="primary" @iconType="accessibility" @size="s" @title="Accessibility requirement">
  <p>When using footers to display generic "Go" buttons, you must provide an <code>aria-label</code> to the button itself that refers back to the title of the card.</p>
</EuiCallOut>
<EuiSpacer />

```hbs template
<EuiFlexGroup @gutterSize="l">
  <EuiFlexItem>
    <EuiCard
      @icon="devToolsApp"
      @iconSize="xxl"
      @title="Developers Tools"
      @description="Example of a short card description."
    >
      <:footer>
        <div>
          <EuiButton aria-label="Go to Developers Tools">Go for it</EuiButton>
          <EuiSpacer @size="xs" />
          <EuiText @size="s">
            <p>
              Or try
              <EuiLink @href="http://google.com">this</EuiLink>
            </p>
          </EuiText>
        </div>
      </:footer>
    </EuiCard>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard
      @icon="dashboardApp"
      @iconSize="xxl"
      @title="Dashboards"
      @description="Example of a longer card description. See how the footers stay lined up."
    >
      <:footer>
        <div>
          <EuiButton aria-label="Go to Dashboards">Go for it</EuiButton>
          <EuiSpacer @size="xs" />
          <EuiText @size="s">
            <p>
              Or try
              <EuiLink @href="http://google.com">this</EuiLink>
            </p>
          </EuiText>
        </div>
      </:footer>
    </EuiCard>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiCard
      @icon="savedObjectsApp"
      @iconSize="xxl"
      @title="Save Objects"
      @description="Example of a short card description."
    >
      <:footer>
        <div>
          <EuiButton aria-label="Go to Save Objects">Go for it</EuiButton>
          <EuiSpacer @size="xs" />
          <EuiText @size="s">
            <p>
              Or try
              <EuiLink @href="http://google.com">this</EuiLink>
            </p>
          </EuiText>
        </div>
      </:footer>
    </EuiCard>
  </EuiFlexItem>
</EuiFlexGroup>
```

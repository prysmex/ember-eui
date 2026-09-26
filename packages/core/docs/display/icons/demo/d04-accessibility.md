---
order: 4
---

# Accessibility

<EuiText>

Most icons are decorative: they repeat what the text next to them says. Those
need nothing, `EuiIcon` renders them with `aria-hidden="true"`.

An icon that carries meaning on its own needs a name:

- `@title="Error"` renders `<title>Error</title>` inside the svg and labels the
  svg with it (use `@titleId` to choose the id), so it is read by screen
  readers and shown on hover.
- `@aria-label="Error"` names it without a tooltip.
- `@aria-labelledby="some-id"` points at visible text elsewhere.

For a clickable icon use `EuiButtonIcon` with an `aria-label` instead of
adding click handlers to `EuiIcon`.

</EuiText>

```hbs template
<EuiFlexGroup @direction="column" @gutterSize="m">
  <EuiFlexItem>
    <EuiText @size="s">
      <p>
        <EuiIcon @type="checkInCircleFilled" @color="success" />
        Saved (decorative: the text says it all)
      </p>
    </EuiText>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiText @size="s">
      <p>
        <EuiIcon @type="alert" @color="danger" @title="Error" />
        Disk usage (the icon alone says there is a problem, hover it)
      </p>
    </EuiText>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiText @size="s">
      <p>
        <EuiIcon @type="lock" @aria-label="Private" />
        Quarterly report
      </p>
    </EuiText>
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <div>
      <EuiButtonIcon @iconType="trash" @color="danger" aria-label="Delete report" />
    </div>
  </EuiFlexItem>
</EuiFlexGroup>
```

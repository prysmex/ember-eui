---
order: 1
---

# Timeline items

<EuiText>

The default `@gutterSize` is `'xl'`; use `'l'` or `'m'` for denser activity.
Items align their icon and event at the center by default. Use
`@verticalAlign="top"` for multi-line content.

</EuiText>

```hbs template
<EuiTimeline aria-label="Project activity" @gutterSize="l">
  <EuiTimelineItem @icon="plus" @iconAriaLabel="Created">
    Project created
  </EuiTimelineItem>
  <EuiTimelineItem @verticalAlign="top">
    <:icon><EuiAvatar @name="Jane Cooper" @size="m" /></:icon>
    <:default>
      <EuiText @size="s">
        <p><strong>Jane Cooper</strong> added a description.</p>
        <p>The timeline accepts any rich Ember content.</p>
      </EuiText>
    </:default>
  </EuiTimelineItem>
  <EuiTimelineItem @icon="check" @iconAriaLabel="Completed">
    Review completed
  </EuiTimelineItem>
</EuiTimeline>
```

---
order: 1
---

# Screen reader only

<EuiText>

Using <strong>EuiScreenReaderOnly</strong> hides the wrapped content from the page, but keeps it accessible for screen readers to provide more context. It should be used primarily to mask <strong>text</strong>.

<em>Using a screen reader, verify that there is a second paragraph.</em>

</EuiText>

<EuiCallOut @title='WebAIM recommendation for screen reader-only content' @color='warning' @size='s'>
  <p>"In most cases, if content (particularly content that provides functionality or interactivity) is important enough to provide to screen reader users, it should probably be made available to all users." <a href='https://webaim.org/techniques/css/invisiblecontent/' target='_blank' rel='noopener noreferrer'>Learn more about invisible content</a></p>
</EuiCallOut>

<EuiSpacer />

```hbs template
<EuiText>
  <p>This is the first paragraph. It is visible to all.</p>
  <EuiScreenReaderOnly>
    <p>
      This is the second paragraph. It is hidden for sighted users but visible
      to screen readers.
    </p>
  </EuiScreenReaderOnly>
  <p>This is the third paragraph. It is visible to all.</p>
</EuiText>
```

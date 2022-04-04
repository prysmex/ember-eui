---
order: 1
---

# Info

<EuiText>
  <p>
    Use <strong>EuiCallOut</strong> to communicate general information to the user.
  </p>
</EuiText>

```hbs template
<EuiCallOut
  @iconType='search'
  @title="Check it out, here's a really long title that will wrap within a narrower browser"
  @color='primary'
>
  <:body>
    <p>
      Here&rsquo;s some stuff that you need to know. We can make this text
      really long so that, when viewed within a browser that&rsquo;s fairly
      narrow, it will wrap, too.
    </p>
    <p>
      And some other stuff on another line, just for kicks.

    </p>
  </:body>
</EuiCallOut>
<EuiSpacer @size='m' />
<EuiCallOut
  @iconType='lensApp'
  @title='Callouts can exist as just a title. Simply omit the child content.'
  @color='primary'
/>
<EuiSpacer @size='m' />
<EuiCallOut
  @size='s'
  @title='This is a small callout for more unintrusive but constant messages.'
  @iconType='pin'
/>
```

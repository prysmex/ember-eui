# Demo

```hbs template
<EuiTitle @size='m'>
  Info
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Use EuiCallOut to communicate general information to the user.
  </p>
</EuiText>
<EuiSpacer />
<EuiPanel @color='subdued'>
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
</EuiPanel>
<EuiSpacer />

<EuiTitle @size='m'>
  Success
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Use this callout to notify the user of an action that succesfully completed.
    Use success callouts sparingly—callouts are typically used for things that
    are broken rather than things that succeed.
  </p>
</EuiText>
<EuiSpacer />

<EuiPanel @color='subdued'>
  <EuiCallOut
    @size='s'
    @title='This is a small callout for more unintrusive but constant messages.'
    @iconType='pin'
    @color='success'
  ><:body>
      <p>
        I have no news. Which is good!
      </p>

    </:body></EuiCallOut>
</EuiPanel>
<EuiSpacer />

<EuiTitle @size='m'>
  Warning
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Use this callout to warn the user against decisions they might regret.
  </p>
</EuiText>
<EuiSpacer />

<EuiPanel @color='subdued'>
  <EuiCallOut
    @size='s'
    @title='Proceed with caution!'
    @iconType='pin'
    @color='warning'
  ><:body>
      <p>
        Here be dragons. Don’t wanna mess with no dragons.
      </p>
      <EuiButton @color='warning'>
        Link button
      </EuiButton>

    </:body></EuiCallOut>
</EuiPanel>
<EuiSpacer />

<EuiTitle @size='m'>
  Danger
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Use this callout to let the user know that something went wrong.
  </p>
</EuiText>
<EuiSpacer />

<EuiPanel @color='subdued'>
  <EuiCallOut
    @size='s'
    @title='Sorry, there was an error'
    @iconType='pin'
    @color='danger'
  ><:body>
      <p>
        Now you have to fix it, but maybe this link can help.
      </p>

    </:body></EuiCallOut>
</EuiPanel>
<EuiSpacer />
```

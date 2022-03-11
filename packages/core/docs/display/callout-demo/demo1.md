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

<EuiText size='xs'>
  <:body>
    <p>
      Default Small callout H3
    </p>
  </:body>
</EuiText>
<EuiCallOut
  @iconType='searchProfilerApp'
  @title='Good status'
  @heading='h3'
  @color='primary'
  @size='s'
>
  <:body>
    <p>
      All systems check, you are good to go. Good luck!
    </p>
  </:body>
</EuiCallOut>
<EuiSpacer />
<EuiText size='xs'>
  <:body>
    <p>
      Warning Medium callout H3
    </p>
  </:body>
</EuiText>
<EuiCallOut @iconType='alert' @title='INCOMING!' @heading='h3' @color='warning'>
  <:body>
    <p>
      You have an homing rocket coming your way! Take evasive action!
    </p>
  </:body>
</EuiCallOut>
<EuiSpacer />
<EuiText size='xs'>
  <p>
    Danger Medium callout H1
  </p>
</EuiText>
<EuiCallOut
  @iconType='wrench'
  @title='Watch out! Danger close!'
  @heading='h1'
  @color='danger'
  @size='m'
>
  <:body>
    <p>
      You have been hit! Seek the repair ship immediately!
    </p>
  </:body>
</EuiCallOut>
<EuiSpacer />
<EuiText size='xs'>
  <p>
    Success Medium callout H3
  </p>
</EuiText>
<EuiCallOut
  @iconType='bullseye'
  @title="Great, you're ready for deployment!"
  @heading='h3'
  @color='success'
  @size='m'
>
  <:body>
    <p>
      Your ship has been repaired, you are good to launch again. Next time evade
      those missiles!
    </p>
  </:body>
</EuiCallOut>
<EuiSpacer />
<EuiText size='xs'>
  <p>
    Default Callout without block
  </p>
</EuiText>
<EuiCallOut
  @iconType='grid'
  @title='This is a Callout without block!'
  @size='m'
/>
<EuiSpacer />
<EuiText size='xs'>
  <p>
    Default Callout H3 without block or icon
  </p>
</EuiText>
<EuiCallOut @heading='h3' @size='m' @iconType='grid'>
  <:title>
    You can also use block named param for title
  </:title>
</EuiCallOut>
```

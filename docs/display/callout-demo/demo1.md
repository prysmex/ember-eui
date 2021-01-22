# Demo

```hbs template
<EuiText size="xs">
  <:body>
    <p>
      Default Small callout H3
    </p>
  </:body>
</EuiText>
<EuiCallOut
  @iconType="searchProfilerApp"
  @title="Good status"
  @heading="h3"
  @color="primary"
  @size="s"
>
  <:body>
    <p>
      All systems check, you are good to go. Good luck!
    </p>
  </:body>
</EuiCallOut>
<EuiSpacer />
<EuiText size="xs">
  <:body>
    <p>
      Warning Medium callout H3
    </p>
  </:body>
</EuiText>
<EuiCallOut @iconType="alert" @title="INCOMING!" @heading="h3" @color="warning">
  <:body>
    <p>
      You have an homing rocket coming your way! Take evasive action!
    </p>
  </:body>
</EuiCallOut>
<EuiSpacer />
<EuiText size="xs">
  <p>
    Danger Medium callout H1
  </p>
</EuiText>
<EuiCallOut
  @iconType="wrench"
  @title="Watch out! Danger close!"
  @heading="h1"
  @color="danger"
  @size="m"
>
  <:body>
    <p>
      You have been hit! Seek the repair ship immediately!
    </p>
  </:body>
</EuiCallOut>
<EuiSpacer />
<EuiText size="xs">
  <p>
    Success Medium callout H3
  </p>
</EuiText>
<EuiCallOut
  @iconType="bullseye"
  @title="Great, you're ready for deployment!"
  @heading="h3"
  @color="success"
  @size="m"
>
  <:body>
    <p>
      Your ship has been repaired, you are good to launch again. Next time evade those missiles!
    </p>
  </:body>
</EuiCallOut>
<EuiSpacer />
<EuiText size="xs">
  <p>
    Default Callout without block
  </p>
</EuiText>
<EuiCallOut @iconType="grid" @title="This is a Callout without block!" @size="m" />
<EuiSpacer />
<EuiText size="xs">
  <p>
    Default Callout H3 without block or icon
  </p>
</EuiText>
<EuiCallOut @heading="h3" @size="m" @iconType="grid">
  <:title>
    You can also use block named param for title
  </:title>
</EuiCallOut>
```

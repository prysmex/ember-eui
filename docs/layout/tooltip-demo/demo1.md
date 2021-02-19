# Demo

```hbs template
<p><b>EuiTooltip</b> is a wrapper for <a href="https://sir-dunxalot.github.io/ember-tooltips/">Ember Tooltips</a></p>

    <EuiSpacer />

    <EuiTooltip @position="top" @content="Tooltip text">
      I'm a span
    </EuiTooltip>

    <EuiSpacer />

    <EuiTooltip @title="See my title?" @content="And my content?" @position="left">
      <span>Tooltips can have a <b>title</b></span>
    </EuiTooltip>

    <EuiSpacer />

    <EuiTooltip @content="I have a long delay" @position="bottom" @delay="long">
      <div>Hover for a while</div>
    </EuiTooltip>

    <EuiSpacer />

    <EuiTooltip @content="...to the right" @position="right">
      <span>From the windooow</span>
    </EuiTooltip>

    <EuiSpacer />

    <EuiTooltip
      @content="I don't feel so good..."
      @position="right"
      @onMouseOut={{this.onMouseOut}}
    >
      <span>Mr. Stark...</span>
    </EuiTooltip>

    <EuiSpacer />

    <EuiIconTip
      @content="Tooltip text for the icon"
      @position="top"
      @type="logoGolang"
      @size="xl"
    />

```

# EuiShowFor and EuiHideFor

<EuiText>
	<p>
		These components will either render or not render their children based on the current window width. Pass an array of named breakpoints to the <EuiCode>sizes</EuiCode> arg to either show or hide their children respectively.
	</p>
	<p>
		The sizing options correlate with the keys in the <EuiCode>EuiBreakpoints</EuiCode> type. The named breakpoint starts at the pixel value provided and ends before the next one.
	</p>
	<EuiCodeBlock>
'xl': 1200px +
'l': 992px (to 1199px)
'm': 768px (to 991px)
's': 575px (to 767px)
'xs': 0px (to 574px)
	</EuiCodeBlock>
</EuiText>

```hbs template
<EuiText>
  <EuiHideFor @sizes='none'>
    <p>
      Hiding from
      <EuiCode>"none"</EuiCode>
      of the screen sizes
    </p>
  </EuiHideFor>
  <EuiHideFor @sizes={{array 'xs'}}>
    <p>
      Hiding from
      <EuiCode>xs</EuiCode>
      screens only
    </p>
  </EuiHideFor>
  <EuiHideFor @sizes={{array 'xs' 's'}}>
    <p>
      Hiding from
      <EuiCode>xs, s</EuiCode>
      screens
    </p>
  </EuiHideFor>
  <EuiHideFor @sizes={{array 'xs' 's' 'm' 'l'}}>
    <p>
      Hiding from
      <EuiCode>xs, s, m, l</EuiCode>
      screens
    </p>
  </EuiHideFor>
  <EuiHideFor @sizes={{array 'xl'}}>
    <p>
      Hiding from
      <EuiCode>xl</EuiCode>
      screens only
    </p>
  </EuiHideFor>

  <EuiSpacer @size='xxl' />

  <EuiShowFor @sizes="all">
    <p>
      Showing for
      <EuiCode>"all"</EuiCode>
      of the screen sizes
    </p>
  </EuiShowFor>
  <EuiShowFor @sizes={{array 'xs'}}>
    <p>
      Showing for
      <EuiCode>xs</EuiCode>
      screens only
    </p>
  </EuiShowFor>
  <EuiShowFor @sizes={{array 'xs' 's'}}>
    <p>
      Showing for
      <EuiCode>xs, s</EuiCode>
      screens
    </p>
  </EuiShowFor>
  <EuiShowFor @sizes={{array 'xs' 's' 'm' 'l'}}>
    <p>
      Showing for
      <EuiCode>xs, s, m, l</EuiCode>
      screens
    </p>
  </EuiShowFor>
  <EuiShowFor @sizes={{array 'xl'}}>
    <p>
      Showing for
      <EuiCode>xl</EuiCode>
      screen only
    </p>
  </EuiShowFor>
  <EuiShowFor @sizes={{array 'm' 'l' 'xl'}}>
    <p>
      Showing for
      <EuiCode>m, l, xl</EuiCode>
      screen only
    </p>
  </EuiShowFor>
</EuiText>
```

```javascript component
import GlimmerComponent from '@glimmer/component';

export default class extends GlimmerComponent {}
```

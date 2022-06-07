---
order: 1
---

<EuiText>
	<p>
		The <strong>EuiKeyPadMenu</strong> component presents <strong>EuiKeyPadMenuItems</strong> in a tiled format, with a fixed width which will accommodate three items and then wrap.
  </p>

  <p>
  <strong>EuiKeyPadMenu</strong> is just a wrapping element for creating the list elements but you must declare each <strong>EuiKeyPadMenu</strong> component manually and wrap them on li
  </p>

</EuiText>
<EuiSpacer/>

```hbs template
<EuiCallOut @iconType='accessibility' @color='warning'>
  <:body>
    If the menu provides navigation for your application, wrap the EuiKeyPadMenu
    with
    <EuiCode @language='html'>{{this.navCode}}</EuiCode>
  </:body>
</EuiCallOut>

<EuiSpacer />

<nav aria-label='Nav title'>
  <EuiKeyPadMenu>
    <li>
      <EuiKeyPadMenuItem @label='Dashboard'>
        <EuiIcon @type='dashboardApp' @size='l' />
      </EuiKeyPadMenuItem>
    </li>

    <li>
      <EuiKeyPadMenuItem @label='Canvas'>
        <EuiIcon @type='canvasApp' @size='l' />
      </EuiKeyPadMenuItem>
    </li>

    <li>
      <EuiKeyPadMenuItem @isSelected={{true}} @label='Lens'>
        <EuiIcon @type='lensApp' @size='l' />
      </EuiKeyPadMenuItem>
    </li>

    <li>
      <EuiKeyPadMenuItem @isDisabled={{true}} @label='Visualize'>
        <EuiIcon @type='visualizeApp' @size='l' />
      </EuiKeyPadMenuItem>
    </li>

    <li>
      <EuiKeyPadMenuItem @label='Graph'>
        <EuiIcon @type='graphApp' @size='l' />
      </EuiKeyPadMenuItem>
    </li>

    <li>
      <EuiKeyPadMenuItem @label='Advanced Settings'>
        <EuiIcon @type='advancedSettingsApp' @size='l' />
      </EuiKeyPadMenuItem>
    </li>
  </EuiKeyPadMenu>
</nav>
```

```js component
import Component from '@glimmer/component';

export default class DemoSideNavComponent extends Component {
  navCode = "<nav aria-label='Nav title'></nav>";
}
```

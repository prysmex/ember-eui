---
order: 3
---

<EuiText>
	<p>
		If the item links to a module that is not GA (beta, lab, etc), you can add a <EuiCode>betaBadgeLabel</EuiCode> and <EuiCode>betaBadgeTooltipContent</EuiCode> to the card and it will properly create and position an <a href="/docs/core/docs/navigation/key-pad-menu">EuiBetaBadge</a>.
  </p>

  <p>
  Supplying just a label will only show the first letter in the badge but displays the full label to the tooltip. You can also pass an <EuiCode>iconType</EuiCode> to replace the letter.
  </p>

</EuiText>
<EuiSpacer/>

# Beta item

```hbs template
<EuiKeyPadMenu>
  <li>
    <EuiKeyPadMenuItem @label='No beta'>
      <EuiIcon @type='editorStrike' @size='l' />
    </EuiKeyPadMenuItem>
  </li>

  <li>
    <EuiKeyPadMenuItem
      @label='Single letter'
      @betaBadgeTooltipContent='This module is not GA. Please help us by reporting any bugs.'
      @betaBadgeLabel='Beta'
    >
      <EuiIcon @type='editorBold' @size='l' />
    </EuiKeyPadMenuItem>
  </li>
  <li>
    <EuiKeyPadMenuItem
      @label='Icon'
      @betaBadgeLabel='External'
      @betaBadgeTooltipContent='This module is an external app'
      @betaBadgeIconType='popout'
    >
      <EuiIcon @type='editorCodeBlock' @size='l' />
    </EuiKeyPadMenuItem>
  </li>

</EuiKeyPadMenu>
```

```js component
import Component from '@glimmer/component';

export default class DemoSideNavComponent extends Component {}
```

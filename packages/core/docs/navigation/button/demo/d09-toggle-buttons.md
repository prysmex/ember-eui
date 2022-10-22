---
order: 9
---

# Toggle buttons

<EuiText>
<p>You can create a toggle button with any button type like the standard <strong>EuiButton</strong>, <strong>EuiButtonEmpty</strong>, or <strong>EuiButtonIcon</strong>. Use state management to handle the visual differences for on and off. Though there are two <strong>exclusive</strong> situations to consider.</p>
<ol>
	<li>If your button changes its readable <strong>text</strong>, via children or <EuiCode>aria-label</EuiCode>, then there is no additional accessibility concern.</li>
	<li>If your button only changes the <strong>visual</strong> appearance, you must add <EuiCode>aria-pressed</EuiCode> passing a boolean for the on and off states. All EUI button types provide a helper prop for this called <EuiCode>isSelected</EuiCode>.</li>
</ol>

</EuiText>

```hbs template
{{#let
  (use-state false)
  (use-state false)
  (use-state true)
  (use-state false)
  as |toggle0 toggle1 toggle2 toggle3|
}}
  <EuiButton {{on 'click' (fn toggle0.setState (not toggle0.value))}}>
    {{if toggle0.value 'Hey there good lookin' 'Toggle me'}}
  </EuiButton>
  <EuiButtonIcon
    @iconType={{if toggle1.value 'play' 'pause'}}
    title={{if toggle1.value 'Play' 'Pause'}}
    aria-label={{if toggle1.value 'Play' 'Pause'}}
    {{on 'click' (fn toggle1.setState (not toggle1.value))}}
  />
  <EuiButton
    @isSelected={{toggle2.value}}
    @fill={{toggle2.value}}
    @iconType={{if toggle2.value 'starFilledSpace' 'starPlusEmpty'}}
    {{on 'click' (fn toggle2.setState (not toggle2.value))}}
  >
    Toggle me
  </EuiButton>
  <EuiButtonIcon
    @display={{if toggle3.value 'base' 'empty'}}
    @size='m'
    aria-label='Autosave'
    title='Autosave'
    @iconType='save'
    aria-pressed={{toggle3.value}}
    @color={{toggle3.value 'primary' 'text'}}
    {{on 'click' (fn toggle3.setState (not toggle3.value))}}
  />
{{/let}}
```

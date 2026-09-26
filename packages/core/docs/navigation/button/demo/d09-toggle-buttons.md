---
order: 9
---

# Toggle buttons

<EuiText>

Any button can toggle something on and off; keep the state yourself and
flip it on click. If the button's **text or label changes** with the state
("Play" / "Pause"), nothing else is needed. If only its **look** changes
(e.g. a filled star), pass `@isSelected` so it gets `aria-pressed` and
screen readers announce whether it is on.

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

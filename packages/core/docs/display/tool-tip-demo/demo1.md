---
order: 1
---

<EuiText>
  <p>
Wrap <strong>EuiToolTip</strong> around any item that you need a tooltip for and provide the content and optionally the title. The position prop will take a suggested position, but will change it if the tooltip gets too close to the edge of the screen.
  </p>
</EuiText>

```hbs template
<EuiPanel @hasShadow={{false}}>
  <EuiText>
    <p>
      This tooltip appears on the
      <EuiToolTip @position='top' @content='Here is some tooltip text'>
        <EuiButtonEmpty>
          Top
        </EuiButtonEmpty>
      </EuiToolTip>
      <p>
        This tooltip appears on the
        <EuiToolTip
          @position='left'
          @title='Tooltip titles are optional'
          @content='Here is some tooltip text. Lets add some more content to see how it wraps.'
        >
          <EuiButtonEmpty>
            Left
          </EuiButtonEmpty>
        </EuiToolTip>
        and includes the optional title.
      </p>
    </p>
    <p>
      This tooltip appears on the
      <EuiToolTip @position='right' @content='Here is some tooltip text'>
        <EuiButtonEmpty>
          Right
        </EuiButtonEmpty>
      </EuiToolTip>
    </p>
    <p>
      This tooltip has a long delay because it might be in a repeatable
      component
      <EuiToolTip @delay='long' @content='Here is some tooltip text'>
        <EuiButtonEmpty>
          Wink
        </EuiButtonEmpty>
      </EuiToolTip>
    </p>
    <p>
      This tooltip appears on the bottom of this icon:
      <EuiToolTip @position='bottom' @content='Here is some tooltip text'>
        <EuiIcon tabindex='0' @type='alert' @title='Icon with tooltip' />
      </EuiToolTip>
    </p>
  </EuiText>
</EuiPanel>
```

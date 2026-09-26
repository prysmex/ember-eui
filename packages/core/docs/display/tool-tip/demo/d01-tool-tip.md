---
order: 1
---

# Tooltip

<EuiText>

Positions (`top`, `right`, `bottom`, `left`), a `@title`, and longer
content.

</EuiText>

```hbs template
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
    This tooltip has a long delay because it might be in a repeatable component
    <EuiToolTip @delay='long' @content='Here is some tooltip text'>
      <EuiButtonEmpty>
        Wink
      </EuiButtonEmpty>
    </EuiToolTip>
  </p>
  <p>
    This tooltip appears on the bottom of this icon:
    <EuiToolTip @position='bottom' @content='Here is some tooltip text'>
      <EuiIcon tabindex='0' @type='warning' @title='Icon with tooltip' />
    </EuiToolTip>
  </p>
</EuiText>
```

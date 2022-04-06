---
order: 1
---
<EuiText>
  Generally, tooltips should provide short, <strong>non-essential</strong>, contextual information, usually naming or describing with more detail. If you need interactive content or anything other than text, we recommend using <strong>EuiPopover</strong> instead.
</EuiText>
<EuiSpacer />
<EuiCallOut @color="warning" @size="s" @iconType="accessibility" @title="Putting anything other than plain text in a tooltip is lost on screen readers." />
<EuiSpacer />
<EuiText>
  Wrap <strong>EuiToolTip</strong> around any item that you need a tooltip for and provide the <EuiCode>content</EuiCode> and optionally the <EuiCode>title</EuiCode>. The <EuiCode>position</EuiCode> prop will take a suggested position, but will change it if the tooltip gets too close to the edge of the screen.
</EuiText>
<EuiSpacer />
<EuiCallOut @color="warning"  @size="s" @iconType="accessibility" @title="Anchoring a tooltip to a non-interactive element makes it difficult for keyboard-only and screen reader users to read." />
<EuiSpacer />
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

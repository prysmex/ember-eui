---
order: 1
---

# Demo

```hbs template
<EuiText>
  <p>
    This tooltip appears on the
    <EuiToolTip @position="top" @content="Here is some tooltip text">
      <EuiButtonEmpty>
        Top
      </EuiButtonEmpty>
    </EuiToolTip>
    <p>
      This tooltip appears on the
      <EuiToolTip
        @position="left"
        @title="Tooltip titles are optional"
        @content="Here is some tooltip text. Lets add some more content to see how it wraps."
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
    <EuiToolTip @position="right" @content="Here is some tooltip text">
      <EuiButtonEmpty>
        Right
      </EuiButtonEmpty>
    </EuiToolTip>
  </p>
  <p>
    This tooltip has a long delay because it might be in a repeatable
        component
    <EuiToolTip @delay="long" @content="Here is some tooltip text">
      <EuiButtonEmpty>
        Wink
      </EuiButtonEmpty>
    </EuiToolTip>
  </p>
  <p>
    This tooltip appears on the bottom of this icon:
    <EuiToolTip @position="bottom" @content="Here is some tooltip text">
      <EuiIcon tabindex="0" @type="alert" @title="Icon with tooltip" />
    </EuiToolTip>
  </p>
</EuiText>
<EuiSpacer @size="xl" />
<p>
  <EuiToolTip @position="top" @content="Here is some tooltip text" @display="block">
    <EuiButton @fullWidth={{true}}>
      I am a block level tooltip, applied to a button with fullWidth
    </EuiButton>
  </EuiToolTip>
</p>
<EuiSpacer />
<EuiToolTip @position="right" @content="Works on anything">
  <EuiFieldText placeholder="Hover over me" aria-label="ToolTip appears on hover" />
</EuiToolTip>
<EuiSpacer />

<EuiText>
  If you want to attach and control the ToolTip to something programatically you can optionally pass an attachTo string or element
  and use the content named block, also you can pass isShown as true to show the tooltip without user interaction
</EuiText>

<EuiSpacer @size="xl"/>

<EuiButton @color="danger" id="attachTo1" {{on "mouseenter" this.updateAttachTo}}>
  You can hover me, attach to 1
</EuiButton>
<EuiButton @color="primary" id="attachTo2" {{on "mouseenter" this.updateAttachTo}}>
  You can hover me, attach to 2
</EuiButton>
<EuiButton @color="warning" id="attachTo3" {{on "mouseenter" this.updateAttachTo}}>
  You can hover me, attach to 3
</EuiButton>

<EuiSpacer @size="xl"/>
<EuiButton {{on "click" (set this.isShown (not this.isShown))}}>
  {{if this.isShown "isShown true" "isShown false"}}
</EuiButton>
<EuiToolTip @position="top" @attachTo={{this.attachTo}} @isShown={{this.isShown}}>
  <:content>
    <p>
      Works on any kind of element — buttons, inputs, you name it!
    </p>
  </:content>
</EuiToolTip>
```

```javascript component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class ToolTipDemo1 extends Component {
  @tracked attachTo = '#attachTo1';
  @tracked isShown = false;

  @action
  updateAttachTo(ele) {
    if (ele.target !== this.attachTo) {
      this.attachTo = ele.target;
    }
  }
}
```

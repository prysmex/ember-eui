---
order: 11
---

# Custom resize logic

<EuiText>
  <p>
    If you want to break out of <strong>EuiResizableContainer</strong> usage completely, you may use the standalone <strong>EuiResizableButton</strong> component. Pass <EuiCode>@isHorizontal</EuiCode> for an x-axis resizer (it is a y-axis one by default). You will need to attach your own mouse, touch, and keyboard events and logic to the button with <EuiCode>&#123;&#123;on&#125;&#125;</EuiCode> modifiers (upstream's <EuiCode>onMouseDown</EuiCode>, <EuiCode>onTouchStart</EuiCode> and <EuiCode>onKeyDown</EuiCode> props) - see the example below.
  </p>
</EuiText>

<EuiSpacer />

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import style from 'ember-style-modifier/modifiers/style';
import { EuiPanel, EuiResizableButton } from '@ember-eui/core/components';

const MIN_PANEL_WIDTH = 20;
const KEYBOARD_OFFSET = 10;

const getMouseOrTouchX = (event) =>
  event.targetTouches ? event.targetTouches[0].pageX : event.pageX;

export default class CustomResizeDemo extends Component {
  @tracked panelWidth = 200;

  initialPanelWidth = 200;
  initialMouseX = 0;

  get panelStyle() {
    return {
      display: 'flex',
      justifyContent: 'flex-end',
      blockSize: '200px',
      inlineSize: `${this.panelWidth}px`,
      maxInlineSize: '100%',
    };
  }

  onMouseMove = (event) => {
    const mouseOffset = getMouseOrTouchX(event) - this.initialMouseX;

    this.panelWidth = Math.max(
      this.initialPanelWidth + mouseOffset,
      MIN_PANEL_WIDTH
    );
  };

  onMouseUp = () => {
    this.initialMouseX = 0;

    window.removeEventListener('mousemove', this.onMouseMove);
    window.removeEventListener('mouseup', this.onMouseUp);
    window.removeEventListener('touchmove', this.onMouseMove);
    window.removeEventListener('touchend', this.onMouseUp);
  };

  @action
  onMouseDown(event) {
    this.initialMouseX = getMouseOrTouchX(event);
    this.initialPanelWidth = this.panelWidth;

    // Window event listeners are used in case the user's mouse leaves the
    // component
    window.addEventListener('mousemove', this.onMouseMove);
    window.addEventListener('mouseup', this.onMouseUp);
    window.addEventListener('touchmove', this.onMouseMove);
    window.addEventListener('touchend', this.onMouseUp);
  }

  @action
  onKeyDown(event) {
    switch (event.key) {
      case 'ArrowRight':
        event.preventDefault(); // Safari+VO will screen reader navigate off the button otherwise
        this.panelWidth += KEYBOARD_OFFSET;
        break;
      case 'ArrowLeft':
        event.preventDefault();
        this.panelWidth = Math.max(
          this.panelWidth - KEYBOARD_OFFSET,
          MIN_PANEL_WIDTH
        );
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.onMouseUp();
  }

  <template>
    <EuiPanel @paddingSize="s" {{style this.panelStyle}}>
      <EuiResizableButton
        @isHorizontal={{true}}
        {{on "mousedown" this.onMouseDown}}
        {{on "touchstart" this.onMouseDown}}
        {{on "keydown" this.onKeyDown}}
      />
    </EuiPanel>
  </template>
}
```

---
order: 3
---

# Progress can have absolute or fixed positions

<EuiText>

Using the `@position` argument we can align our bar to be `fixed` or `absolute`. In both options, the background color of the base bar is dropped (since the context of width is already known from your wrapping element). For the absolute option, make sure that your wrapping element has `position: relative` applied.

</EuiText>

<EuiSpacer />

<EuiCallOut @title="Progress bars over fixed headers" @color="warning" @iconType="warning">
  <p>Using the <code>fixed</code> position may result in <strong>EuiProgress</strong> being overlaid when its parent wrapper has a <code>z-index</code> value lower than another fixed element, such as <strong>EuiHeader</strong>. In this scenario, wrap <strong>EuiProgress</strong> in an <strong>EuiPortal</strong> (example below).</p>
</EuiCallOut>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { registerDestructor } from '@ember/destroyable';
import { EuiButton, EuiCallOut, EuiFlexGroup, EuiFlexItem, EuiHeader, EuiHeaderLogo, EuiHeaderSection, EuiHeaderSectionItem, EuiPanel, EuiPortal, EuiProgress, EuiSpacer, EuiText } from '@ember-eui/core/components';
import { on } from '@ember/modifier';

export default class ProgressPositionsDemo extends Component {
  @tracked value = 0;
  @tracked showProgress = false;
  @tracked showHeader = false;
  timer = null;

  constructor(owner, args) {
    super(owner, args);
    registerDestructor(this, () => clearTimeout(this.timer));
  }

  progress(value) {
    if (value > 100) {
      this.value = 100;
    } else {
      this.value = value;
      const diff = Math.round(Math.random() * 10);
      this.timer = setTimeout(() => this.progress(value + diff), 250);
    }
  }

  @action
  toggleProgress() {
    if (!this.showProgress) {
      this.timer = setTimeout(() => this.progress(0), 250);
    } else {
      clearTimeout(this.timer);
      this.value = 0;
    }
    this.showProgress = !this.showProgress;
    this.showHeader = false;
  }

  @action
  toggleHeader() {
    clearTimeout(this.timer);
    this.showProgress = false;
    this.showHeader = !this.showHeader;
  }

  <template>
    <div>
      <EuiPanel style="width: 300px; position: relative; overflow: hidden;">
        <EuiProgress @size="xs" @color="accent" @position="absolute" />
        <EuiText>
          <h2>Absolutely!</h2>
          <p>
            The progress bar is absolutely positioned in this panel. You could see
            how this might be useful in our Toast component.
          </p>
        </EuiText>
      </EuiPanel>

      <EuiSpacer @size="l" />

      <EuiFlexGroup @gutterSize="s" @alignItems="center">
        <EuiFlexItem @grow={{false}}>
          <EuiButton @size="s" {{on "click" this.toggleProgress}}>
            Toggle a fixed bar
          </EuiButton>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiButton @size="s" {{on "click" this.toggleHeader}}>
            Toggle a fixed bar with header
          </EuiButton>
        </EuiFlexItem>
      </EuiFlexGroup>

      <EuiSpacer @size="l" />

      {{#if this.showProgress}}
        <div>
          <EuiCallOut @title="Look up!" @color="warning" @iconType="sortUp">
            <p>The progress bar is fixed to the top of your browser.</p>
          </EuiCallOut>
          <EuiProgress @value={{this.value}} @max={{100}} @size="s" @position="fixed" />
        </div>
      {{/if}}

      {{#if this.showHeader}}
        <div>
          <EuiCallOut @title="Look up!" @color="warning" @iconType="sortUp">
            <p>
              The progress bar is fixed to the top of your browser and positioned
              above an <strong>EuiHeader</strong>.
            </p>
          </EuiCallOut>
          <EuiHeader style="position: fixed; top: 0; left: 0; width: 100%;">
            <EuiHeaderSection>
              <EuiHeaderSectionItem>
                <EuiHeaderLogo @href="#" aria-label="Go to home page" />
              </EuiHeaderSectionItem>
            </EuiHeaderSection>
          </EuiHeader>
          <div style="position: absolute; z-index: 5;">
            <EuiPortal>
              <EuiProgress @size="xs" @color="accent" @position="fixed" />
            </EuiPortal>
          </div>
        </div>
      {{/if}}
    </div>
  </template>
}
```


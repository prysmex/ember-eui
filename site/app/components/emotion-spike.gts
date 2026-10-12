import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { on } from '@ember/modifier';
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';
import { EuiThemeContext, useEuiStyles } from '@ember-eui/core/utils/emotion/context';
import type { EuiColorMode, EuiThemeOverrides } from '@ember-eui/core/utils/emotion/theme';

export default class EmotionSpike extends Component {
  @tracked mode: EuiColorMode = 'light';
  @tracked clicks = 0;
  context = new EuiThemeContext(() => ({ colorMode: this.mode }));
  brand: EuiThemeOverrides = { colors: { primary: '#663399', onPrimary: '#ffffff' }, borderRadius: 16 };

  @action toggleTheme() { this.mode = this.mode === 'light' ? 'dark' : 'light'; }
  @action countClick() { this.clicks++; }

  get frameStyles() {
    return useEuiStyles(this.context, (theme) => ({
      backgroundColor: theme.colors.background,
      color: theme.colors.text,
      padding: 32,
      borderRadius: 12,
      fontFamily: theme.fontFamily,
      '& h1': { fontSize: 28, margin: '0 0 12px' },
      '& h2': { fontSize: 20, margin: '24px 0 12px' },
    }));
  }
  get rowStyles() {
    return useEuiStyles(this.context, () => ({ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center', marginTop: 16 }));
  }
  get darkStyles() {
    return useEuiStyles(this.context, () => ({ backgroundColor: '#1d1e24', padding: 20, borderRadius: 8 }));
  }

  <template>
    <main class={{this.frameStyles}}>
      <h1>A fresh coat of paint</h1>
      <p>Try the buttons, switch themes, and explore a different look for one section.</p>
      <EuiEmotionProvider @parent={{this.context}} as |eui|>
        <div class={{this.rowStyles}}>
          <eui.Button {{on "click" this.toggleTheme}}>Switch theme</eui.Button>
          <eui.Button @fill={{true}} {{on "click" this.countClick}}>Click me</eui.Button>
          <span aria-live="polite">Clicks: {{this.clicks}}</span>
        </div>
        <h2>Everyday actions</h2>
        <div class={{this.rowStyles}}>
          <eui.Button>Outline</eui.Button>
          <eui.Button @fill={{true}}>Primary</eui.Button>
          <eui.Button @color="success" @fill={{true}}>Success</eui.Button>
          <eui.Button @color="warning" @fill={{true}}>Warning</eui.Button>
          <eui.Button @color="danger" @fill={{true}}>Danger</eui.Button>
          <eui.Button @size="s">Small</eui.Button>
          <eui.Button @isSelected={{true}}>Selected</eui.Button>
          <eui.Button @isDisabled={{true}}>Disabled</eui.Button>
          <eui.Button @isLoading={{true}}>Loading</eui.Button>
          <eui.Button @href="#custom-look">Jump to custom look</eui.Button>
        </div>
        <h2>Always dark</h2>
        <section class={{this.darkStyles}} aria-label="Dark buttons">
          <EuiEmotionProvider @parent={{eui.context}} @colorMode="dark" as |dark|>
            <div class={{this.rowStyles}}>
              <dark.Button @fill={{true}}>Primary</dark.Button>
              <dark.Button @color="danger">Danger</dark.Button>
              <dark.Button @isLoading={{true}}>Loading</dark.Button>
            </div>
          </EuiEmotionProvider>
        </section>
        <h2 id="custom-look">A custom look</h2>
        <EuiEmotionProvider @parent={{eui.context}} @overrides={{this.brand}} as |brand|>
          <div class={{this.rowStyles}}>
            <brand.Button @fill={{true}}>Purple & rounded</brand.Button>
            <brand.Button>Outline</brand.Button>
          </div>
        </EuiEmotionProvider>
      </EuiEmotionProvider>
    </main>
  </template>
}

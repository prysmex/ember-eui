import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import EuiButton from '@ember-eui/core/components/eui-button';
import EuiPanel from '@ember-eui/core/components/eui-panel';
import EuiSpacer from '@ember-eui/core/components/eui-spacer';
import EuiHorizontalRule from '@ember-eui/core/components/eui-horizontal-rule';
import EuiLoadingSpinner from '@ember-eui/core/components/eui-loading-spinner';
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';
import { EuiThemeContext } from '@ember-eui/core/utils/emotion/context';
import { euiClass } from '@ember-eui/core/utils/eui/styles';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';
import type { EuiColorMode } from '@ember-eui/core/utils/emotion/theme';
import type {
  EuiBorealisHighContrastMode,
  EuiBorealisOverrides,
} from '@ember-eui/core/utils/eui/theme';

const example = `<EuiEmotionProvider @colorMode="light">
  <EuiPanel><EuiButton @fill={{true}}>Light</EuiButton></EuiPanel>
  <EuiEmotionProvider @colorMode="dark">
    <EuiPanel><EuiButton @fill={{true}}>Dark</EuiButton></EuiPanel>
  </EuiEmotionProvider>
</EuiEmotionProvider>`;

/** Live migration evidence: public Ember components backed by upstream styles. */
export default class LatestEuiSpike extends Component {
  @service('eui-emotion') declare defaults: EuiEmotionService;
  @tracked mode: EuiColorMode = 'light';
  @tracked contrast: EuiBorealisHighContrastMode = false;
  @tracked rounded = false;
  @tracked saves = 0;
  @tracked loading = false;
  readonly colors = [
    'primary',
    'accent',
    'accentSecondary',
    'success',
    'warning',
    'danger',
    'text',
  ];
  readonly example = example;
  readonly context = new EuiThemeContext(
    () => ({ colorMode: this.mode, highContrastMode: this.contrast }),
    () => this.defaults.context,
  );
  get savedMessage() {
    return `${this.saves} ${this.saves === 1 ? 'change' : 'changes'} saved`;
  }
  get overrides(): EuiBorealisOverrides {
    return {
      border: {
        radius: {
          control: this.rounded ? '24px' : '8px',
          panel: this.rounded ? '24px' : '12px',
        },
      },
    };
  }
  get isLight() {
    return this.mode === 'light';
  }
  get isDark() {
    return this.mode === 'dark';
  }
  get standardContrast() {
    return this.contrast === false;
  }
  get preferredContrast() {
    return this.contrast === 'preferred';
  }
  get forcedContrast() {
    return this.contrast === 'forced';
  }
  @action setMode(mode: EuiColorMode) {
    this.mode = mode;
  }
  @action setContrast(mode: EuiBorealisHighContrastMode) {
    this.contrast = mode;
  }
  @action toggleRounded() {
    this.rounded = !this.rounded;
  }
  @action save() {
    this.saves++;
  }
  @action toggleLoading() {
    this.loading = !this.loading;
  }
  get frame() {
    const theme = this.context.upstream.euiTheme;
    return euiClass(this.context, {
      boxSizing: 'border-box',
      padding: 'clamp(16px, 4vw, 40px)',
      borderRadius: 16,
      backgroundColor: theme.colors.body,
      color: theme.colors.textParagraph,
      fontFamily: theme.font.family,
      '& h1': {
        color: 'inherit',
        fontFamily: 'inherit',
        fontSize: 'clamp(30px, 4vw, 48px)',
        fontWeight: 700,
        lineHeight: 1.15,
        margin: '12px 0',
      },
      '& h2': {
        color: 'inherit',
        fontFamily: 'inherit',
        fontSize: 24,
        fontWeight: 600,
        lineHeight: 1.3,
        margin: '0 0 12px',
      },
      '& h3': {
        color: 'inherit',
        fontFamily: 'inherit',
        fontSize: 18,
        fontWeight: 600,
        lineHeight: 1.3,
        margin: '0 0 8px',
      },
      '& p': { color: 'inherit', margin: '0 0 12px', lineHeight: 1.6 },
      '& .latest-eyebrow': {
        fontSize: 12,
        textTransform: 'uppercase',
        letterSpacing: '0.12em',
        fontWeight: 600,
      },
      '& .latest-controls': {
        display: 'flex',
        flexWrap: 'wrap',
        gap: 8,
        alignItems: 'center',
      },
      '& .latest-grid': {
        display: 'grid',
        gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
        gap: 16,
      },
      '& .latest-stack': { minWidth: 0 },
      '& .latest-note': { fontSize: 13, opacity: 0.8 },
      '& .latest-code': {
        whiteSpace: 'pre-wrap',
        overflowWrap: 'anywhere',
        fontFamily: theme.font.familyCode,
        fontSize: 13,
        lineHeight: 1.6,
      },
      '& .latest-surface': { minWidth: 0 },
      '@media (max-width: 700px)': {
        '& .latest-grid': { gridTemplateColumns: '1fr' },
      },
    });
  }
  <template>
    <EuiEmotionProvider
      @colorMode={{this.mode}}
      @highContrastMode={{this.contrast}}
    >
      <section
        class={{this.frame}}
        data-eui-latest-showcase
        data-mode={{this.mode}}
      >
        <header>
          <EuiButton @size="s" @href="/docs/introduction" data-latest-back>Back
            to documentation</EuiButton>
          <EuiSpacer @size="m" />
          <p class="latest-eyebrow">The latest EUI, in Ember</p>
          <h1>Borealis, component by component.</h1>
          <p>Real upstream themes and style factories. Native Ember components,
            with scoped light and dark contexts.</p>
          <p class="latest-note" data-latest-versions>EUI 123.1.0 · Borealis
            8.1.0 · theme-common 10.1.0</p>
          <div class="latest-controls" aria-label="Theme controls">
            <EuiButton
              @isSelected={{this.isLight}}
              data-latest-light
              {{on "click" (fn this.setMode "light")}}
            >Light</EuiButton>
            <EuiButton
              @isSelected={{this.isDark}}
              data-latest-dark
              {{on "click" (fn this.setMode "dark")}}
            >Dark</EuiButton>
          </div>
          <EuiSpacer @size="m" />
          <div class="latest-controls" aria-label="Contrast controls">
            <EuiButton
              @size="s"
              @isSelected={{this.standardContrast}}
              data-contrast-standard
              {{on "click" (fn this.setContrast false)}}
            >Standard contrast</EuiButton>
            <EuiButton
              @size="s"
              @isSelected={{this.preferredContrast}}
              data-contrast-preferred
              {{on "click" (fn this.setContrast "preferred")}}
            >Preferred contrast</EuiButton>
            <EuiButton
              @size="s"
              @isSelected={{this.forcedContrast}}
              data-contrast-forced
              {{on "click" (fn this.setContrast "forced")}}
            >Forced contrast tokens</EuiButton>
          </div>
          <EuiSpacer @size="s" />
          <p class="latest-note">Contrast controls change upstream tokens.
            Forced colors also depend on your browser and operating system.</p>
        </header>
        <EuiHorizontalRule @margin="l" />
        <h2>One screen. Two themes.</h2>
        <p>These islands keep their own mode while sharing the parent contrast
          setting.</p>
        <div class="latest-grid">
          <EuiEmotionProvider @colorMode="light">
            <EuiPanel
              @paddingSize="l"
              class="latest-surface"
              data-latest-light-island
            >
              <h3>Light workspace</h3>
              <p>A real Borealis panel and primary button.</p>
              <EuiButton
                @fill={{true}}
                data-latest-light-action
                {{on "click" this.save}}
              >Save in light</EuiButton>
              <EuiSpacer @size="m" />
              <EuiLoadingSpinner @size="m" data-latest-light-spinner />
            </EuiPanel>
          </EuiEmotionProvider>
          <EuiEmotionProvider @colorMode="dark">
            <EuiPanel
              @paddingSize="l"
              class="latest-surface"
              data-latest-dark-island
            >
              <h3>Dark workspace</h3>
              <p>The same components, resolved against dark tokens.</p>
              <EuiButton
                @fill={{true}}
                data-latest-dark-action
                {{on "click" this.save}}
              >Save in dark</EuiButton>
              <EuiSpacer @size="m" />
              <EuiLoadingSpinner @size="m" data-latest-dark-spinner />
            </EuiPanel>
          </EuiEmotionProvider>
        </div>
        <EuiSpacer @size="l" />
        <h2>Buttons with native behavior</h2>
        <EuiPanel @paddingSize="l" data-latest-variants>
          <div class="latest-controls">
            {{#each this.colors as |color|}}
              <EuiButton
                @color={{color}}
                @fill={{true}}
                data-latest-variant={{color}}
              >{{color}}</EuiButton>
            {{/each}}
          </div>
          <EuiSpacer @size="m" />
          <div class="latest-controls">
            <EuiButton
              @size="s"
              @iconType="plus"
              data-latest-save
              {{on "click" this.save}}
            >Save change</EuiButton>
            <EuiButton @href="#migration-scope" data-latest-anchor>Migration
              scope</EuiButton>
            <EuiButton
              @isDisabled={{true}}
              data-latest-disabled
            >Disabled</EuiButton>
            <EuiButton
              @isLoading={{this.loading}}
              data-latest-loading
            >Background action</EuiButton>
            <EuiButton
              @size="s"
              data-latest-toggle-loading
              {{on "click" this.toggleLoading}}
            >Toggle loading</EuiButton>
          </div>
          <EuiSpacer @size="s" />
          <p aria-live="polite" data-latest-save-count>{{this.savedMessage}}</p>
        </EuiPanel>
        <EuiSpacer @size="l" />
        <h2>Override tokens inside a context</h2>
        <p>Change the native control and panel radius. The surrounding
          components keep their defaults.</p>
        <EuiButton
          @size="s"
          @isSelected={{this.rounded}}
          data-latest-rounded
          {{on "click" this.toggleRounded}}
        >Round the preview</EuiButton>
        <EuiSpacer @size="m" />
        <EuiEmotionProvider @borealisOverrides={{this.overrides}}>
          <EuiPanel @paddingSize="l" data-latest-override-panel>
            <h3>Scoped shape tokens</h3>
            <EuiButton
              @fill={{true}}
              data-latest-override-button
              {{on "click" this.save}}
            >Nested action</EuiButton>
          </EuiPanel>
        </EuiEmotionProvider>
        <EuiHorizontalRule @margin="l" />
        <section id="migration-scope">
          <h2>Migration scope</h2>
          <p>Migrated components follow the latest upstream styling. This batch
            migrates Button, Panel, Spacer, HorizontalRule and LoadingSpinner.
            This standalone showcase disables legacy styles. The remaining docs
            and component catalog still use bundled Amsterdam CSS while their
            migration is pending.</p>
          <p>The
            <a href="/docs/emotion">original Emotion showcase</a>
            uses the earlier hand-authored theme. This page uses upstream
            Borealis tokens and upstream component factories.</p>
          <details><summary>Provider example</summary><pre
              class="latest-code"
            >{{this.example}}</pre></details>
          <EuiSpacer @size="m" />
          <p class="latest-note">Spike status: incremental migration, with
            rendering and upstream factory parity tests. Whole-catalog parity,
            SSR/hydration, visual coverage and performance comparisons remain
            release gates.</p>
        </section>
      </section>
    </EuiEmotionProvider>
  </template>
}

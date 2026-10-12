import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn } from '@ember/helper';
import EuiEmotionButton from '@ember-eui/core/components/eui-emotion-button';
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';
import {
  EuiThemeContext,
  useEuiStyles,
} from '@ember-eui/core/utils/emotion/context';
import type EuiEmotionService from '@ember-eui/core/services/eui-emotion';
import type {
  EuiColorMode,
  EuiThemeOverrides,
} from '@ember-eui/core/utils/emotion/theme';

/** Both the panel and its buttons read the same scoped context. */
function panelStyles(context: EuiThemeContext) {
  return useEuiStyles(context, (theme) => ({
    backgroundColor: theme.colors.background,
    color: theme.colors.text,
    '& p': { color: theme.colors.text, opacity: 0.75 },
  }));
}

type Brand = 'purple' | 'ocean' | 'forest';
const brandColors = { purple: '#663399', ocean: '#005a9e', forest: '#006b45' };
const providerExample = `<EuiEmotionProvider @colorMode="light">
  <EuiEmotionButton @fill={{true}}>Light action</EuiEmotionButton>

  <EuiEmotionProvider
    @colorMode="dark"
  >
    <EuiEmotionButton @fill={{true}}>Dark action</EuiEmotionButton>
  </EuiEmotionProvider>
</EuiEmotionProvider>`;
const stylingExample = `import { useEuiStyles } from '@ember-eui/core/utils/emotion/context';
import { getEuiThemeContext } from '@ember-eui/core/utils/emotion/consume';

get styles() {
  return useEuiStyles(getEuiThemeContext(this), (theme) => ({
    color: theme.colors.text,
    backgroundColor: theme.colors.background,
    padding: theme.spacing * 2,
  }));
}`;

export default class EmotionSpike extends Component {
  @service('eui-emotion') declare defaults: EuiEmotionService;
  @tracked mode: EuiColorMode = 'light';
  @tracked clicks = 0;
  @tracked brand: Brand = 'purple';
  @tracked rounded = true;
  readonly context = new EuiThemeContext(
    () => ({
      colorMode: this.mode,
      overrides: { fontFamily: 'Arial, Helvetica, sans-serif' },
    }),
    () => this.defaults.context,
  );
  readonly providerExample = providerExample;
  readonly stylingExample = stylingExample;

  get savedMessage() {
    return `${this.clicks} ${this.clicks === 1 ? 'change' : 'changes'} saved`;
  }

  get isLight() {
    return this.mode === 'light';
  }
  get isDark() {
    return this.mode === 'dark';
  }
  get isPurple() {
    return this.brand === 'purple';
  }
  get isOcean() {
    return this.brand === 'ocean';
  }
  get isForest() {
    return this.brand === 'forest';
  }
  get brandOverrides(): EuiThemeOverrides {
    return {
      colors: { primary: brandColors[this.brand], onPrimary: '#ffffff' },
      borderRadius: this.rounded ? 20 : 4,
    };
  }

  @action setMode(mode: EuiColorMode) {
    this.mode = mode;
  }
  @action setBrand(brand: Brand) {
    this.brand = brand;
  }
  @action toggleRounded() {
    this.rounded = !this.rounded;
  }
  @action countClick() {
    this.clicks++;
  }
  @action resetClicks() {
    this.clicks = 0;
  }

  get frameStyles() {
    return useEuiStyles(this.context, (theme) => {
      const dark = this.isDark;
      const surface = dark ? '#262934' : '#f6f8fc';
      const border = dark ? '#3b4150' : '#e1e6ef';
      const muted = dark ? '#b3bdcf' : '#586779';
      return {
        label: 'emotion-showcase',
        boxSizing: 'border-box',
        minWidth: 0,
        backgroundColor: theme.colors.background,
        color: theme.colors.text,
        padding: '40px clamp(20px, 4vw, 56px) 56px',
        fontFamily: 'Arial, Helvetica, sans-serif',
        lineHeight: 1.6,
        '& *, & *::before, & *::after': { boxSizing: 'border-box' },
        '& h1, & h2, & h3, & p': { margin: 0 },
        '& h1': {
          fontSize: 'clamp(32px, 4vw, 56px)',
          lineHeight: 1.08,
          letterSpacing: '-0.045em',
          fontWeight: 750,
          maxWidth: 600,
        },
        '& h2': {
          fontSize: 26,
          lineHeight: 1.3,
          letterSpacing: '-0.025em',
          fontWeight: 700,
        },
        '& h3': { fontSize: 17, lineHeight: 1.4, fontWeight: 650 },
        '& :where(p)': { color: muted },
        '& .showcase-topline': {
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 20,
          flexWrap: 'wrap',
          marginBottom: 42,
        },
        '& .showcase-eyebrow': {
          fontSize: 11,
          fontWeight: 700,
          letterSpacing: '0.13em',
          textTransform: 'uppercase',
          display: 'flex',
          alignItems: 'center',
          gap: 8,
        },
        '& .showcase-dot': {
          width: 7,
          height: 7,
          borderRadius: '50%',
          backgroundColor: theme.colors.success,
          display: 'inline-block',
        },
        '& .showcase-switcher': {
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          padding: 6,
          backgroundColor: surface,
          border: `1px solid ${border}`,
          borderRadius: 12,
        },
        '& .showcase-mode-label': {
          padding: '0 6px',
          fontSize: 12,
          color: muted,
        },
        '& .showcase-hero': {
          display: 'grid',
          gridTemplateColumns: '1.1fr 1fr',
          alignItems: 'center',
          gap: 40,
          marginBottom: 40,
        },
        '& .showcase-lead': { marginTop: 22, fontSize: 17, maxWidth: 500 },
        '& .showcase-row': {
          display: 'flex',
          gap: 10,
          alignItems: 'center',
          flexWrap: 'wrap',
          marginTop: 20,
        },
        '& .showcase-caption': { fontSize: 12, color: muted },
        '& .showcase-preview': {
          border: `1px solid ${border}`,
          borderRadius: 18,
          padding: 24,
          background: dark
            ? 'linear-gradient(140deg, #282c39, #20232d)'
            : 'linear-gradient(140deg, #f0f5ff, #f8f5ff)',
        },
        '& .showcase-preview-top': {
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 22,
        },
        '& .showcase-pill': {
          display: 'inline-flex',
          fontSize: 11,
          fontWeight: 650,
          backgroundColor: theme.colors.background,
          border: `1px solid ${border}`,
          borderRadius: 20,
          padding: '3px 10px',
        },
        '& .showcase-workspace': {
          padding: 22,
          backgroundColor: theme.colors.background,
          border: `1px solid ${border}`,
          borderRadius: 12,
          boxShadow: dark ? 'none' : '0 8px 24px rgba(22, 38, 63, 0.06)',
        },
        '& .showcase-avatar': {
          display: 'grid',
          placeItems: 'center',
          width: 38,
          height: 38,
          borderRadius: 10,
          backgroundColor: surface,
          color: theme.colors.primary,
          fontWeight: 700,
        },
        '& .showcase-workspace-header': {
          display: 'flex',
          alignItems: 'center',
          gap: 12,
          marginBottom: 22,
        },
        '& .showcase-progress': {
          height: 6,
          borderRadius: 10,
          backgroundColor: surface,
          margin: '16px 0 22px',
          overflow: 'hidden',
        },
        '& .showcase-progress span': {
          display: 'block',
          height: '100%',
          width: '72%',
          borderRadius: 'inherit',
          backgroundColor: theme.colors.primary,
        },
        '& .showcase-facts': {
          display: 'grid',
          gridTemplateColumns: 'repeat(3, 1fr)',
          gap: 20,
          borderTop: `1px solid ${border}`,
          borderBottom: `1px solid ${border}`,
          padding: '20px 0',
          marginBottom: 46,
        },
        '& .showcase-fact strong': { display: 'block', fontSize: 14 },
        '& .showcase-fact span': {
          display: 'block',
          fontSize: 12,
          color: muted,
        },
        '& .showcase-section': { marginTop: 44, scrollMarginTop: 80 },
        '& .showcase-section > p': { marginTop: 8, maxWidth: 690 },
        '& .showcase-gallery': {
          display: 'grid',
          gridTemplateColumns: 'repeat(4, minmax(0, 1fr))',
          gap: 12,
          marginTop: 22,
        },
        '& .showcase-variant': {
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'flex-start',
          justifyContent: 'space-between',
          gap: 18,
          padding: 18,
          minHeight: 116,
          border: `1px solid ${border}`,
          borderRadius: 10,
          backgroundColor: surface,
        },
        '& .showcase-variant > span': { fontSize: 11, color: muted },
        '& .showcase-islands': {
          display: 'grid',
          gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
          gap: 16,
          marginTop: 22,
        },
        '& .showcase-island': {
          padding: 24,
          borderRadius: 14,
          border: `1px solid ${border}`,
        },
        '& .showcase-island h3': { marginTop: 12, fontSize: 22 },
        '& .showcase-island p': { fontSize: 13, marginTop: 8 },
        '& .showcase-brand': {
          display: 'grid',
          gridTemplateColumns: '1fr 1fr',
          gap: 30,
          padding: 28,
          marginTop: 22,
          backgroundColor: surface,
          border: `1px solid ${border}`,
          borderRadius: 14,
        },
        '& .showcase-brand-preview': {
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          alignItems: 'flex-start',
          gap: 16,
          padding: 24,
          borderRadius: 10,
          backgroundColor: theme.colors.background,
          border: `1px solid ${border}`,
        },
        '& .showcase-swatch': {
          display: 'inline-block',
          width: 9,
          height: 9,
          borderRadius: '50%',
        },
        '& .showcase-swatch--purple': { backgroundColor: brandColors.purple },
        '& .showcase-swatch--ocean': { backgroundColor: brandColors.ocean },
        '& .showcase-swatch--forest': { backgroundColor: brandColors.forest },
        '& .showcase-architecture': {
          display: 'grid',
          gridTemplateColumns: 'repeat(3, minmax(0, 1fr))',
          gap: 24,
          marginTop: 22,
        },
        '& .showcase-architecture p': { fontSize: 13, marginTop: 8 },
        '& .showcase-number': {
          fontSize: 11,
          color: theme.colors.primary,
          fontWeight: 700,
          display: 'block',
          marginBottom: 10,
        },
        '& details': {
          border: `1px solid ${border}`,
          borderRadius: 10,
          marginTop: 20,
          overflow: 'hidden',
        },
        '& summary': {
          cursor: 'pointer',
          padding: '14px 18px',
          fontSize: 14,
          fontWeight: 600,
          backgroundColor: surface,
        },
        '& summary:focus-visible': {
          outline: `2px solid ${theme.colors.focus}`,
          outlineOffset: -3,
        },
        '& pre': {
          padding: 20,
          margin: 0,
          fontSize: 12,
          lineHeight: 1.7,
          overflowX: 'auto',
          maxWidth: '100%',
          backgroundColor: theme.colors.background,
          color: theme.colors.text,
        },
        '& code': {
          fontFamily: 'ui-monospace, SFMono-Regular, Consolas, monospace',
          background: 'none',
          color: 'inherit',
        },
        '& .showcase-footer': {
          marginTop: 38,
          paddingTop: 20,
          borderTop: `1px solid ${border}`,
          fontSize: 12,
          color: muted,
        },
        '@media (max-width: 1000px)': {
          '& .showcase-hero': { gridTemplateColumns: '1fr', gap: 28 },
          '& .showcase-gallery': {
            gridTemplateColumns: 'repeat(2, minmax(0, 1fr))',
          },
        },
        '@media (max-width: 600px)': {
          padding: '24px 16px 36px',
          '& .showcase-topline': { marginBottom: 28 },
          '& .showcase-facts, & .showcase-islands, & .showcase-brand, & .showcase-architecture':
            { gridTemplateColumns: '1fr' },
          '& .showcase-brand': { padding: 18, gap: 22 },
          '& .showcase-variant': { padding: 12 },
          '& .showcase-mode-label': { display: 'none' },
        },
      };
    });
  }

  <template>
    <main
      class={{this.frameStyles}}
      data-emotion-showcase
      data-mode={{this.mode}}
    >
      <EuiEmotionProvider @parent={{this.context}}>
        <div class="showcase-topline">
          <span class="showcase-eyebrow"><span class="showcase-dot"></span>Ember
            EUI / styling experiment</span>
          <div
            class="showcase-switcher"
            role="group"
            aria-label="Preview theme"
          >
            <span class="showcase-mode-label">Preview theme</span>
            <EuiEmotionButton
              @size="s"
              @isSelected={{this.isLight}}
              @fill={{this.isLight}}
              {{on "click" (fn this.setMode "light")}}
              data-theme-light
            >Light</EuiEmotionButton>
            <EuiEmotionButton
              @size="s"
              @isSelected={{this.isDark}}
              @fill={{this.isDark}}
              {{on "click" (fn this.setMode "dark")}}
              data-theme-dark
            >Dark</EuiEmotionButton>
          </div>
        </div>

        <section class="showcase-hero" aria-labelledby="showcase-title">
          <div>
            <h1 id="showcase-title">Ember, meet Emotion.</h1>
            <p class="showcase-lead">One component. Different themes. Explore a
              new way to style Ember EUI, with live colors and a look that
              belongs to each part of your page.</p>
            <div class="showcase-row">
              <EuiEmotionButton @href="#scoped-themes" @fill={{true}}>Explore
                scoped themes ↓</EuiEmotionButton>
              <EuiEmotionButton @href="#how-it-works">How it works</EuiEmotionButton>
            </div>
          </div>
          <div class="showcase-preview">
            <div class="showcase-preview-top"><span
                class="showcase-eyebrow"
              >Live preview</span><span class="showcase-pill">{{if
                  this.isLight
                  "Light"
                  "Dark"
                }}
                theme</span></div>
            <div class="showcase-workspace">
              <div class="showcase-workspace-header"><span
                  class="showcase-avatar"
                >W</span><div><h3>Your workspace</h3><p
                    class="showcase-caption"
                  >Ready for the next good idea.</p></div></div>
              <p class="showcase-caption">Project progress</p>
              <div
                class="showcase-progress"
                role="img"
                aria-label="Project progress: 72 percent"
              ><span></span></div>
              <div class="showcase-row">
                <EuiEmotionButton
                  @fill={{true}}
                  {{on "click" this.countClick}}
                  data-save-changes
                >Save changes</EuiEmotionButton>
                <EuiEmotionButton
                  @size="s"
                  {{on "click" this.resetClicks}}
                >Reset</EuiEmotionButton>
              </div>
              <p
                class="showcase-caption"
                aria-live="polite"
                data-save-count
              >{{this.savedMessage}}</p>
            </div>
          </div>
        </section>

        <div class="showcase-facts">
          <div class="showcase-fact"><strong>Live light & dark</strong><span
            >Switch themes without remounting.</span></div>
          <div class="showcase-fact"><strong>One button, many states</strong><span
            >The first component in the spike.</span></div>
          <div class="showcase-fact"><strong>Themes with boundaries</strong><span
            >Override one section, keep the rest.</span></div>
        </div>

        <section class="showcase-section" aria-labelledby="button-states">
          <h2 id="button-states">A button for every state</h2>
          <p>These buttons share the page theme. Try the switcher above and
            watch every variant update together.</p>
          <div class="showcase-gallery">
            <div class="showcase-variant"><EuiEmotionButton
              >Outline</EuiEmotionButton><span>Default / primary</span></div>
            <div class="showcase-variant"><EuiEmotionButton
                @fill={{true}}
              >Primary</EuiEmotionButton><span>Filled action</span></div>
            <div class="showcase-variant"><EuiEmotionButton
                @color="success"
                @fill={{true}}
              >Success</EuiEmotionButton><span>Success</span></div>
            <div class="showcase-variant"><EuiEmotionButton
                @color="danger"
                @fill={{true}}
              >Delete</EuiEmotionButton><span>Critical action</span></div>
            <div class="showcase-variant"><EuiEmotionButton
                @size="s"
              >Small</EuiEmotionButton><span>Compact size</span></div>
            <div class="showcase-variant"><EuiEmotionButton
                @isSelected={{true}}
              >Selected</EuiEmotionButton><span>Selected state</span></div>
            <div class="showcase-variant"><EuiEmotionButton
                @isDisabled={{true}}
              >Disabled</EuiEmotionButton><span>Disabled state</span></div>
            <div class="showcase-variant"><EuiEmotionButton
                @isLoading={{true}}
              >Loading</EuiEmotionButton><span>Loading state</span></div>
          </div>
        </section>

        <section
          class="showcase-section"
          id="scoped-themes"
          aria-labelledby="scoped-themes-title"
        >
          <h2 id="scoped-themes-title">One page. Two themes.</h2>
          <p>Yes, light and dark can live in the same UI. Each section below has
            its own provider, so its theme stays fixed when you switch the page
            theme.</p>
          <div class="showcase-islands">
            <EuiEmotionProvider @colorMode="light" as |light|>
              <section
                class="showcase-island {{panelStyles light.context}}"
                data-light-island
              >
                <span class="showcase-eyebrow">Context / light</span>
                <h3>A light workspace</h3>
                <p>Bright surfaces, dark text, and a deep blue primary action.</p>
                <div class="showcase-row">
                  <EuiEmotionButton @fill={{true}} data-island-primary>Light
                    action</EuiEmotionButton>
                  <EuiEmotionButton>Outline</EuiEmotionButton>
                </div>
              </section>
            </EuiEmotionProvider>
            <EuiEmotionProvider @colorMode="dark" as |dark|>
              <section
                class="showcase-island {{panelStyles dark.context}}"
                data-dark-island
              >
                <span class="showcase-eyebrow">Context / dark</span>
                <h3>A dark workspace</h3>
                <p>Quiet surfaces, bright text, and a lighter blue primary
                  action.</p>
                <div class="showcase-row">
                  <EuiEmotionButton @fill={{true}} data-island-primary>Dark
                    action</EuiEmotionButton>
                  <EuiEmotionButton>Outline</EuiEmotionButton>
                </div>
              </section>
            </EuiEmotionProvider>
          </div>
        </section>

        <section
          class="showcase-section"
          id="custom-look"
          aria-labelledby="custom-look-title"
        >
          <h2 id="custom-look-title">Make one section your own</h2>
          <p>A nested provider can change color and shape while inheriting the
            page's light or dark mode. The buttons above keep their original
            theme.</p>
          <div class="showcase-brand">
            <div>
              <h3>Choose an accent</h3>
              <div class="showcase-row" role="group" aria-label="Brand accent">
                <EuiEmotionButton
                  @size="s"
                  @isSelected={{this.isPurple}}
                  {{on "click" (fn this.setBrand "purple")}}
                  data-brand-purple
                ><span
                    class="showcase-swatch showcase-swatch--purple"
                  ></span>Purple</EuiEmotionButton>
                <EuiEmotionButton
                  @size="s"
                  @isSelected={{this.isOcean}}
                  {{on "click" (fn this.setBrand "ocean")}}
                  data-brand-ocean
                ><span
                    class="showcase-swatch showcase-swatch--ocean"
                  ></span>Ocean</EuiEmotionButton>
                <EuiEmotionButton
                  @size="s"
                  @isSelected={{this.isForest}}
                  {{on "click" (fn this.setBrand "forest")}}
                  data-brand-forest
                ><span
                    class="showcase-swatch showcase-swatch--forest"
                  ></span>Forest</EuiEmotionButton>
              </div>
              <div class="showcase-row"><EuiEmotionButton
                  @size="s"
                  @isSelected={{this.rounded}}
                  {{on "click" this.toggleRounded}}
                  data-rounded
                >Rounded corners</EuiEmotionButton></div>
            </div>
            <div class="showcase-brand-preview" data-brand-preview>
              <span class="showcase-eyebrow">Your custom context</span>
              <EuiEmotionProvider @overrides={{this.brandOverrides}}>
                <EuiEmotionButton @fill={{true}} data-brand-primary>Branded
                  action</EuiEmotionButton>
                <EuiEmotionButton>Outline</EuiEmotionButton>
              </EuiEmotionProvider>
            </div>
          </div>
        </section>

        <section
          class="showcase-section"
          id="how-it-works"
          aria-labelledby="how-it-works-title"
        >
          <h2 id="how-it-works-title">Built for Ember</h2>
          <p>The spike uses Emotion's framework-independent API with Ember's own
            reactive state and contextual components.</p>
          <div class="showcase-architecture">
            <article><span class="showcase-number">01 / PROVIDE</span><h3>A
                context for each section</h3><p>Components consume their nearest
                provider automatically. Nested providers inherit mode, tokens
                and cache; no yielded Button or parent argument is required.</p></article>
            <article><span class="showcase-number">02 / REACT</span><h3>Tracked
                theme settings</h3><p>Color mode and token overrides flow
                through tracked getters. Mounted components restyle as their
                settings change.</p></article>
            <article><span class="showcase-number">03 / STYLE</span><h3>Styles
                beside the component</h3><p>useEuiTheme reads the tokens.
                useEuiStyles generates a class through a shared Emotion cache,
                reusing equivalent styles.</p></article>
          </div>
          <details><summary>Use light and dark providers together</summary><pre
            ><code>{{this.providerExample}}</code></pre></details>
          <details><summary>Style a custom component with its context</summary><pre
            ><code>{{this.stylingExample}}</code></pre></details>
        </section>
        <p class="showcase-footer">An opt-in experiment with a focused button
          port and a small theme token set. Upstream EUI visual parity, server
          rendering, and performance comparisons are still to be evaluated.</p>
      </EuiEmotionProvider>
    </main>
  </template>
}

---
order: 2
---

<EuiPageHeader @pageTitle="Getting started" />

<EuiSpacer />

<EuiText>

This addon requires some peer dependencies. Install the correct versions of each package, which are listed by the command

<EuiCodeBlock @isCopyable={{true}}>{{"npm info @ember-eui/core peerDependencies"}}</EuiCodeBlock>

<EuiSpacer />

Once you've installed it, you can now install the addon itself:

<EuiCodeBlock @isCopyable={{true}}>{{"ember install @ember-eui/core"}}</EuiCodeBlock>

<EuiSpacer />

<EuiTitle>
  <h3>
    Icons
  </h3>
</EuiTitle>

For icons to work you will need to:

- install `ember-svg-jar`
- add the following `ember-svg-jar` options to your `ember-cli-build.js`:

<EuiCodeBlock @language="ts" @isCopyable={{true}}>
{{t "getting_started.icons_configuration"}}
</EuiCodeBlock>

<EuiTitle>
  <h3>
    Build Configuration, Styles and Theming
  </h3>
</EuiTitle>

<EuiSpacer />

Themes:
There is light and dark theme, you can import them in a few ways to your app.
There's also some extensions made to the @elastic/eui css, they are available via `@ember-eui/core/styles/ember-eui.css`

1. You have a few ways to get the styles importing it statically on any js, so it will be bundled intially.
<EuiCodeBlock @language="ts" @isCopyable={{true}}>
{{t "getting_started.styles_ts"}}
</EuiCodeBlock>
2. Using handlebars you can create an easy swapper
<EuiCodeBlock @language="hbs" @isCopyable={{true}}>
{{t "getting_started.styles_hbs"}}
</EuiCodeBlock>
3. You can dynamically import it, you can have a look at this demo sourcecode change-theme util
<EuiCodeBlock @language="ts" @isCopyable={{true}}>
{{t "getting_started.styles_dynamic"}}
</EuiCodeBlock>
4. You can import them via the old way of importing assets to ember apps
<EuiCodeBlock @language="ts" @isCopyable={{true}}>
{{t "getting_started.styles_old_import"}}
</EuiCodeBlock>

<EuiTitle>
  <h3>
    Runtime configuration
  </h3>
</EuiTitle>

<EuiSpacer />
 v2 addons new need way to allow apps to customize other than using the typical ENV or ember-cli-build configs. There's two recommended ways.

1. Create an initializer and configure ember-eui eui-config service
<EuiCodeBlock @language="ts" @isCopyable={{true}}>
{{t "getting_started.eui_config_initializer"}}
</EuiCodeBlock>
2. In any place you want, inject eui-config service and configure
<EuiCodeBlock @language="ts" @isCopyable={{true}}>
{{t "getting_started.eui_service_injection"}}
</EuiCodeBlock>

<EuiTitle>
  <h3>
    Last steps...
  </h3>
</EuiTitle>

The whole ember ecosystem is working towards v2 spec, so by now we need to do some extra steps for EuiComboBox to work because its an ember-power-select wrapper.

Inside your index.html file, do the following:
Add a div id="ember-basic-dropdown-wormhole" below body-footer meanwhile ember-power-select and ember-basic-dropdown get modernized, also, add in ember-cli-build, inside the app config

<EuiCodeBlock @language="ts" @isCopyable={{true}}>
{{t "getting_started.ember_power_select"}}
</EuiCodeBlock>

<EuiSpacer />

</EuiText>

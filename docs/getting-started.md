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

You _might_ get babel errors for a dependency mistmatch between embroider packages, here's a [link](https://github.com/embroider-build/embroider/issues/1077) for more info,
if so, you can force that all packages use the same dependency with npm `overrides` or yarn `resolutions`, here's a the sample for yarn that you could add to your package.json

<EuiCodeBlock @language="json" @isCopyable={{true}}>
{{t "getting_started.package_configuration"}}
</EuiCodeBlock>

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

<EuiCode>theme</EuiCode>: You can specify the theme you want
<EuiSpacer />

<EuiCodeBlock @language="ts" @isCopyable={{true}}>
{{t "getting_started.build_configuration"}}
</EuiCodeBlock>

<EuiTitle>
  <h3>
    Runtime configuration
  </h3>
</EuiTitle>

<EuiCode>euiComboBoxOptionsHeight</EuiCode>: Set default height for <EuiCode>{{"<EuiComboBox />"}}</EuiCode> options
<EuiSpacer />

<EuiCodeBlock @language="ts" @isCopyable={{true}}>
{{t "getting_started.runtime_configuration"}}
</EuiCodeBlock>

</EuiText>

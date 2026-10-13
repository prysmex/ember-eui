---
order: 12
---

# Configuring the default plugins

<EuiText>

<EuiCode>getDefaultEuiMarkdownPlugins</EuiCode> (and the three <EuiCode>getDefaultEuiMarkdown...Plugins</EuiCode> functions) accept an optional configuration object: <EuiCode>exclude</EuiCode> unregisters default plugins, <EuiCode>processingConfig</EuiCode> configures the processing plugins (<EuiCode>linkProps</EuiCode>: any <strong>EuiLink</strong> arg, e.g. <EuiCode>target</EuiCode>, <EuiCode>color</EuiCode>, <EuiCode>external</EuiCode> or an <EuiCode>onClick</EuiCode> handler, applied to every formatted link), and <EuiCode>parsingConfig</EuiCode> overrides the configuration of a default parsing plugin, the <EuiCode>emoji</EuiCode> options and the link validator (<EuiCode>linkValidator</EuiCode>: <EuiCode>allowProtocols</EuiCode>, <EuiCode>allowRelative</EuiCode> for links starting with <EuiCode>/</EuiCode>, <EuiCode>allowDocumentRelative</EuiCode> and <EuiCode>baseUrl</EuiCode>). Links the validator rejects render as text, the link validator is on by default and allows <EuiCode>https:</EuiCode>, <EuiCode>http:</EuiCode>, <EuiCode>mailto:</EuiCode> and absolute relative links. You can also use <EuiCode>euiMarkdownLinkValidator</EuiCode> in your own parsing plugin list.

The example below excludes the <EuiCode>emoji</EuiCode> plugin and only lets <EuiCode>https:</EuiCode> and <EuiCode>mailto:</EuiCode> links through, with document-relative links (<EuiCode>[link](path)</EuiCode>) enabled. Every link opens in a new tab through <EuiCode>processingConfig.linkProps</EuiCode>.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiMarkdownFormat } from '@ember-eui/core/components';
import { getDefaultEuiMarkdownPlugins } from '@ember-eui/core/utils/markdown/plugins/markdown-default-plugins/index';

const markdownContent = `
- :cry: Automatic emoji formatting has been excluded from this markdown.
- In the example below, only \`https:\` and \`mailto:\` protocols should turn into links.
- Document-relative links have been enabled, so that \`[link](path)\` or \`[link](../another-path)\` will turn into links.

https://elastic.co
http://elastic.co
someone@elastic.co

[Relative link to the EuiMarkdownEditor docs](editor)
[Relative link to EuiPageTemplate docs](../../templates/page-template)
`;

const { processingPlugins, parsingPlugins } = getDefaultEuiMarkdownPlugins({
  exclude: ['emoji'],
  parsingConfig: {
    linkValidator: {
      allowProtocols: ['https:', 'mailto:'],
      allowDocumentRelative: true,
    },
  },
  processingConfig: {
    linkProps: { target: '_blank' },
  },
});

<template>
  <EuiMarkdownFormat
    @value={{markdownContent}}
    @processingPluginList={{processingPlugins}}
    @parsingPluginList={{parsingPlugins}}
  />
</template>
```

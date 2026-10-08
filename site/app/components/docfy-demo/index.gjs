import { hash } from '@ember/helper';
import { EuiSpacer } from '@ember-eui/core/components';
import EuiSplitPanelOuter from '@ember-eui/core/components/eui-split-panel/outer';

import DocfyDemoDescription from './description.gjs';
import DocfyDemoExample from './example.gjs';
import DocfyDemoSnippet from './snippet.gjs';
import DocfyDemoSnippets from './snippets.gjs';
import DemoPlayground from '../demo-playground.gjs';

/**
 * Replaces @docfy/ember's DocfyDemo (see vite.config.mjs, which points the
 * generated page templates here). Same yielded API as docfy's:
 * Description, Example, Snippet and Snippets.
 */
<template>
  {{yield (hash Description=(component DocfyDemoDescription id=@id))}}

  <div class="docfy-demo">
    <EuiSplitPanelOuter
      class="guideSection euiSplitPanel"
      @hasBorder={{true}}
      @paddingSize="none"
      @hasShadow={{false}}
      @grow={{false}}
      ...attributes
    >
      <DemoPlayground @id={{@id}} />
      {{yield
        (hash
          Example=DocfyDemoExample
          Snippet=(component DocfyDemoSnippet id=@id)
          Snippets=(component DocfyDemoSnippets id=@id)
        )
      }}
    </EuiSplitPanelOuter>
  </div>

  <EuiSpacer @size="l" />
  <EuiSpacer @size="l" />
</template>

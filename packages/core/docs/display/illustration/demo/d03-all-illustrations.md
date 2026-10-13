---
order: 3
---

# All illustrations

<EuiText>

Every illustration in `@elastic/eui-illustrations`. Search by name, then select one to see how to import it.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { illustrations } from '@elastic/eui-illustrations';
import {
  EuiCodeBlock,
  EuiEmptyPrompt,
  EuiFlexGrid,
  EuiFlexItem,
  EuiIllustration,
  EuiPanel,
  EuiSpacer,
  EuiText
} from '@ember-eui/core/components';
import EuiSearchBar, { Query } from '@ember-eui/core/components/eui-search-bar';

const items = Object.entries(illustrations)
  .map(([exportName, illustration]) => ({ exportName, ...illustration }))
  .sort((a, b) => a.title.localeCompare(b.title));

const box = {
  placeholder: 'Search illustrations by name',
  incremental: true,
  'aria-label': 'Search illustrations by name'
};

// theme functions (see "Theming your own components"), as upstream's css
const tileCss = (isSelected) => ({ euiTheme }) => ({
  display: 'flex',
  flexDirection: 'column',
  cursor: 'pointer',
  transition: `box-shadow ${euiTheme.animation.fast} ease-in-out, border-color ${euiTheme.animation.fast} ease-in-out`,
  '&:hover': { borderColor: euiTheme.colors.primary },
  ...(isSelected && {
    borderColor: euiTheme.colors.primary,
    boxShadow: `inset 0 0 0 ${euiTheme.border.width.thick} ${euiTheme.colors.primary}`
  })
});
const tileCssDefault = tileCss(false);
const tileCssSelected = tileCss(true);

const artCss = ({ euiTheme }) => ({
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  padding: euiTheme.size.m,
  backgroundColor: euiTheme.colors.lightestShade,
  borderRadius: euiTheme.border.radius.medium,
  marginBottom: euiTheme.size.s
});

const titleCss = ({ euiTheme }) => ({
  flexShrink: 0,
  fontWeight: euiTheme.font.weight.semiBold,
  lineHeight: 1
});

export default class IllustrationGallery extends Component {
  @tracked query = null;
  @tracked selectedId = null;

  get filtered() {
    if (!this.query) return items;
    return Query.execute(this.query, items, { defaultFields: ['title', 'id'] });
  }

  get selected() {
    return this.filtered.find((item) => item.id === this.selectedId) ?? null;
  }

  get snippet() {
    const name = this.selected?.exportName;
    return `import { EuiIllustration } from '@ember-eui/core/components';
import { ${name} } from '@elastic/eui-illustrations';

<template><EuiIllustration @type={{${name}}} /></template>`;
  }

  onSearch = ({ query }) => {
    this.query = query;
  };

  toggle = (item) => {
    this.selectedId = this.selectedId === item.id ? null : item.id;
  };

  isSelected = (item) => item.id === this.selectedId;
  tileCssFor = (item) => (this.isSelected(item) ? tileCssSelected : tileCssDefault);
  select = (item) => () => this.toggle(item);
  pressed = (item) => String(this.isSelected(item));
  label = (item) => `Show code for ${item.title}`;

  <template>
    <EuiSearchBar @box={{box}} @onChange={{this.onSearch}} />

    <EuiSpacer />

    {{#if this.filtered.length}}
      <EuiFlexGrid @columns={{3}} @gutterSize="m">
        {{#each this.filtered key="id" as |item|}}
          <EuiFlexItem>
            <EuiPanel
              @hasShadow={{false}}
              @hasBorder={{true}}
              @paddingSize="s"
              @onClick={{this.select item}}
              @css={{this.tileCssFor item}}
              aria-pressed={{this.pressed item}}
              aria-label={{this.label item}}
            >
              <EuiText @css={{artCss}}>
                <EuiIllustration @type={{item}} @alt="" />
              </EuiText>
              <EuiText @size="m" @textAlign="center" @css={{titleCss}}>
                {{item.title}}
              </EuiText>
            </EuiPanel>
          </EuiFlexItem>
        {{/each}}
      </EuiFlexGrid>
    {{else}}
      <EuiEmptyPrompt @iconType="search">
        <:title><h3>No illustrations found</h3></:title>
        <:body><p>Try a different search term.</p></:body>
      </EuiEmptyPrompt>
    {{/if}}

    {{#if this.selected}}
      <EuiSpacer />
      <EuiCodeBlock @language="gjs" @fontSize="m" @paddingSize="m" @isCopyable={{true}}>
        {{this.snippet}}
      </EuiCodeBlock>
    {{/if}}
  </template>
}
```

---
  order: 1
---
<EuiPageContent
@hasShadow={{false}}
@hasBorder={{false}}
@paddingSize="none"
@color="transparent"
@borderRadius="none" >
<EuiPageContentBody @restrictWidth={{true}}>
<EuiPanel @color="subdued" @hasShadow={{false}} @paddingSize="l">
<EuiFlexGroup @alignItems="center" >
<EuiFlexItem>
<EuiTitle @size="l">

<h1>Ember EUI</h1>
</EuiTitle>
<EuiSpacer />
<EuiSpacer />
<EuiTitle @size="s">
<h2>Ember JS components for Elastic design system</h2>
</EuiTitle>
<EuiSpacer @size="s" />
<EuiText @grow={{false}}>
<p>
This project aims to implement <EuiLink @href="https://github.com/elastic/eui">
<strong>The Elastic UI framework (EUI)</strong>
</EuiLink> css and components in the <EuiLink @external={{true}} @href="https://www.youtube.com/watch?v=GFeRTO1LOuM">ember way</EuiLink>
</p>

</EuiText>
<EuiSpacer @size="l" />
<EuiFlexGroup @gutterSize="s" @wrap={{true}} @responsive={{false}}>
<EuiFlexItem grow={{false}}>
<EuiLink @href="/docs/installation">
<strong>Getting started</strong>
</EuiLink>
</EuiFlexItem>
</EuiFlexGroup>
</EuiFlexItem>

<EuiFlexItem>
 <EuiImage
      @size='original'
      @hasShadow={{false}}
      @alt='eui'
      @src='/assets/euiIlluIntro.svg'
    />
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiPanel>
      <EuiSpacer @size="xxl" />

<EuiSpacer @size="xxl" />

<EuiFlexGrid @columns={{4}} >
<EuiFlexItem  >
<EuiCard
@hasBorder={{true}}
@href="/docs/core/docs/navigation/button"
@textAlign="left"
@image='/assets/Buttons.svg'
@title="Buttons"
@description="Buttons for every usage you might need"
/>
</EuiFlexItem>

<EuiFlexItem  >
<EuiCard
@hasBorder={{true}}
@href="/docs/core/docs/display/card/basic-card"
@textAlign="left"
@image='/assets/Cards.svg'
@title="Cards"
@description="Cards like these help you make repeatable content more presentable"
/>
</EuiFlexItem>
<EuiFlexItem  >
<EuiCard
@hasBorder={{true}}
@href="/docs/core/docs/layout/flex"
@textAlign="left"
@image='/assets/Flex.svg'
@title="Flexible layouts"
@description="Create layouts by using flex groups, grids, and items"
/>
</EuiFlexItem>
<EuiFlexItem >
<EuiCard
@hasBorder={{true}}
@href="/docs/core/docs/forms/form-layouts/described-form-groups"
@textAlign="left"
@image='/assets/Forms.svg'
@title="Forms"
@description="Input tags, layouts, and validation for your forms"
/>
</EuiFlexItem>

<EuiFlexItem >
<EuiCard
@hasBorder={{true}}
@href="/docs/core/docs/display/icons"
@textAlign="left"
@image='/assets/Icons.svg'
@title="Icons"
@description="Our SVG icon library gives you full control over size and color"
/>
</EuiFlexItem>

<EuiFlexItem >
<EuiCard
@hasBorder={{true}}
@href="/docs/core/docs/layout/page"
@textAlign="left"
@image='/assets/Pages.svg'
@title="Pages"
@description="Layout your whole application page with this component and its series of child components"
/>
</EuiFlexItem>

<EuiFlexItem >
<EuiCard
@hasBorder={{true}}
@href="/docs/core/docs/display/text"
@textAlign="left"
@image='/assets/Text.svg'
@title="Text"
@description="Simple HTML text like paragraphs and lists are wrapped in a single text component for styling"
/>
</EuiFlexItem>

<EuiFlexItem >
<EuiCard
@hasBorder={{true}}
@href="/docs/core/docs/layout/modal"
@textAlign="left"
@image='/assets/Modals.svg'
@title="Modal"
@description="A modal works best for focusing users' attention on a short amount of content and getting them to make a decision. "
/>
</EuiFlexItem>

</EuiFlexGrid>

<EuiSpacer @size="xl" />

<EuiFlexGroup @justifyContent="spaceAround">

<EuiFlexItem @grow={{false}}>

<EuiText @textAlign='center'><p>
This project exists thanks to all the people who contribute

</p>
<p><EuiLink @href="https://github.com/prysmex/ember-eui">
<strong>Contributing</strong>
</EuiLink></p>
</EuiText>
<EuiImage
@size='xl'
@hasShadow={{false}}
@alt='contrib'
@url='https://contrib.rocks/image?repo=prysmex/ember-eui'
/>

</EuiFlexItem>

 </EuiFlexGroup>

  <div>
  <EuiSpacer @size="xl" />
        <EuiText @size="xs" @textAlign="center" @color="subdued">
          <p>
            EUI is dual-licensed under
            <EuiLink @href="https://github.com/elastic/eui/blob/main/licenses/ELASTIC-LICENSE-2.0.md">
              Elastic License 2.0
            </EuiLink>
            and
            <EuiLink @href="https://github.com/elastic/eui/blob/main/licenses/SSPL-LICENSE.md">
              Server Side Public License, v 1
            </EuiLink>
            | Crafted with
            <span
              role="img"
              aria-label="love"
              className="guideHome__footerHeart"
            >
              ❤️
            </span>
            by 
            <EuiLink @href="https://github.com/prysmex/ember-eui" @external={{false}} @target="_blank">
            Prysmex
            </EuiLink>
          </p>
        </EuiText>
      </div>

</EuiPageContentBody>
</EuiPageContent>

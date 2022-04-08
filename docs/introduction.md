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
<h2>All the power of Elastic design system, now on Ember JS</h2>
</EuiTitle>
<EuiSpacer @size="s" />
<EuiText @grow={{false}}>
<p>
This project aims to implement <EuiLink @href="https://github.com/elastic/eui">
<strong>The Elastic UI framework (EUI)</strong>
</EuiLink> css and components in the ember way. 
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

</EuiPageContentBody>
</EuiPageContent>

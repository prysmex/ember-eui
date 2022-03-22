# Demo

```hbs template
<div>
  <EuiTitle @size='m'>
    Padding
  </EuiTitle>
  <EuiSpacer />
  <EuiText>
    <p>
      The most basic use is to simply add padding around your content.
    </p>
  </EuiText>
  <EuiSpacer @size='l' />
  <EuiPanel @paddingSize='none'>
    paddingSize=&quot;none&quot;
  </EuiPanel>
  <EuiSpacer @size='l' />
  <EuiPanel @paddingSize='s'>
    paddingSize=&quot;s&quot;
  </EuiPanel>
  <EuiSpacer @size='l' />
  <EuiPanel @paddingSize='m'>
    paddingSize=&quot;m&quot; (default)
  </EuiPanel>
  <EuiSpacer @size='l' />
  <EuiPanel @paddingSize='l'>
    paddingSize=&quot;l&quot;
  </EuiPanel>
</div>
<EuiSpacer />
<EuiTitle @size='m'>
  Shadow and border
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    EuiPanel can give depth to your container with hasShadow while hasBorder can
    add containment. Just be sure not to include too many nested panels with
    these settings.
  </p>
</EuiText>
<EuiPanel @hasShadow={{false}}>
  @hasShadow={{false}}
</EuiPanel>
<EuiSpacer @size='l' />
<EuiPanel @hasBorder={{true}}>
  @hasBorder={{true}}
</EuiPanel>
<EuiSpacer />
<EuiTitle @size='m'>
  Colors and corners
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Use color to add background shading to your panel and provide an additional
    helpful aesthetic to your container in context. Be mindful to use color
    sparingly. You can also remove the rounded corners depending on the
    placement of your panel with @borderRadius="none" Passing
    @color="transparent" can give you a quick empty box simply for adding
    padding to all sides.
  </p>
</EuiText>

<EuiPanel @color='subdued' @borderRadius='none' @hasShadow={{false}}>
  <p>I am a simple shaded box</p>
</EuiPanel>

<EuiSpacer />

<EuiPanel @color='transparent' @hasBorder={{false}}>
  <p>I am a transparent box simply for padding</p>
</EuiPanel>

<EuiSpacer />
<EuiTitle @size='m'>
  Growing height
</EuiTitle>
<EuiSpacer />
<EuiText>
  <p>
    Using EuiPanel in an EuiFlexItem will always grow its height to match. This
    is great for rows of panels. However, you can also turn this feature off by
    setting @grow={{false}}.
  </p>
</EuiText>
<EuiSpacer />
<EuiFlexGroup @gutterSize='l'>
  <EuiFlexItem>
    <EuiPanel>
      <EuiText>
        <p>
          I am some panel content...
          <br />
          ...
          <br />
          ...
          <br />
          whose content is tall
        </p>
      </EuiText>
    </EuiPanel>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiPanel @grow={{true}}>
      <EuiText>
        <p>I am some panel content... whose content will grow</p>
      </EuiText>
    </EuiPanel>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiPanel @grow={{false}}>
      <EuiText>
        <p>I am some panel content... whose content did not grow</p>
      </EuiText>
    </EuiPanel>
  </EuiFlexItem>
</EuiFlexGroup>
```

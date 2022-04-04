---
order: 2
---

# Click an image for a fullscreen version

 <EuiText>
    <p>Apply the <EuiCode @language="text">allowFullScreen</EuiCode> prop to make the image clickable and show a fullscreen version. Note that the second image also passes <EuiCode @language="js">fullScreenIconColor<span class="token operator">=</span><span class="token string">"dark"</span></EuiCode> to change icon color to better contrast against the light background of that image.</p>
    </EuiText>

```hbs template
<EuiFlexGroup>
  <EuiFlexItem @grow={{false}}>
    <EuiImage
      @size='m'
      @hasShadow={{true}}
      @allowFullScreen={{true}}
      @caption='Click me'
      @alt='Accessible image alt goes here'
      @url='https://source.unsplash.com/2000x1000/?Nature'
    />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiImage
      @size='m'
      @hasShadow={{true}}
      @allowFullScreen={{true}}
      @caption='Click me'
      @alt='Accessible image alt goes here'
      @fullScreenIconColor='dark'
      @url='https://source.unsplash.com/1000x2000/?Nature'
    />
  </EuiFlexItem>
</EuiFlexGroup>
```

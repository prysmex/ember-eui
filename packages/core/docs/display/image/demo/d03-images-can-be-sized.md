---
order: 3
---

# Images can be sized

<EuiText>
    <p>Images can be sized by passing the <EuiCode @language="text">size</EuiCode> prop a value of <EuiCode @language="text">s / m / l / xl / original / fullWidth / number / string</EuiCode>. This size sets the <strong>maximum</strong> length of the longest edge of the image, whether that is height or width, and scales it. Only the provided sizing values will also increase the size of a smaller image.</p>
    </EuiText>

```hbs template
<div>
  <EuiImage
    @hasShadow={{true}}
    @allowFullScreen={{true}}
    @size='{{50}}'
    @caption='Custom size (50)'
    @alt='Accessible image alt goes here'
    @url='https://source.unsplash.com/1000x1000/?Nature'
  />
  <EuiSpacer />
  <EuiImage
    @size='s'
    @hasShadow={{true}}
    @allowFullScreen={{true}}
    @caption='Small'
    @alt='Accessible image alt goes here'
    @url='https://source.unsplash.com/1000x1000/?Nature'
  />
  <EuiSpacer />
  <EuiImage
    @size='m'
    @hasShadow={{true}}
    @allowFullScreen={{true}}
    @caption='Medium'
    @alt='Accessible image alt goes here'
    @url='https://source.unsplash.com/1000x1000/?Nature'
  />
  <EuiSpacer />
  <EuiImage
    @size='l'
    @hasShadow={{true}}
    @allowFullScreen={{true}}
    @caption='Large'
    @alt='Accessible image alt goes here'
    @url='https://source.unsplash.com/1000x1000/?Nature'
  />
  <EuiSpacer />
  <EuiImage
    @size='xl'
    @hasShadow={{true}}
    @allowFullScreen={{true}}
    @caption='Extra large'
    @alt='Accessible image alt goes here'
    @url='https://source.unsplash.com/1000x1000/?Nature'
  />
  <EuiSpacer />
  <EuiImage
    @hasShadow={{true}}
    @allowFullScreen={{true}}
    @caption='Original'
    @alt='Accessible image alt goes here'
    @url='https://source.unsplash.com/1000x1000/?Nature'
  />
  <EuiSpacer />
  <EuiImage
    @hasShadow={{true}}
    @allowFullScreen={{true}}
    @size='fullWidth'
    @caption='Full width'
    @alt='Accessible image alt goes here'
    @url='https://source.unsplash.com/1000x1000/?Nature'
  />
</div>
```

# Demo

```hbs template
<EuiAvatar @size="s" @name="Raphael" />
<EuiAvatar @size="m" @name="Donatello" />
<EuiAvatar @size="l" @name="Leonardo" @color="#BD10E0" />
<EuiAvatar @size="xl" @name="Michelangelo" />
<EuiSpacer />
<EuiAvatar @size="s" @name="Cat" @imageUrl="https://source.unsplash.com/64x64/?cat" />
<EuiAvatar @size="m" @name="Cat" @imageUrl="https://source.unsplash.com/64x64/?cat" />
<EuiAvatar @size="l" @name="Cat" @imageUrl="https://source.unsplash.com/64x64/?cat" />
<EuiAvatar @size="xl" @name="Cat" @imageUrl="https://source.unsplash.com/64x64/?cat" />
<EuiSpacer />
<EuiAvatar @size="m" @name="Single" />
<EuiAvatar @size="m" @name="Two Words" />
<EuiAvatar @size="m" @name="More Than Two Words" />
<EuiAvatar @size="m" @name="lowercase words" />
<EuiSpacer />
<EuiTitle @size="xs">
  <h4>
    Custom & Spaces type
  </h4>
</EuiTitle>
<EuiSpacer />
<EuiAvatar @size="m" @type="space" @name="Kibana" initialsLength={{2}} />
<EuiAvatar @size="m" @type="space" @name="Leonardo Dude" initialsLength={{1}} />
<EuiAvatar @size="m" @type="space" @name="Not provided" initials="?" />
<EuiAvatar @size="m" @type="space" @name="Engineering Space" @initials="En" @initialsLength={{2}} />
```
---
order: 8
---

# Image URLs

<EuiText>

A `@type` that is neither an EUI icon nor a registered name is used as the
`src` of an `<img>`, e.g. a file in `public/` or an external URL. The size
classes still apply; colors do not (the image is not inline), and `@title`
becomes its `alt` text.

Prefer registered svgs (above) for icons of your own: they can be colored and
are part of your build. In development, a `@type` that looks like a path or
URL (and so may have been an ember-svg-jar name) logs a warning suggesting to
register it.

</EuiText>

```hbs template
<EuiFlexGroup @gutterSize="l" @alignItems="center" @responsive={{false}}>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon @type="/assets/euivector.svg" @size="xl" @title="Ember EUI" />
  </EuiFlexItem>
  <EuiFlexItem @grow={{false}}>
    <EuiIcon
      @type="https://upload.wikimedia.org/wikipedia/commons/0/02/SVG_logo.svg"
      @size="xl"
      @title="SVG logo"
    />
  </EuiFlexItem>
</EuiFlexGroup>
```

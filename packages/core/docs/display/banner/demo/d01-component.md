---
order: 1
---

# Component

<EuiText>

The component requires a `@title` and a `<:media>` block. All other arguments are optional.

</EuiText>

```hbs template
<EuiBanner
  @title="Introducing a new feature"
  @text="Get more done with the latest improvements to your workspace. Explore what's new and start using it today."
>
  <:media>
    <img src="https://placehold.co/80x80" alt="" aria-hidden="true" />
  </:media>
</EuiBanner>
```

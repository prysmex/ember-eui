---
order: 3
---

# Timeline avatar

<EuiText>

The timeline icon is a very important part of the comment:

- By default, each **EuiComment** shows an avatar with the `user` icon. A `@timelineAvatarAriaLabel` should be provided when using this default option.
- You can customize your avatar by passing to `@timelineIcon` any of the icon types that **EuiIcon** supports. The icon will show inside a `subdued` avatar. Consider this option when showing a system update. Providing a `@timelineAvatarAriaLabel` is recommended.
- You can further customize the timeline icon by putting an **EuiAvatar** in the `<:timelineIcon>` block.

</EuiText>

```hbs template
<EuiCommentList aria-label="An example with different timeline icons">
  <EuiComment @timelineAvatarAriaLabel="Andre Diaz">
    <:username>andred</:username>
    <:event>is using a default avatar</:event>
    <:body>
      <EuiText @size="s">
        <p>
          The avatar initials is generated from the <EuiCode>username</EuiCode>
          argument.
        </p>
      </EuiText>
    </:body>
  </EuiComment>

  <EuiComment @timelineAvatarAriaLabel="System" @timelineIcon="dot">
    <:username>system</:username>
    <:event>
      The <EuiCode>@timelineIcon</EuiCode> is using a <EuiCode>dot</EuiCode> icon.
    </:event>
  </EuiComment>

  <EuiComment @timelineAvatarAriaLabel="Beautiful cat">
    <:timelineIcon>
      <EuiAvatar @name="Cat" @imageUrl="https://picsum.photos/id/40/64" />
    </:timelineIcon>
    <:username>cat</:username>
    <:event>is using a custom avatar</:event>
    <:body>
      <EuiText @size="s">
        <p>
          The <EuiCode>&lt;:timelineIcon&gt;</EuiCode> block is using a custom
          <strong>EuiAvatar</strong>.
        </p>
      </EuiText>
    </:body>
  </EuiComment>
</EuiCommentList>
```

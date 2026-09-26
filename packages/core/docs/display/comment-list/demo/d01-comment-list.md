---
order: 1
---

# Comment list

<EuiText>

Regular comments have a body in a panel; `@type="update"` comments are a
single line recording an event. Each comment's blocks fill its parts:
`<:username>`, `<:event>`, `<:timestamp>`, `<:actions>`, `<:body>` and
`<:timelineIcon>`.

</EuiText>

```hbs template
<EuiCommentList>
  <EuiComment @type='regular'>
    <:username>
      kyloRen
    </:username>
    <:event>
      destroyed the jedi temple
    </:event>
    <:body>
      <EuiText>
        <p>
          Far out in the uncharted backwaters of the unfashionable end of the
          western spiral arm of the Galaxy lies a small unregarded yellow sun.
        </p>
      </EuiText>
    </:body>
    <:actions>
      <EuiButtonIcon @iconType='wrench' aria-label='Edit comment' />
    </:actions>
  </EuiComment>
  <EuiComment @type='update'>
    <:username>
      lukeSW
    </:username>
    <:event>
      went into hiding
    </:event>
    <:timestamp>
      on 2015-02-05
    </:timestamp>
  </EuiComment>
  <EuiComment @type='update'>
    <:username>
      r2d2
    </:username>
    <:event>
      kinda shut down
    </:event>
    <:body>
      <EuiText>
        <p>
          He went into a sort of hibernation or low power mode, you know? Like
          when you 'sleep' a computer.
        </p>
      </EuiText>
    </:body>
    <:timestamp>
      on 2015-02-05
    </:timestamp>
  </EuiComment>
  <EuiComment @timelineIcon='listAdd' @type='update'>
    <:username>
      <EuiFlexGroup @responsive={{false}} @alignItems='center' @gutterSize='s'>
        <EuiFlexItem @grow={{false}}>
          <EuiAvatar
            @type='space'
            @initials='FO'
            @name='First Order'
            @initialLength={{2}}
            @size='s'
          />
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          firstOrder
        </EuiFlexItem>
      </EuiFlexGroup>
    </:username>
    <:event>
      <EuiFlexGroup @responsive={{false}} @alignItems='center' @gutterSize='s'>
        <EuiFlexItem @grow={{false}}>
          was created by
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiBadge @color='accent'>snoke</EuiBadge>
        </EuiFlexItem>
      </EuiFlexGroup>
    </:event>
    <:timestamp>
      on 2015-02-05
    </:timestamp>
  </EuiComment>
  <EuiComment @type='regular'>
    <:timelineIcon>
      <EuiAvatar @initials='RS' @name='Rey Skywokah' @type='user' />
    </:timelineIcon>
    <:username>
      reySkywokah
    </:username>
    <:event>
      turned out to be all mighty
    </:event>
    <:body>
      <EuiText>
        <p>
          How and why did this happen? Who knows..?
        </p>
      </EuiText>
    </:body>
    <:actions>
      <EuiButtonIcon @iconType='questionInCircle' />
    </:actions>
    <:timestamp>
      on 2015-02-05
    </:timestamp>
  </EuiComment>
</EuiCommentList>
```

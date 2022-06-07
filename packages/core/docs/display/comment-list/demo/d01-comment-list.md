<EuiText>
	<p>
The Comment List serves merely as a wrapper for various comments.
It does contain the comments from trying to connect each other in case you had multiple
unrelated comment lists in the same page.

The original component from the React.js framework receives a @comments object, and maps them into the EuiCommentList component. For Ember.js, just pass them as children.

  </p>

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
      <EuiButtonIcon @iconType='wrench' />
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

---
order: 3
---

# Your own rendering

<EuiText>

With a block, it yields the diff's chunks (`[operation, text]`, where the
operation is `-1` removed, `1` added, `0` unchanged) and renders nothing
itself, e.g. to count the changes or style them differently.

</EuiText>

```hbs template
<EuiTextDiff
  @beforeText="Deploy on Monday to staging"
  @afterText="Deploy on Friday to production"
  as |chunks|
>
  <EuiText>
    <p>
      {{#each chunks as |chunk|}}
        {{#if (eq (get chunk "0") 1)}}
          <EuiBadge @color="success">{{get chunk "1"}}</EuiBadge>
        {{else if (eq (get chunk "0") -1)}}
          <EuiBadge @color="danger">{{get chunk "1"}}</EuiBadge>
        {{else}}
          {{get chunk "1"}}
        {{/if}}
      {{/each}}
    </p>
  </EuiText>
</EuiTextDiff>
```

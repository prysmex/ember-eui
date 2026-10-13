---
order: 1
---

# Single line

<EuiText>

`EuiTextTruncate` provides customizable and size-aware single line text truncation.

The four truncation styles supported are `start`, `end`, `startEnd`, and `middle`. Resize the below demo (drag the panel's resize handle) to see how different truncation styles respond to dynamic width changes.

</EuiText>

```hbs template
<EuiText>
  <EuiPanel style='overflow: auto; resize: inline; inline-size: 35ch; max-inline-size: 100%;'>
    <EuiTextTruncate
      @text='The quick brown fox jumps over the lazy dog.'
      @truncation='start'
    />
    <EuiTextTruncate
      @text='But the dog wasn’t lazy, it was just practicing mindfulness, so it had a greater sense of life-satisfaction than that fox with all its silly jumping.'
      @truncation='end'
    />
    <EuiTextTruncate
      @text='And from the fox’s perspective, life was full of hoops to jump through, low-hanging fruit to jump for, and dead car batteries to jump-start.'
      @truncation='startEnd'
    />
    <EuiTextTruncate
      @text='So it thought the dog was making a poor life choice by focusing so much on mindfulness. What if its car broke down?'
      @truncation='middle'
    />
  </EuiPanel>
</EuiText>
```

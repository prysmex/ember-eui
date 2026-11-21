---
title: Record footer
order: 75
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: record footer"/>
<EuiSpacer @size="l" />

<EuiText>

Your own block under the expanded record's fields: comments, history or
actions for the record.

`<:recordFooter as |record sheet|>` adds your own block below the fields
(and the hidden fields), after a line, in the flyout and in the modal:
`record` is the expanded record, `sheet` the block API the toolbar gets.
The arrows re-render it with the next record. It is inside the shell's
focus trap, so its inputs and buttons work with the keyboard; the
record's keys stay on its boxes, so typing in the block types there, and
Escape in a text box of the block does not close the record.

```gjs
<EuiSheet @fields={{this.fields}} @records={{this.records}} …>
  <:recordFooter as |record|>
    <MyComments @recordId={{record.id}} />
  </:recordFooter>
</EuiSheet>
```

The sheet stores no comments or history: they are your data, shown by
your component.

## Related

- [Expanded record](/docs/sheet/docs/sheet/rows/expanded-record)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>

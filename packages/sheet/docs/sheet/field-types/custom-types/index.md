---
title: Custom field types and editors
order: 42
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: custom field types and editors"/>
<EuiSpacer @size="l" />

<EuiText>

Your own types in `@fieldTypes`: a `parse` and a `format`, and, if you
want, your own cell, editor and part of the field editor. A built-in
type can be wrapped too, with another editor.

## In the field editor

A type can name itself in the field editor's type select with `label`
(default: the built-in name, "Single line text", "Single select", …) and
add its own part of the editor with `fieldOptions`, a component that gets
`draft`, `field` (on edit), `messages` and `onChange(patch)`, which merges
keys into the draft. List the type in `@creatableFieldTypes` to offer it.
`linkedRecord`, `user` and `attachment` are not offered by default: they
need `search` or `upload` functions, which a draft cannot hold; list them
and complete the field in your handler.

## Related

- [All field types](/docs/sheet/docs/sheet/field-types)
- [Field editor](/docs/sheet/docs/sheet/fields)
- [API reference](/docs/sheet/docs/sheet/more/api-reference)

</EuiText>

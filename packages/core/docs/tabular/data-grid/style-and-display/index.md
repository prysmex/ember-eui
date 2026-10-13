---
title: Data grid style & display
order: 5
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Data grid style & display"/>
<EuiSpacer @size="l" />

<EuiText>

**EuiDataGrid**'s look is set with `@gridStyle` (borders, stripes, row
hover, header and footer styles, font size, cell padding and row classes)
and its row heights with `@rowHeightsOptions`. Users can change the density
and row height from the toolbar's display selector; both objects take an
`onChange` callback to follow those changes. The examples below cover grid
styles, row classes, default, overridden and automatic row heights, and
reacting to the user's display changes.

## Row heights options

By default, all rows get a height of **34 pixels**, but there are scenarios
where you might want to adjust the height to fit more content. To do that,
you can pass an object to the `@rowHeightsOptions` argument. This object
accepts the following properties:

- `defaultHeight`
  - Defines the default size for all rows
  - Can be configured with an exact pixel height, a line count, or `"auto"`
    to fit all content
- `rowHeights`
  - Overrides the height for a specific row
  - Can be configured with an exact pixel height, a line count, or `"auto"`
    to fit all content
- `lineHeight`
  - Sets a default line height for all cells, which is used to calculate
    row height
  - Accepts any value that the `line-height` CSS property normally takes
    (e.g. px, ems, rems, or unitless)
- `onChange`
  - Optional callback when the user changes the data grid's internal
    `rowHeightsOptions` (e.g., via the toolbar display selector).
  - Can be used to store and preserve user display preferences on page
    refresh - see the "Adjusting your grid to user/toolbar changes" example
    below.
- `scrollAnchorRow`
  - Optional indicator of the row that should be used as an anchor for
    vertical layout shift compensation.
  - Can be set to the default `undefined`, `"start"`, or `"center"`.
  - If set to `"start"`, the topmost visible row will monitor for unexpected
    changes to its vertical position and try to compensate for these by
    scrolling the grid scroll container such that the topmost row position
    remains stable.
  - If set to `"center"`, the middle visible row will monitor for unexpected
    changes to its vertical position and try to compensate for these by
    scrolling the grid scroll container such that the middle row position
    remains stable.
  - This is particularly useful when the grid contains `auto` sized rows.
    Since these rows are measured as they appear in the overscan, they can
    cause surprising shifts of the vertical position of all following rows
    when their measured height is different from the estimated height. See
    the [scroll anchoring example](/docs/core/docs/tabular/data-grid/container-constraints).

<EuiCallOut @title="Rows have minimum height requirements" @color="warning" @size="s">
  <p>
    Rows must be at least <strong>34 pixels</strong> tall so they can render
    at least one line of text. If you provide a smaller height the row will
    default to <strong>34 pixels</strong>.
  </p>
</EuiCallOut>

</EuiText>

<EuiHorizontalRule />

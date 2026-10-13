---
title: Table layout guidelines
order: 4
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Table layout guidelines"/>
<EuiSpacer @size="l" />

<EuiText>

These guidelines help you build clear, accessible tables that are easy to
scan at any viewport size. They apply to
[EuiBasicTable](../basic-table), [EuiInMemoryTable](../in-memory-table)
and [custom tables](../table).

The key points to remember:

- **The table contents must look right on all container sizes**. Always
  test table and column configurations on small and large screens, and
  remember the dynamic layout elements like push flyouts, sidebars and
  other elements that reduce the available width.
- All tables should **enable horizontal scrolling** on overflow with
  `@scrollableInline={{true}}` and `@tableLayout="auto"` to maintain
  legibility.
- **All columns must have the width and truncation options set** to best
  fit the content: use the `em` unit for columns with text, and `px` for
  static-size elements like plots.
- Upstream EUI asks for a sticky actions column (`sticky: true`) as the last
  column; sticky actions columns are not supported by Ember EUI yet.
- Column **headers should be concise and never truncated**. Use iconography
  in place of lengthy column titles; add a `nameTooltip` when additional
  context is needed.
- User content in cells must not overly extend the column's width.

You can find more details about the rules below.

## Enable horizontal scrolling

Set `@scrollableInline={{true}}` and `@tableLayout="auto"` on all tables,
so they can scroll horizontally on overflow rather than compressing columns
into illegibility. All data tables should also set
`@responsiveBreakpoint={{false}}` to disable the mobile card view unless
the table has up to 3 columns and there's a valid UX reason to keep it
enabled.

Test tables at these viewport sizes to cover a wide range of client
devices: 400px, 600px (or with a push flyout open), 1200px, 2000px. Be
aware of content scaling ratios in displays.

## Column sizing

Columns must be configured to fit the content they render using the
`width`, `minWidth` and `maxWidth` options.

Begin with the heading cell: the column's title must be short and clear.
Set `minWidth` to fit the whole title without truncation. Next, adjust for
the body content:

- **Constant size columns** like icon indicators or toggle switches should
  use a static width. Set `width`, `minWidth` and `maxWidth` to the same
  value to prevent the column expanding and shrinking in undesirable
  scenarios.
- **Predefined value columns** like status badges displaying one of the
  known values, should set `minWidth` to fit the longest possible value
  without truncating.
- **Dynamic value columns** displaying user-provided or generated content
  must set `width`, `minWidth` and `maxWidth` to precisely control sizing
  for all possible lengths of inputs. Check the constraints set on the DB
  level to find the longest possible value.

</EuiText>

<EuiSpacer />

<EuiFlexGroup @gutterSize="m">
  <EuiFlexItem>
    <EuiPanel @color="subdued" @paddingSize="l" @hasBorder={{true}} style="min-height: 130px">
      <EuiTable @scrollableInline={{true}} @tableLayout="auto" @responsiveBreakpoint={{false}}>
        <EuiTableHeader>
          <EuiTableHeaderCell>Name</EuiTableHeaderCell>
          <EuiTableHeaderCell>Status</EuiTableHeaderCell>
          <EuiTableHeaderCell @width="5em" @align="right">Orders</EuiTableHeaderCell>
        </EuiTableHeader>
        <EuiTableBody>
          <EuiTableRow>
            <EuiTableRowCell>Lisa Nguyen</EuiTableRowCell>
            <EuiTableRowCell @textOnly={{false}}><EuiHealth @color="success">Active</EuiHealth></EuiTableRowCell>
            <EuiTableRowCell @width="5em" @align="right">3</EuiTableRowCell>
          </EuiTableRow>
          <EuiTableRow>
            <EuiTableRowCell>Ben Park</EuiTableRowCell>
            <EuiTableRowCell @textOnly={{false}}><EuiHealth @color="danger">Inactive</EuiHealth></EuiTableRowCell>
            <EuiTableRowCell @width="5em" @align="right">12</EuiTableRowCell>
          </EuiTableRow>
        </EuiTableBody>
      </EuiTable>
    </EuiPanel>
    <EuiSpacer @size="s" />
    <EuiText @size="s">
      <EuiTextColor @color="success"><strong>Do</strong></EuiTextColor>
      <p>Size columns to fit their content. Headers are fully readable and cells use space efficiently.</p>
    </EuiText>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiPanel @color="subdued" @paddingSize="l" @hasBorder={{true}} style="min-height: 130px">
      <EuiTable @scrollableInline={{true}} @tableLayout="auto" @responsiveBreakpoint={{false}}>
        <EuiTableHeader>
          <EuiTableHeaderCell>Name</EuiTableHeaderCell>
          <EuiTableHeaderCell>Status</EuiTableHeaderCell>
          <EuiTableHeaderCell @width="3em" @align="right" @maxWidth="3em">Orders</EuiTableHeaderCell>
        </EuiTableHeader>
        <EuiTableBody>
          <EuiTableRow>
            <EuiTableRowCell>Lisa Nguyen</EuiTableRowCell>
            <EuiTableRowCell @textOnly={{false}}><EuiHealth @color="success">Active</EuiHealth></EuiTableRowCell>
            <EuiTableRowCell @width="3em" @align="right" @maxWidth="3em">3</EuiTableRowCell>
          </EuiTableRow>
          <EuiTableRow>
            <EuiTableRowCell>Ben Park</EuiTableRowCell>
            <EuiTableRowCell @textOnly={{false}}><EuiHealth @color="danger">Inactive</EuiHealth></EuiTableRowCell>
            <EuiTableRowCell @width="3em" @align="right" @maxWidth="3em">12</EuiTableRowCell>
          </EuiTableRow>
        </EuiTableBody>
      </EuiTable>
    </EuiPanel>
    <EuiSpacer @size="s" />
    <EuiText @size="s">
      <EuiTextColor @color="danger"><strong>Don't</strong></EuiTextColor>
      <p>Leave too little space for the column name or body content.</p>
    </EuiText>
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer />

<EuiText>

### Header tooltips

Columns that need a description or further explanation should use the
`nameTooltip` option with `icon: 'question'`. Never render an `EuiToolTip`
in the column's name.

```js
{
  field: 'service_health',
  name: 'Health',
  nameTooltip: {
    icon: 'question',
    content: 'Health status is determined by the latency anomalies detected by the ML jobs',
  },
}
```

## Text alignment

Use the following `align` settings for each of the content types:

| Content type | Alignment | Rationale |
| --- | --- | --- |
| Standard text | `left` (default) | Matches the natural reading direction for most languages. |
| Numbers and metrics | `right` | Allows users to compare magnitudes and decimal places visually. |
| Booleans and icons | `center` | Provides visual balance for narrow, symmetrical columns. |
| Actions | `right` | Keeps the primary interaction point near the edge of the container. |

</EuiText>

<EuiSpacer />

<EuiFlexGroup @gutterSize="m">
  <EuiFlexItem>
    <EuiPanel @color="subdued" @paddingSize="l" @hasBorder={{true}} style="min-height: 130px">
      <EuiTable @scrollableInline={{true}} @tableLayout="auto" @responsiveBreakpoint={{false}}>
        <EuiTableHeader>
          <EuiTableHeaderCell>Item</EuiTableHeaderCell>
          <EuiTableHeaderCell @align="right">Revenue</EuiTableHeaderCell>
        </EuiTableHeader>
        <EuiTableBody>
          <EuiTableRow>
            <EuiTableRowCell>Project A</EuiTableRowCell>
            <EuiTableRowCell @align="right">1,234.56</EuiTableRowCell>
          </EuiTableRow>
          <EuiTableRow>
            <EuiTableRowCell>Project B</EuiTableRowCell>
            <EuiTableRowCell @align="right">89.90</EuiTableRowCell>
          </EuiTableRow>
          <EuiTableRow>
            <EuiTableRowCell>Project C</EuiTableRowCell>
            <EuiTableRowCell @align="right">502.00</EuiTableRowCell>
          </EuiTableRow>
        </EuiTableBody>
      </EuiTable>
    </EuiPanel>
    <EuiSpacer @size="s" />
    <EuiText @size="s">
      <EuiTextColor @color="success"><strong>Do</strong></EuiTextColor>
      <p>Right-align numbers so digits and decimal places line up for easy comparison.</p>
    </EuiText>
  </EuiFlexItem>
  <EuiFlexItem>
    <EuiPanel @color="subdued" @paddingSize="l" @hasBorder={{true}} style="min-height: 130px">
      <EuiTable @scrollableInline={{true}} @tableLayout="auto" @responsiveBreakpoint={{false}}>
        <EuiTableHeader>
          <EuiTableHeaderCell>Item</EuiTableHeaderCell>
          <EuiTableHeaderCell>Revenue</EuiTableHeaderCell>
        </EuiTableHeader>
        <EuiTableBody>
          <EuiTableRow>
            <EuiTableRowCell>Project A</EuiTableRowCell>
            <EuiTableRowCell>1,234.56</EuiTableRowCell>
          </EuiTableRow>
          <EuiTableRow>
            <EuiTableRowCell>Project B</EuiTableRowCell>
            <EuiTableRowCell>89.90</EuiTableRowCell>
          </EuiTableRow>
          <EuiTableRow>
            <EuiTableRowCell>Project C</EuiTableRowCell>
            <EuiTableRowCell>502.00</EuiTableRowCell>
          </EuiTableRow>
        </EuiTableBody>
      </EuiTable>
    </EuiPanel>
    <EuiSpacer @size="s" />
    <EuiText @size="s">
      <EuiTextColor @color="danger"><strong>Don't</strong></EuiTextColor>
      <p>Left-align numbers. Magnitudes become harder to compare at a glance.</p>
    </EuiText>
  </EuiFlexItem>
</EuiFlexGroup>

<EuiSpacer />

<EuiText>

## Text wrapping and truncation

By default, table cells wrap text to fit the container, unless the
`maxWidth` option is not configured. However, some content becomes
difficult to read when broken across many lines.

- Never wrap or truncate any numeric, boolean, monetary values and
  short-text columns (e.g., UUIDs). For short yet unknown content length
  use the `eui-textNoWrap` class (`className: 'eui-textNoWrap'`).
- Long-text columns displaying important information such as names should
  never be truncated. You may enable truncation on text over 4 lines of
  text to preserve readability. Always set `maxWidth` to prevent
  overexpansion.

</EuiText>

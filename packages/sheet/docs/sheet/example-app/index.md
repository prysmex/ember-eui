---
title: Example app
order: 1
---

<EuiSpacer/>
<EuiPageHeader @pageTitle="Sheet: an example app"/>
<EuiSpacer @size="l" />

<EuiText>

A product list as an app would have it: 230 products on a (fake)
server, loaded 50 at a time, edited in place, grouped, imported from a
supplier's file and exported to CSV. One component and one module of
data; each part below links to the page that explains it.

- **Loading more as you scroll.** `fetchProducts(offset, limit)` answers
  after 400 ms. `@onVisibleRangeChange` asks for the next page when the
  last record on screen is within 20 of the end, `@isLoading` shows the
  bar meanwhile, and the component keeps its own cursor (`fetched`).
  The add row waits until every product is loaded (`@canInsert`): an
  added record would otherwise land before products not loaded yet.
  ([Load more](/docs/sheet/docs/sheet/data/load-more#loading-more-as-you-scroll))
- **Groups.** "Group by category", or "Group by this field" in a column's
  menu (`@onGroupByChange`). Grouping needs every product, so it loads
  the rest first; then `localRecords` groups them (`store.view`), with
  the stock's sum on each header (`summaries`). The chevrons collapse a
  group (`@onGroupToggle`). ([Group by](/docs/sheet/docs/sheet/data/record-groups#group-by))
- **Editing.** Type, paste, fill, clear, undo: each change set goes to
  `@onChange`, which applies it to the store (where a real app also
  sends it to its server) and keeps a line per changed cell. SKU and
  Product are required, Price and Stock have `min: 0`. ([Editing
  basics](/docs/sheet/docs/sheet/editing))
- **Import.** "Import CSV…" opens `<EuiSheetImport>` in a modal on a
  file of yours; "Import a supplier's file" on a sample whose columns
  have other names (the fields' `importAliases` match them) and whose
  third line has a price that can't be read. Import calls
  `api.appendRows`: one change set, one Ctrl/Cmd+Z. It loads every
  product first and turns grouping off, since imported lines go after
  the last record (and, grouped, would take its group). ([The import
  screen](/docs/sheet/docs/sheet/import-export/import-screen#the-import-screen))
- **CSV export.** "Export CSV" loads every product and downloads
  `toCsv` of them, the visible fields in their order. ([CSV
  export](/docs/sheet/docs/sheet/import-export#export-to-csv))
- **The expanded record.** Space on a cell, or the expand icon on a
  row's number, opens the product; its footer (`<:recordFooter>`) lists
  the edits made to it on this page. ([Expanded record](/docs/sheet/docs/sheet/rows/expanded-record#expanded-record))

The first field is frozen (`@frozenFields={{1}}`), so the SKU stays in
view when you scroll right. [Getting started](/docs/sheet/docs/sheet) has the basics; the
component's code is in the example's code tab.

## The data and the server

The fields, the generated products, the fake server and the sample
file, `app/utils/sheet-example-products.js` (the component imports it
as `site/utils/sheet-example-products`):

```js
// The sheet docs' example app (Sheet, Example app): the fields of a
// product list, a fake server that pages them, and a CSV file to import.

const CATEGORIES = [
  { value: 'tools', label: 'Tools', color: 'primary' },
  { value: 'safety', label: 'Safety', color: 'success' },
  { value: 'electrical', label: 'Electrical', color: 'warning' },
  { value: 'plumbing', label: 'Plumbing', color: 'accent' },
];

export const FIELDS = [
  {
    id: 'sku',
    label: 'SKU',
    required: true,
    importAliases: ['Code'],
    width: 110,
  },
  {
    id: 'name',
    label: 'Product',
    required: true,
    importAliases: ['Name'],
    width: 200,
  },
  {
    id: 'category',
    label: 'Category',
    type: 'singleSelect',
    options: CATEGORIES,
    width: 130,
  },
  {
    id: 'price',
    label: 'Price',
    type: 'currency',
    currency: 'MXN',
    min: 0,
    importAliases: ['Unit price'],
    width: 110,
  },
  {
    id: 'stock',
    label: 'Stock',
    type: 'number',
    min: 0,
    importAliases: ['Qty'],
    width: 90,
  },
  { id: 'active', label: 'Active', type: 'checkbox', width: 80 },
  {
    id: 'restock',
    label: 'Restock',
    type: 'date',
    importAliases: ['Next restock'],
    width: 120,
  },
];

const NAMES = {
  tools: ['Hammer', 'Wrench', 'Screwdriver set', 'Drill bit', 'Tape measure'],
  safety: ['Safety glasses', 'Work gloves', 'Hard hat', 'Ear plugs', 'Vest'],
  electrical: ['Cable 2.5 mm', 'Switch', 'Socket', 'Fuse 16 A', 'LED bulb'],
  plumbing: ['PVC pipe', 'Elbow 90°', 'Valve 1/2"', 'Teflon tape', 'Tap'],
};

// 230 products on the "server"
const PRODUCTS = Array.from({ length: 230 }, (_, i) => {
  const category = CATEGORIES[i % CATEGORIES.length].value;
  const names = NAMES[category];

  return {
    id: `p${i + 1}`,
    sku: `SKU-${String(1001 + i)}`,
    name: `${names[Math.floor(i / 4) % names.length]} ${Math.floor(i / 20) + 1}`,
    category,
    price: Math.round((20 + ((i * 37) % 900)) * 100) / 100,
    stock: (i * 13) % 120,
    active: i % 9 !== 0,
    restock: `2026-12-${String((i % 28) + 1).padStart(2, '0')}`,
  };
});

/** One page of products, after 400 ms, and how many there are. */
export function fetchProducts(offset, limit) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve({
        products: PRODUCTS.slice(offset, offset + limit).map((product) => ({
          ...product,
        })),
        total: PRODUCTS.length,
      });
    }, 400);
  });
}

/** A supplier's file: other column names, one price that can't be read. */
export const SAMPLE_CSV = [
  'Code,Name,Category,Unit price,Qty,Active,Next restock',
  'SKU-2001,Utility knife,Tools,89.90,40,yes,05/12/2026',
  'SKU-2002,Face shield,Safety,149.00,12,yes,08/12/2026',
  'SKU-2003,Extension cord 5 m,Electrical,twelve,30,yes,10/12/2026',
  'SKU-2004,Pipe wrench,Plumbing,320.50,6,no,12/12/2026',
].join('\r\n');
```

</EuiText>

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

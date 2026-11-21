// Sample data for the sheet docs' examples (Sheet pages): a few
// inspections, employees, suppliers and products, and a fake server's
// wait. Each function returns new records, so every example edits its
// own copy.

export const SITES = [
  { value: 'mty', label: 'Monterrey plant', color: 'primary' },
  { value: 'slp', label: 'San Luis warehouse', color: 'accent' },
  { value: 'qro', label: 'Querétaro line', color: 'success' },
];

export const STATUSES = [
  { value: 'open', label: 'Open' },
  { value: 'progress', label: 'In progress', color: 'primary' },
  { value: 'closed', label: 'Closed', color: 'success' },
];

export const INSPECTORS = [
  { id: 'u1', label: 'Ana Ruiz', email: 'ana@prysmex.com' },
  { id: 'u2', label: 'Bruno Vela', email: 'bruno@prysmex.com' },
  { id: 'u3', label: 'Carla Soto', email: 'carla@prysmex.com' },
  { id: 'u4', label: 'Diego Paz', email: 'diego@prysmex.com' },
];

/** Safety inspections: one record per walk-through of an area. */
export function inspections() {
  return [
    {
      id: 'ins-101',
      title: 'Forklift pre-shift check',
      site: 'mty',
      area: 'Dock 2',
      inspector: INSPECTORS[0],
      date: '2026-11-03',
      score: 0.92,
      findings: 1,
      status: 'closed',
      passed: true,
    },
    {
      id: 'ins-102',
      title: 'Fire extinguishers, hall B',
      site: 'mty',
      area: 'Hall B',
      inspector: INSPECTORS[1],
      date: '2026-11-05',
      score: 0.75,
      findings: 3,
      status: 'progress',
      passed: false,
    },
    {
      id: 'ins-103',
      title: 'Chemical storage',
      site: 'slp',
      area: 'Store 1',
      inspector: INSPECTORS[2],
      date: '2026-11-10',
      score: 0.98,
      findings: 0,
      status: 'closed',
      passed: true,
    },
    {
      id: 'ins-104',
      title: 'Lockout / tagout, press 4',
      site: 'qro',
      area: 'Press line',
      inspector: INSPECTORS[3],
      date: '2026-11-12',
      score: 0.6,
      findings: 5,
      status: 'open',
      passed: false,
    },
    {
      id: 'ins-105',
      title: 'Emergency exits',
      site: 'slp',
      area: 'Building A',
      inspector: INSPECTORS[0],
      date: '2026-11-17',
      score: 0.88,
      findings: 2,
      status: 'progress',
      passed: true,
    },
    {
      id: 'ins-106',
      title: 'Guard rails, mezzanine',
      site: 'qro',
      area: 'Mezzanine',
      inspector: null,
      date: null,
      score: null,
      findings: null,
      status: 'open',
      passed: false,
    },
  ];
}

/** People on a site: contact data, a role and their dates. */
export function employees() {
  return [
    {
      id: 'e1',
      name: 'Ana Ruiz',
      role: 'Safety lead',
      email: 'ana@prysmex.com',
      phone: '+52 81 1234 5678',
      start: '2024-02-01',
      end: null,
      rate: 410,
      certified: true,
    },
    {
      id: 'e2',
      name: 'Bruno Vela',
      role: 'Inspector',
      email: 'bruno@prysmex.com',
      phone: '81 2222 3333',
      start: '2025-06-16',
      end: null,
      rate: 320,
      certified: true,
    },
    {
      id: 'e3',
      name: 'Carla Soto',
      role: 'Inspector',
      email: 'carla@prysmex.com',
      phone: '(81) 4444-5555',
      start: '2026-01-12',
      end: '2026-12-31',
      rate: 300,
      certified: false,
    },
    {
      id: 'e4',
      name: 'Diego Paz',
      role: 'Operator',
      email: 'diego@prysmex.com',
      phone: '+52 444 123 4567',
      start: '2023-09-04',
      end: null,
      rate: 240,
      certified: false,
    },
    {
      id: 'e5',
      name: 'Elena Gil',
      role: 'Operator',
      email: 'elena@prysmex.com',
      phone: '442 555 0101',
      start: '2026-03-02',
      end: null,
      rate: 240,
      certified: true,
    },
  ];
}

/** Suppliers of safety equipment, with their links. */
export function suppliers() {
  return [
    {
      id: 's1',
      name: 'Seguridad Norte',
      website: 'seguridadnorte.mx',
      email: 'ventas@seguridadnorte.mx',
      phone: '+52 81 8000 1200',
    },
    {
      id: 's2',
      name: 'Protección Industrial',
      website: 'https://proteccion.example.com/catalogo',
      email: 'contacto@proteccion.example.com',
      phone: '(442) 210-3344',
    },
    {
      id: 's3',
      name: 'EPP del Bajío',
      website: 'eppbajio',
      email: 'compras(at)eppbajio.mx',
      phone: 'call the office',
    },
    {
      id: 's4',
      name: 'Señales y Más',
      website: 'https://senales.example.org',
      email: 'info@senales.example.org',
      phone: '81 1111 2222',
    },
  ];
}

/** Safety equipment in stock. */
export function products() {
  return [
    {
      id: 'p1',
      sku: '7501234567890',
      name: 'Hard hat',
      price: 189,
      stock: 40,
      discount: 0.1,
      time: 600,
    },
    {
      id: 'p2',
      sku: '7501234567906',
      name: 'Safety glasses',
      price: 95.5,
      stock: 120,
      discount: 0,
      time: 300,
    },
    {
      id: 'p3',
      sku: '7501234567913',
      name: 'Nitrile gloves (box)',
      price: 249,
      stock: 18,
      discount: 0.05,
      time: 900,
    },
    {
      id: 'p4',
      sku: '7501234567920',
      name: 'Reflective vest',
      price: 129.9,
      stock: 64,
      discount: 0.15,
      time: 450,
    },
    {
      id: 'p5',
      sku: '7501234567937',
      name: 'Ear plugs (pack)',
      price: 59,
      stock: 200,
      discount: 0.2,
      time: 240,
    },
  ];
}

/** Resolves after `ms`, as a server would; rejects when `signal` aborts. */
export function wait(ms, signal) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(resolve, ms);

    signal?.addEventListener('abort', () => {
      clearTimeout(timer);
      reject(new DOMException('Aborted', 'AbortError'));
    });
  });
}

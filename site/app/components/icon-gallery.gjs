import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { fn } from '@ember/helper';
import { on } from '@ember/modifier';

import {
  EuiFieldSearch,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormRow,
  EuiIcon,
  EuiSelect,
  EuiSpacer,
  EuiText,
  EuiTitle,
} from '@ember-eui/core/components';
import { copyToClipboard } from '@ember-eui/core/utils/copy-to-clipboard';
import { typeToPathMap } from '@ember-eui/core/utils/css-mappings/eui-icon';

const ELASTIC_LOGOS = new Set([
  'logoElastic',
  'logoElasticStack',
  'logoElasticsearch',
  'logoAppSearch',
  'logoBeats',
  'logoBusinessAnalytics',
  'logoCloud',
  'logoCloudEnterprise',
  'logoEnterpriseSearch',
  'logoKibana',
  'logoLogging',
  'logoLogstash',
  'logoMaps',
  'logoMetrics',
  'logoObservability',
  'logoSecurity',
  'logoSiteSearch',
  'logoUptime',
  'logoVulnerabilityManagement',
  'logoWorkplaceSearch',
]);

/**
 * `size` is the size the icons are designed for: glyphs for 16px (`m`),
 * logos, apps and machine learning icons for 32px (`xl`).
 */
const CATEGORIES = [
  {
    id: 'glyphs',
    title: 'Glyphs',
    size: 'm',
    description:
      'Small, single color icons for actions and status. Designed for the default size m (16px); they take the color of the surrounding text.',
  },
  {
    id: 'editor',
    title: 'Editor controls',
    size: 'm',
    description:
      'Formatting and alignment icons, typically used in toolbars and EuiButtonGroup.',
  },
  {
    id: 'tokens',
    title: 'Tokens',
    size: 'm',
    description:
      'Colored badges for data types and code symbols, e.g. field types in a list. Prefer EuiToken, which adds the shape and color variations.',
  },
  {
    id: 'elastic',
    title: 'Elastic logos',
    size: 'xl',
    description:
      'Multi-color Elastic product logos. Only use them for Elastic products; designed for 32px (size xl).',
  },
  {
    id: 'logos',
    title: 'Third-party logos',
    size: 'xl',
    description:
      'Logos of other products and services, designed for 32px (size xl). Some have a `Mono` single color variant.',
  },
  {
    id: 'apps',
    title: 'Apps',
    size: 'xl',
    description:
      'Kibana app icons, multi-color and designed for 32px (size xl). Pass a color to render them in a single color.',
  },
  {
    id: 'ml',
    title: 'Machine learning',
    size: 'xl',
    description: 'Machine learning job icons, designed for 32px (size xl).',
  },
];

function categoryOf(type) {
  if (type.endsWith('Job') || type === 'dataVisualizer') return 'ml';
  if (type.endsWith('App')) return 'apps';
  if (type.startsWith('editor')) return 'editor';
  if (type.startsWith('token')) return 'tokens';
  if (ELASTIC_LOGOS.has(type)) return 'elastic';
  if (type.startsWith('logo')) return 'logos';

  return 'glyphs';
}

const ICONS = Object.keys(typeToPathMap)
  .filter((type) => type !== 'empty')
  .sort((a, b) => a.localeCompare(b));

const CATEGORY_OPTIONS = [
  { value: 'all', text: `All categories (${ICONS.length})` },
  ...CATEGORIES.map((category) => ({
    value: category.id,
    text: `${category.title} (${ICONS.filter((type) => categoryOf(type) === category.id).length})`,
  })),
];

/**
 * Every named EUI icon, searchable and grouped by category. Clicking an icon
 * copies `<EuiIcon @type="..." />`.
 */
export default class IconGallery extends Component {
  @tracked query = '';
  @tracked category = 'all';
  @tracked copied;

  get sections() {
    const query = this.query.trim().toLowerCase();

    return CATEGORIES.filter(
      (category) => this.category === 'all' || this.category === category.id,
    )
      .map((category) => ({
        ...category,
        icons: ICONS.filter(
          (type) =>
            categoryOf(type) === category.id &&
            (!query || type.toLowerCase().includes(query)),
        ),
      }))
      .filter((section) => section.icons.length > 0);
  }

  @action
  search(event) {
    this.query = event.target.value;
  }

  @action
  selectCategory(event) {
    this.category = event.target.value;
  }

  @action
  copy(type) {
    if (copyToClipboard(`<EuiIcon @type="${type}" />`)) {
      this.copied = type;
    }
  }

  <template>
    <EuiFlexGroup @gutterSize="m" @wrap={{true}}>
      <EuiFlexItem>
        <EuiFormRow @label="Search icons">
          <EuiFieldSearch
            @value={{this.query}}
            @placeholder="e.g. arrow, logo, token"
            @isClearable={{false}}
            aria-label="Search icons"
            {{on "input" this.search}}
          />
        </EuiFormRow>
      </EuiFlexItem>
      <EuiFlexItem @grow={{false}}>
        <EuiFormRow @label="Category">
          <EuiSelect
            @options={{CATEGORY_OPTIONS}}
            @value={{this.category}}
            aria-label="Icon category"
            {{on "change" this.selectCategory}}
          />
        </EuiFormRow>
      </EuiFlexItem>
    </EuiFlexGroup>

    <EuiSpacer @size="s" />
    <EuiText @size="xs" @color="subdued" aria-live="polite">
      {{#if this.copied}}
        Copied
        <code>&lt;EuiIcon @type="{{this.copied}}" /&gt;</code>
      {{else}}
        Click an icon to copy its
        <code>&lt;EuiIcon /&gt;</code>
        tag.
      {{/if}}
    </EuiText>
    <EuiSpacer @size="m" />

    <div class="iconGallery">
      {{#each this.sections as |section|}}
        <section class="iconGallery__section">
          <EuiTitle @size="xs"><h3>{{section.title}}
              ({{section.icons.length}})</h3></EuiTitle>
          <EuiText @size="s" @color="subdued">
            <p>{{section.description}}</p>
          </EuiText>
          <EuiSpacer @size="s" />
          <ul class="iconGallery__grid">
            {{#each section.icons as |type|}}
              <li>
                <button
                  type="button"
                  class="iconGallery__icon"
                  title="Copy <EuiIcon @type=&quot;{{type}}&quot; />"
                  {{on "click" (fn this.copy type)}}
                >
                  <EuiIcon @type={{type}} @size={{section.size}} />
                  <span class="iconGallery__name">{{type}}</span>
                </button>
              </li>
            {{/each}}
          </ul>
        </section>
      {{else}}
        <EuiText @color="subdued">
          <p>No icon matches “{{this.query}}”.</p>
        </EuiText>
      {{/each}}
    </div>
  </template>
}

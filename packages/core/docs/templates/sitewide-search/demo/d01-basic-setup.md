---
order: 1
---

# Basic setup

<EuiText>

`EuiSelectableTemplateSitewide` is an opinionated wrapper around `EuiSelectable` to provide a reusable template across the Elastic products that will share the same global search capabilities. It creates the search input that triggers a popover containing the list of options.

**Search input.** The search ability of `EuiSelectable` is still hooked up to the options provided. It will highlight the portion of the label that matches the search string. Upstream's demo hooks up a keyboard shortcut (command + K) to focus the search input; the template does not come with this ability and this demo does not wire it.

**Popover.** The popover itself allows you to display a `<:popoverTitle>` block and a `<:popoverFooter>` block. (Upstream's `popoverProps` are not available, see the width arg `@popoverWidth`.)

**Selection.** The options themselves are simply rendered as list items with no interactive behavior like buttons or links. You must handle the interaction when the component passes back the altered array of options with the selected option having `checked: 'on'`.

**Popover toggle and responsiveness.** The default display is to render the search input inline which triggers a popover with the results. Or you can decide to trigger the whole selectable component from a single button. By passing your own button in the `<:popoverButton>` block, the component will use this to trigger the popover, putting the search inside. Upstream's `popoverButtonBreakpoints` helper (render the button only at some window sizes) is not available. See "Loading and a popover button" below.

This demo shows how you can temporarily replace the icon for a subset of options to display a short list of recently viewed options before the user types.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiSelectableTemplateSitewide, EuiText, EuiFlexGroup, EuiFlexItem, EuiLink, EuiBadge } from '@ember-eui/core/components';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

const SEARCH_DATA = [
  {
    label: 'Welcome dashboards',
    meta: [{ text: 'Dashboard', type: 'application', highlightSearchString: true }],
    url: 'welcome-dashboards',
  },
  {
    label:
      '[Flights] Flight Count and Average Ticket Price over the course of several years maybe even decades',
    meta: [{ text: 'Visualization', type: 'application' }],
  },
  {
    label: '[Flights] Global Flight Dashboard',
    meta: [{ text: 'Dashboard', type: 'application', highlightSearchString: true }],
  },
  {
    label: '[Logs] Host, Visits and Bytes Table',
    meta: [{ text: 'TSVB visualization', type: 'application' }],
  },
  {
    label: '[Flights] Flight Log',
    meta: [{ text: 'Discover', type: 'application' }],
  },
  {
    label: 'Dashboards',
    url: 'dashboards',
    icon: { type: 'logoKibana' },
  },
  {
    label: 'Generate HAR Archive of Network Timings/Details for Kibana requests',
    meta: [
      { text: 'Article', type: 'article' },
      {
        text: 'https://discuss.elastic.co/t/generate-har-archive-of-network-timings',
        highlightSearchString: true,
      },
    ],
  },
  {
    label: '[Logs] Web Traffic',
    url: 'dashboard-logs-web-traffic',
    meta: [{ text: 'Dashboard', type: 'application', highlightSearchString: true }],
  },
  {
    label: 'Databoard analytics',
    title: 'Databoard analytics; Dashboard; Deployment: Flights Data',
    meta: [
      { text: 'Dashboard', type: 'application' },
      { text: 'Flights Data', type: 'deployment' },
    ],
  },
  {
    label: 'Primary logs',
    meta: [{ text: 'Flights Data', type: 'deployment' }],
  },
  {
    label: 'SIEM',
    icon: { type: 'logoSecurity' },
    meta: [{ text: 'personal-databoard', type: 'deployment' }],
  },
  {
    label: 'Dev tools',
    url: 'dev-tools-console',
    meta: [{ text: 'Management application', type: 'application' }],
  },
  {
    label: 'Billing',
    icon: { type: 'user' },
    meta: [{ text: 'Account', type: 'platform' }],
  },
  {
    label: 'Maps',
    url: 'maps',
    icon: { type: 'logoKibana' },
    meta: [{ text: 'Analyze application', type: 'application' }],
    space: 'Hello World',
  },
  {
    label: 'Kibana monitoring with MB',
    searchableLabel: 'Kibana monitoring with MB; Case no. 00508173',
    meta: [
      { text: 'Case', type: 'case' },
      { text: '00508173' },
    ],
  },
  {
    label: 'My support tickets',
    icon: { type: 'help' },
    meta: [{ text: 'Support', type: 'platform' }],
  },
  {
    label: 'Totally custom',
    searchableLabel: 'Totally custom with pink metadata',
    icon: { type: 'warning', color: 'accent' },
    meta: [{ text: 'I have a custom type', type: 'PINK' }],
  },
];

// The first 5 options with a clock icon simulate recently viewed
const RECENTS = SEARCH_DATA.slice(0, 5).map((recent) => ({
  ...recent,
  icon: { type: 'clock', color: 'subdued' },
}));

export default class SitewideBasicSetupDemo extends Component {
  @tracked searchValue = '';

  get currentOptions() {
    return this.searchValue ? SEARCH_DATA : RECENTS;
  }

  @action
  onSearch(value) {
    this.searchValue = value;
  }

  @action
  onChange(updatedOptions) {
    // do something with the selection: the option with `checked: 'on'`
    const clickedItem = updatedOptions.find((option) => option.checked === 'on');
    if (!clickedItem) return;
  }

  <template>
    <EuiSelectableTemplateSitewide
      @options={{this.currentOptions}}
      @onSearch={{this.onSearch}}
      @onChange={{this.onChange}}
    >
      <:popoverFooter>
        <EuiText @color="subdued" @size="xs">
          <EuiFlexGroup @alignItems="center" @gutterSize="s" @responsive={{false}} @wrap={{true}}>
            <EuiFlexItem @grow={{false}}>
              {{#if this.searchValue}}
                <EuiLink>View more results</EuiLink>
              {{/if}}
            </EuiFlexItem>
            <EuiFlexItem />
            <EuiFlexItem @grow={{false}}>Quickly search using</EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiBadge>Command + K</EuiBadge>
            </EuiFlexItem>
          </EuiFlexGroup>
        </EuiText>
      </:popoverFooter>
    </EuiSelectableTemplateSitewide>
  </template>
}
```

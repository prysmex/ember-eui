---
order: 1
---

# Basic setup

<EuiText>

`EuiSelectableTemplateSitewide` is an opinionated wrapper around `EuiSelectable` to provide a reusable template across the Elastic products that will share the same global search capabilities. It creates the search input that triggers a popover containing the list of options.

### Search input

The search ability of `EuiSelectable` is still hooked up to the options provided. It will highlight the portion of the label that matches the search string. `@searchProps` takes the options of the search field (`append`, `onKeyUpCapture`, `inputRef`, `className`, ...).

The demo showcases the possibility to allow a keyboard shortcut (command + K) to trigger the search input focus, but the template does not come with this ability.

### Popover

The popover itself allows you to display a `<:popoverTitle>` block, a `<:popoverFooter>` block, or pass any of the `@popoverProps` to the `EuiPopover` component (`width` sets the content width).

### Selection

The options themselves are simply rendered as list items with no interactive behavior like buttons or links. You must handle the interaction when the component passes back the altered array of options with the selected option having `checked: 'on'`.

### Popover toggle and responsiveness

The default display is to render the search input inline which triggers a popover with the results. Or you can decide to trigger the whole selectable component from a single button. By passing your own button in the `<:popoverButton>` block, the component will use this to trigger the popover, putting the search inside.

This is a great way to handle reducing the size of the component for smaller screens. The component offers a helper arg called `@popoverButtonBreakpoints` which will only render the `<:popoverButton>` if the window size matches named breakpoint(s). Narrow this window to see the toggle button below.

This demo shows how you can temporarily replace the icon for a subset of options to display a short list of recently viewed options before the user types. The `PINK` meta type is a custom one: it only has the class `euiSelectableTemplateSitewide__optionMeta--PINK`, which `@listProps.css` styles.

</EuiText>

<EuiSpacer />

```gjs component
import { EuiSelectableTemplateSitewide, EuiText, EuiFlexGroup, EuiFlexItem, EuiLink, EuiBadge, EuiButton } from '@ember-eui/core/components';
import { array } from '@ember/helper';
import { on } from '@ember/modifier';
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

// Styles the custom `PINK` meta type through its class.
const listCss = ({ euiTheme }) => ({
  '.euiSelectableTemplateSitewide__optionMeta--PINK': {
    fontWeight: euiTheme.font.weight.medium,
    color: euiTheme.colors.textAccent,
  },
});

export default class SitewideBasicSetupDemo extends Component {
  @tracked searchValue = '';
  @tracked isLoading = false;
  searchRef = null;

  constructor() {
    super(...arguments);
    window.addEventListener('keydown', this.onWindowKeyDown);
  }

  willDestroy() {
    super.willDestroy();
    window.removeEventListener('keydown', this.onWindowKeyDown);
    window.removeEventListener('keyup', this.onWindowKeyUp);
  }

  get currentOptions() {
    return this.searchValue ? SEARCH_DATA : RECENTS;
  }

  // Hook up the keyboard shortcut for command + K to focus the search input
  onWindowKeyDown = (event) => {
    if (event.metaKey && event.key.toLowerCase() === 'k') {
      event.preventDefault();
      window.addEventListener('keyup', this.onWindowKeyUp);
    }
  };

  onWindowKeyUp = () => {
    window.removeEventListener('keyup', this.onWindowKeyUp);
    this.searchRef?.focus();
    // simulate a remotely-executed search
    this.isLoading = true;
    setTimeout(() => (this.isLoading = false), 400);
  };

  searchProps = {
    append: '⌘K',
    className: 'customSearchClass',
    inputRef: (input) => (this.searchRef = input),
    onKeyUpCapture: (event) => (this.searchValue = event.currentTarget.value),
  };

  listProps = { className: 'customListClass', css: listCss };

  popoverProps = { className: 'customPopoverClass' };

  @action
  onChange(updatedOptions) {
    // do something with the selection: the option with `checked: 'on'`
    const clickedItem = updatedOptions.find((option) => option.checked === 'on');
    if (!clickedItem) return;
  }

  <template>
    <EuiSelectableTemplateSitewide
      @isLoading={{this.isLoading}}
      @options={{this.currentOptions}}
      @onChange={{this.onChange}}
      @searchProps={{this.searchProps}}
      @listProps={{this.listProps}}
      @popoverProps={{this.popoverProps}}
      @popoverButtonBreakpoints={{array "xs" "s"}}
    >
      <:popoverButton as |toggle|>
        <EuiButton {{on "click" toggle}}>Mobile toggle</EuiButton>
      </:popoverButton>
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

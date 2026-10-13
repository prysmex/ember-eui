---
order: 3
---

# Page configurations

<EuiText>

When piecing all of the different page components together, the state of your application will dictate how best to configure each component. Ideally, your main content should always live within a `'plain'` colored body or section.

When using `EuiEmptyPrompt` to replace the main contents of your page you will want to use a panel color opposite that of the section color. For example:

</EuiText>

<EuiSpacer />

```gjs component
import { EuiTable, EuiTableHeader, EuiTableHeaderCell, EuiTableBody, EuiTableRow, EuiTableRowCell, EuiIcon, EuiCode } from '@ember-eui/core/components';
import { eq } from 'ember-truth-helpers';
import Component from '@glimmer/component';

export default class PageConfigurationsDemo extends Component {
  items = [
    {
      sidebar: true,
      header: 'none',
      body: 'color="plain"',
      section: 'color="plain" bottomBorder',
      emptyPrompt: 'color="subdued"',
    },
    {
      sidebar: false,
      header: true,
      body: 'color="transparent"',
      section: 'color="plain" bottomBorder="extended"',
      emptyPrompt: 'color="subdued"',
    },
    {
      sidebar: false,
      header: false,
      body: 'color="transparent"',
      section: 'color="plain" bottomBorder="extended"',
      emptyPrompt: 'color="plain"',
    },
  ];

  <template>
    <EuiTable>
      <EuiTableHeader>
        <EuiTableHeaderCell>EuiPageSidebar</EuiTableHeaderCell>
        <EuiTableHeaderCell>EuiPageHeader</EuiTableHeaderCell>
        <EuiTableHeaderCell>EuiPageBody</EuiTableHeaderCell>
        <EuiTableHeaderCell>EuiPageSection</EuiTableHeaderCell>
        <EuiTableHeaderCell>EuiEmptyPrompt settings</EuiTableHeaderCell>
      </EuiTableHeader>
      <EuiTableBody>
        {{#each this.items as |item|}}
          <EuiTableRow>
            <EuiTableRowCell>
              <EuiIcon
                @type={{if item.sidebar "checkCircleFill" "error"}}
                @color={{if item.sidebar "success" "danger"}}
                @title={{if item.sidebar "true" "false"}}
              />
            </EuiTableRowCell>
            <EuiTableRowCell>
              {{#if (eq item.header "none")}}
                <EuiIcon @type="minusCircle" @color="subdued" @title="none" />
              {{else if item.header}}
                <EuiIcon @type="checkCircleFill" @color="success" @title="true" />
              {{else}}
                <EuiIcon @type="error" @color="danger" @title="false" />
              {{/if}}
            </EuiTableRowCell>
            <EuiTableRowCell><EuiCode>{{item.body}}</EuiCode></EuiTableRowCell>
            <EuiTableRowCell><EuiCode>{{item.section}}</EuiCode></EuiTableRowCell>
            <EuiTableRowCell><EuiCode>{{item.emptyPrompt}}</EuiCode></EuiTableRowCell>
          </EuiTableRow>
        {{/each}}
      </EuiTableBody>
    </EuiTable>
  </template>
}
```

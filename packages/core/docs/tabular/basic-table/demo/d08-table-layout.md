---
order: 8
---

# Table layout

<EuiText>

`EuiBasicTable` uses a fixed layout by default. You can change it to `auto`
with the `@tableLayout` argument. Note that setting `@tableLayout` to
`auto` prevents the `truncateText` column option from working properly. If
you want to set different column widths while still using `truncateText`,
set the width of each column with its `width` option.

You can also set the vertical alignment (`valign`) at the column level,
which affects the cell contents for that entire column (excluding the
header and footer), and the horizontal alignment (`align`).

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiLink,
  EuiBasicTable,
  EuiButtonGroup,
  EuiCallOut,
  EuiFlexGroup,
  EuiSpacer,
} from '@ember-eui/core/components';

const USERS = [
  ['Ada', 'Lovelace', 'adalove', 'Senior Mathematical Programmer', '12 St James Square London LDN SW1Y 4JH'],
  ['Alan', 'Turing', 'enigma', 'Principal Cryptanalyst', '78 High Street Wilmslow CHS SK9 1AA'],
  ['Grace', 'Hopper', 'gracehopper', 'Rear Admiral of Compiler Engineering', '2611 Jefferson Davis Highway Arlington VA 22202'],
  ['Linus', 'Torvalds', 'torvalds', 'Kernel Maintainer', '1 Mannerheimintie Helsinki UUS 00100'],
  ['Margaret', 'Hamilton', 'mhamilton', 'Director of Software Engineering', '75 Cambridge Parkway Cambridge MA 02142'],
  ['Edsger', 'Dijkstra', 'ewd', 'Professor of Computing Science', '210 Coolsingel Rotterdam ZH 3011 AD'],
  ['Barbara', 'Liskov', 'bliskov', 'Institute Professor', '32 Vassar Street Cambridge MA 02139'],
  ['Bjarne', 'Stroustrup', 'bjarne', 'Language Designer', '14 Nordre Ringgade Aarhus MID 8000'],
  ['Niklaus', 'Wirth', 'nwirth', 'Compiler Construction Lead', '35 Stadthausstrasse Winterthur ZH 8400'],
  ['Yukihiro', 'Matsumoto', 'matz', 'Chief Ruby Architect', '3-1 Ofukacho Kita-ku Osaka OSK 530-0011'],
].map(([firstName, lastName, github, jobTitle, address], i) => ({
  id: i + 1,
  firstName,
  lastName,
  github,
  jobTitle,
  address,
}));

const GithubCell = <template><EuiLink @href="#" @target="_blank">{{@value}}</EuiLink></template>;

export default class BasicTableLayout extends Component {
  users = USERS;

  @tracked tableLayout = 'tableLayoutFixed';
  @tracked layoutValue = 'fixed';
  @tracked vAlign = 'columnVAlignMiddle';
  @tracked vAlignValue = 'middle';
  @tracked align = 'columnAlignLeft';
  @tracked alignValue = 'left';

  tableLayoutButtons = [
    { id: 'tableLayoutFixed', label: 'Fixed', value: 'fixed' },
    { id: 'tableLayoutAuto', label: 'Auto', value: 'auto' },
    { id: 'tableLayoutCustom', label: 'Custom', value: 'custom' },
  ];

  vAlignButtons = [
    { id: 'columnVAlignTop', label: 'Top', value: 'top' },
    { id: 'columnVAlignMiddle', label: 'Middle', value: 'middle' },
    { id: 'columnVAlignBottom', label: 'Bottom', value: 'bottom' },
  ];

  alignButtons = [
    { id: 'columnAlignLeft', label: 'Left', value: 'left' },
    { id: 'columnAlignCenter', label: 'Center', value: 'center' },
    { id: 'columnAlignRight', label: 'Right', value: 'right' },
  ];

  get isAuto() {
    return this.tableLayout === 'tableLayoutAuto';
  }

  get columns() {
    const custom = this.layoutValue === 'custom';
    const align = this.alignValue;
    const valign = this.vAlignValue;
    return [
      {
        field: 'firstName',
        name: 'First Name',
        truncateText: true,
        align,
        valign,
        mobileOptions: {
          render: (user) => `${user.firstName} ${user.lastName}`,
          header: false,
          truncateText: false,
          enlarge: true,
          width: '100%',
        },
      },
      {
        field: 'lastName',
        name: 'Last Name',
        truncateText: true,
        align,
        valign,
        mobileOptions: { show: false },
      },
      { field: 'github', name: 'Github', component: GithubCell, align, valign },
      {
        field: 'jobTitle',
        name: 'Job title',
        truncateText: true,
        align,
        valign,
        width: custom ? '100px' : undefined,
      },
      {
        field: 'address',
        name: 'Address',
        truncateText: { lines: 2 },
        align,
        valign,
        width: custom ? '20%' : undefined,
      },
    ];
  }

  get callOutText() {
    switch (this.tableLayout) {
      case 'tableLayoutAuto':
        return 'Job title will not wrap or truncate since tableLayout is set to auto. Address will truncate if necessary';
      case 'tableLayoutCustom':
        return 'Job title has a custom column width of 100px. Address has a custom column width of 20%';
      default:
        return 'Job title has truncateText set to true. Address is set to { lines: 2 }';
    }
  }

  @action
  onTableLayoutChange(id, value) {
    this.tableLayout = id;
    this.layoutValue = value;
  }

  @action
  onVAlignChange(id, value) {
    this.vAlign = id;
    this.vAlignValue = value;
  }

  @action
  onAlignChange(id, value) {
    this.align = id;
    this.alignValue = value;
  }

  <template>
    <EuiFlexGroup @alignItems="flexStart">
      <EuiButtonGroup
        @legend="Table layout options"
        @options={{this.tableLayoutButtons}}
        @idSelected={{this.tableLayout}}
        @onChange={{this.onTableLayoutChange}}
      />
      <EuiButtonGroup
        @legend="Vertical align options"
        @options={{this.vAlignButtons}}
        @idSelected={{this.vAlign}}
        @onChange={{this.onVAlignChange}}
      />
      <EuiButtonGroup
        @legend="Horizontal align options"
        @options={{this.alignButtons}}
        @idSelected={{this.align}}
        @onChange={{this.onAlignChange}}
      />
    </EuiFlexGroup>
    <EuiSpacer @size="m" />
    <EuiCallOut
      @size="s"
      @color={{if this.isAuto "warning" "primary"}}
      @title={{this.callOutText}}
    />
    <EuiSpacer @size="m" />
    <EuiBasicTable
      @tableCaption="Demo of EuiBasicTable's table layout options"
      @responsiveBreakpoint={{false}}
      @items={{this.users}}
      @columns={{this.columns}}
      @rowHeader="firstName"
      @tableLayout={{if this.isAuto "auto" "fixed"}}
    />
  </template>
}
```

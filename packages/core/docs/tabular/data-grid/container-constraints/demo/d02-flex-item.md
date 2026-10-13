---
order: 2
---

# Data grid in a flex item

<EuiText>

When placed within an [EuiFlexGroup](/docs/core/docs/layout/flex) and
**EuiFlexItem**, the data grid will have trouble shrinking to fit. To fix
this, you will need to manually add a style of `min-width: 0` to the
**EuiFlexItem**.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { get, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import {
  EuiDataGrid,
  EuiFlexGroup,
  EuiFlexItem,
  EuiLink,
  EuiPanel,
} from '@ember-eui/core/components';

const data = [
  ['Kertzmann, Lorenzo Jr.', 'lorenzo.kertzmann@example.com', 'Port Isom', 'Portugal', '43172691'],
  ['Hessel, Adela DVM', 'adela_hessel@example.org', 'Lake Kianfort', 'Kenya', '08812395'],
  ['Bauch, Celestino III', 'celestino.bauch@example.net', 'Fort Gilberto', 'Chile', '91254066'],
  ['Wiza, Marlene PhD', 'marlene.wiza@example.com', 'New Teagan', 'Norway', '37020518'],
  ['Okuneva, Dario Sr.', 'dario_okuneva@example.org', 'West Mabel', 'Japan', '64409837'],
  ['Gleichner, Ines MD', 'ines.gleichner@example.net', 'Schultzburgh', 'Canada', '20983314'],
  ['Pacocha, Rex II', 'rex_pacocha@example.com', 'East Lorine', 'Brazil', '75530127'],
  ['Lindgren, Nyah V', 'nyah.lindgren@example.org', 'Hilllfield', 'Sweden', '11846590'],
  ['Murazik, Toby DDS', 'toby.murazik@example.net', 'Lake Rosalind', 'Ireland', '58712043'],
  ['Feest, Bridie I', 'bridie_feest@example.com', 'North Ansel', 'Mexico', '30365812'],
  ['Hand, Elias IV', 'elias.hand@example.org', 'Rippinberg', 'Germany', '96021478'],
  ['Kozey, Mafalda Jr.', 'mafalda.kozey@example.net', 'Port Cleta', 'Italy', '42137760'],
  ['Rau, Jovan Sr.', 'jovan_rau@example.com', 'Wardton', 'India', '87304125'],
  ['Senger, Alysa PhD', 'alysa.senger@example.org', 'Lake Amelie', 'Australia', '13579046'],
  ['Upton, Grady III', 'grady.upton@example.net', 'South Elvis', 'Egypt', '64820931'],
  ['Becker, Ola DVM', 'ola_becker@example.com', 'Kuhlmanville', 'Peru', '29174608'],
  ['Zieme, Callie MD', 'callie.zieme@example.org', 'New Jerel', 'France', '50613287'],
  ['Walsh, Imani II', 'imani.walsh@example.net', 'Boyleton', 'Spain', '78246019'],
  ['Herzog, Brant V', 'brant_herzog@example.com', 'Fort Edd', 'Iceland', '36098541']
].map(([name, email, city, country, account]) => ({ name, email, city, country, account }));

export default class ContainerFlexDemo extends Component {
  data = data;

  columns = [{ id: 'name' }, { id: 'email' }, { id: 'city' }, { id: 'country' }, { id: 'account' }];

  gridStyle = { border: 'horizontal', header: 'underline' };

  @tracked visibleColumns = this.columns.map(({ id }) => id);

  @action setVisibleColumns(visibleColumns) {
    this.visibleColumns = visibleColumns;
  }

  @tracked pageIndex = 0;
  @tracked pageSize;

  @action setPageIndex(pageIndex) {
    this.pageIndex = pageIndex;
  }

  @action setPageSize(pageSize) {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  }

  <template>
    <EuiFlexGroup>
      <EuiFlexItem style="min-width: 120px;" @grow={{false}}>
        <EuiPanel @color="subdued">Sidebar</EuiPanel>
      </EuiFlexItem>
      <EuiFlexItem style="min-width: 0;">
        <EuiPanel style="height: 300px; overflow: hidden;" @hasBorder={{true}} @paddingSize="none">
          <EuiDataGrid
            aria-label="Container flex data grid demo"
            @columns={{this.columns}}
            @columnVisibility={{hash visibleColumns=this.visibleColumns setVisibleColumns=this.setVisibleColumns}}
            @rowCount={{this.data.length}}
            @gridStyle={{this.gridStyle}}
            @pagination={{hash
              pageIndex=this.pageIndex
              pageSize=this.pageSize
              onChangeItemsPerPage=this.setPageSize
              onChangePage=this.setPageIndex
            }}
          >
            <:cell as |cell|>
              {{#if (eq cell.columnId "city")}}
                <EuiLink @href="http://google.com">{{get (get this.data cell.rowIndex) "city"}}</EuiLink>
              {{else}}
                {{get (get this.data cell.rowIndex) cell.columnId}}
              {{/if}}
            </:cell>
          </EuiDataGrid>
        </EuiPanel>
      </EuiFlexItem>
    </EuiFlexGroup>
  </template>
}
```

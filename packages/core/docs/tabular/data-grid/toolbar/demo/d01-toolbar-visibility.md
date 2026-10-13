---
order: 1
---

# Toolbar visibility

<EuiText>

The `@toolbarVisibility` argument, when used as a boolean, controls the
visibility of the entire toolbar displayed above the grid. Using the
argument's object configuration allows setting the visibility of the
individual toolbar controls. Toggle the options below to see the
configuration and its effect on the grid.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { fn, get, hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import {
  EuiAvatar,
  EuiButtonGroup,
  EuiCodeBlock,
  EuiDataGrid,
  EuiFormRow,
  EuiRange,
  EuiSplitPanelInner,
  EuiSplitPanelOuter
} from '@ember-eui/core/components';

const data = [
  ['Hartmann', 'Ada', 'Jr.', '20375816'],
  ['Okafor', 'Bruno', 'III', '61049273'],
  ['Lindqvist', 'Carmen', 'Sr.', '87512046'],
  ['Moreau', 'Dmitri', 'IV', '39268105'],
  ['Novak', 'Elena', 'II', '50817394']
].map(([last, first, suffix, account]) => ({
  avatar: `${last}, ${first}`,
  name: `${last}, ${first} ${suffix}`,
  account
}));

const columns = [
  { id: 'avatar', initialWidth: 40 },
  { id: 'name' },
  { id: 'account', schema: 'numeric' }
];

const toolbarBooleanOptions = [
  { id: 'true', label: 'True' },
  { id: 'false', label: 'False' }
];
const toolbarBooleanOrObjectOptions = [
  { id: 'true', label: 'True' },
  { id: 'false', label: 'False' },
  { id: 'object', label: 'Object' }
];

// `showDisplaySelector.additionalDisplaySettings` is a component
const AdditionalDisplaySettings = <template>
  <EuiFormRow @label="Random Sample Size" @display="columnCompressed">
    <EuiRange
      @compressed={{true}}
      @fullWidth={{true}}
      @showInput={{true}}
      @min={{1}}
      @max={{100}}
      @step={{1}}
      @value={{10}}
      data-test-subj="randomSampleSize"
    />
  </EuiFormRow>
</template>;

// Prints a `toolbarVisibility` object as a `hash` helper call
const toHash = (value, indent = '  ') => {
  if (typeof value !== 'object') return `${value}`;
  const entries = Object.entries(value).map(([key, entry]) =>
    key === 'additionalDisplaySettings'
      ? `${indent}  ${key}=this.AdditionalDisplaySettings`
      : `${indent}  ${key}=${toHash(entry, `${indent}  `)}`
  );
  return `(hash\n${entries.join('\n')}\n${indent})`;
};

const ConfigurationRow = <template>
  <EuiFormRow @label={{@label}} @display="columnCompressed">
    <EuiButtonGroup
      @isFullWidth={{true}}
      @buttonSize="compressed"
      @legend={{@label}}
      @options={{@options}}
      @idSelected={{get @state @name}}
      @onChange={{fn @onChange @name}}
    />
  </EuiFormRow>
</template>;

export default class ToolbarVisibilityDemo extends Component {
  @tracked state = {
    toolbarType: 'true',
    showColumnSelector: 'true',
    allowOrderingColumns: 'true',
    allowHideColumns: 'true',
    showSortSelector: 'true',
    showDisplaySelector: 'true',
    allowDensity: 'true',
    allowRowHeight: 'true',
    allowResetButton: 'true',
    additionalDisplaySettings: 'false',
    showKeyboardShortcuts: 'true',
    showFullScreenSelector: 'true'
  };

  // Required data grid state
  @tracked visibleColumns = columns.map(({ id }) => id);
  @tracked sortingColumns = [];
  @tracked pageIndex = 0;
  @tracked pageSize = 10;

  setOption = (name, id) => (this.state = { ...this.state, [name]: id });
  setVisibleColumns = (visibleColumns) => (this.visibleColumns = visibleColumns);
  onSort = (sortingColumns) => (this.sortingColumns = sortingColumns);
  onChangePage = (pageIndex) => (this.pageIndex = pageIndex);
  onChangeItemsPerPage = (pageSize) => {
    this.pageSize = pageSize;
    this.pageIndex = 0;
  };

  get toolbarVisibility() {
    const s = this.state;
    if (s.toolbarType === 'true') return true;
    if (s.toolbarType === 'false') return false;
    return {
      showColumnSelector:
        s.showColumnSelector === 'object'
          ? {
              allowReorder: s.allowOrderingColumns === 'true',
              allowHide: s.allowHideColumns === 'true'
            }
          : s.showColumnSelector === 'true',
      showSortSelector: s.showSortSelector === 'true',
      showDisplaySelector:
        s.showDisplaySelector === 'object'
          ? {
              allowDensity: s.allowDensity === 'true',
              allowRowHeight: s.allowRowHeight === 'true',
              allowResetButton: s.allowResetButton === 'true',
              ...(s.additionalDisplaySettings === 'true'
                ? { additionalDisplaySettings: AdditionalDisplaySettings }
                : {})
            }
          : s.showDisplaySelector === 'true',
      showKeyboardShortcuts: s.showKeyboardShortcuts === 'true',
      showFullScreenSelector: s.showFullScreenSelector === 'true'
    };
  }

  get snippet() {
    const toolbarVisibility = this.toolbarVisibility;
    const value =
      typeof toolbarVisibility === 'object'
        ? toHash(toolbarVisibility, '  ').replace(/^\(/, '{{').replace(/\)$/, '}}')
        : `{{${toolbarVisibility}}}`;
    return `<EuiDataGrid\n  ...\n  @toolbarVisibility=${value}\n/>`;
  }

  <template>
    <EuiSplitPanelOuter @hasBorder={{true}}>
      <EuiSplitPanelInner @grow={{false}}>
        <div style="margin-block-end: 16px">
          <ConfigurationRow
            @label="Toolbar visibility"
            @name="toolbarType"
            @options={{toolbarBooleanOrObjectOptions}}
            @state={{this.state}}
            @onChange={{this.setOption}}
          />
          {{#if (eq this.state.toolbarType "object")}}
            <ConfigurationRow
              @label="Show column selector"
              @name="showColumnSelector"
              @options={{toolbarBooleanOrObjectOptions}}
              @state={{this.state}}
              @onChange={{this.setOption}}
            />
            {{#if (eq this.state.showColumnSelector "object")}}
              <div style="padding-inline-start: 24px">
                <ConfigurationRow
                  @label="Allow ordering"
                  @name="allowOrderingColumns"
                  @options={{toolbarBooleanOptions}}
                  @state={{this.state}}
                  @onChange={{this.setOption}}
                />
                <ConfigurationRow
                  @label="Allow hiding"
                  @name="allowHideColumns"
                  @options={{toolbarBooleanOptions}}
                  @state={{this.state}}
                  @onChange={{this.setOption}}
                />
              </div>
            {{/if}}
            <ConfigurationRow
              @label="Show sort selector"
              @name="showSortSelector"
              @options={{toolbarBooleanOptions}}
              @state={{this.state}}
              @onChange={{this.setOption}}
            />
            <ConfigurationRow
              @label="Show display selector"
              @name="showDisplaySelector"
              @options={{toolbarBooleanOrObjectOptions}}
              @state={{this.state}}
              @onChange={{this.setOption}}
            />
            {{#if (eq this.state.showDisplaySelector "object")}}
              <div style="padding-inline-start: 24px">
                <ConfigurationRow
                  @label="Show density"
                  @name="allowDensity"
                  @options={{toolbarBooleanOptions}}
                  @state={{this.state}}
                  @onChange={{this.setOption}}
                />
                <ConfigurationRow
                  @label="Show row height"
                  @name="allowRowHeight"
                  @options={{toolbarBooleanOptions}}
                  @state={{this.state}}
                  @onChange={{this.setOption}}
                />
                <ConfigurationRow
                  @label="Show reset button"
                  @name="allowResetButton"
                  @options={{toolbarBooleanOptions}}
                  @state={{this.state}}
                  @onChange={{this.setOption}}
                />
                <ConfigurationRow
                  @label="Additional display settings"
                  @name="additionalDisplaySettings"
                  @options={{toolbarBooleanOptions}}
                  @state={{this.state}}
                  @onChange={{this.setOption}}
                />
              </div>
            {{/if}}
            <ConfigurationRow
              @label="Show keyboard shortcuts"
              @name="showKeyboardShortcuts"
              @options={{toolbarBooleanOptions}}
              @state={{this.state}}
              @onChange={{this.setOption}}
            />
            <ConfigurationRow
              @label="Show fullscreen toggle"
              @name="showFullScreenSelector"
              @options={{toolbarBooleanOptions}}
              @state={{this.state}}
              @onChange={{this.setOption}}
            />
          {{/if}}
        </div>
        <EuiDataGrid
          aria-label="Data grid with custom toolbarVisibility set"
          @columns={{columns}}
          @columnVisibility={{hash
            visibleColumns=this.visibleColumns
            setVisibleColumns=this.setVisibleColumns
          }}
          @sorting={{hash columns=this.sortingColumns onSort=this.onSort}}
          @pagination={{hash
            pageIndex=this.pageIndex
            pageSize=this.pageSize
            onChangePage=this.onChangePage
            onChangeItemsPerPage=this.onChangeItemsPerPage
          }}
          @rowCount={{data.length}}
          @height="auto"
          @toolbarVisibility={{this.toolbarVisibility}}
        >
          <:cell as |cell|>
            {{#let (get data cell.rowIndex) as |row|}}
              {{#if (eq cell.columnId "avatar")}}
                <EuiAvatar @size="s" @name={{row.avatar}} />
              {{else}}
                {{get row cell.columnId}}
              {{/if}}
            {{/let}}
          </:cell>
        </EuiDataGrid>
      </EuiSplitPanelInner>
      <EuiSplitPanelInner @color="subdued" @paddingSize="none" @grow={{false}}>
        <EuiCodeBlock @language="html" @fontSize="m" @paddingSize="m" @isCopyable={{true}}>{{this.snippet}}</EuiCodeBlock>
      </EuiSplitPanelInner>
    </EuiSplitPanelOuter>
  </template>
}
```

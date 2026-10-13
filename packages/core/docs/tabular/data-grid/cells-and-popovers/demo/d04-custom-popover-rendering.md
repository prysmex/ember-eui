---
order: 4
---

# Completely customizing cell popover rendering

<EuiText>

If you want complete control over the rendering of the entire cell popover,
pass a component to `@renderCellPopover` (or use the `<:cellPopover>`
block). This allows you to do things like set your own wrappers and replace
the default cell actions rendering with your own.

To make falling back to atoms of the default cell popover easier, several
arguments are passed to your custom `@renderCellPopover` component:

- The default block (`{{yield}}`): the cell's value rendered by
  `@renderCellValue` (with `@isDetails`). It can be used (e.g.) if you want
  a custom wrapper or cell actions, but default popover content. The
  `<:cellPopover>` block has no such content: render the value yourself.
- `@cellContentsElement`: a direct reference to the cell's HTML content
  node, which allows accessing the cell's `innerText` for cases where raw
  text is useful (e.g. copying).
- `@cellActions`: the default popover footer and buttons, as a component.
  Use it if you want custom popover content but default cell actions.
  - If deliberately leaving out the default `@cellActions`, you **must**
    re-implement your cell actions in the popover in some form. Leaving out
    cell actions available in the cell but not in the popover introduces UX
    inconsistencies and will confuse the end user.
- `@DefaultCellPopover`: the default popover component. Use it if you only
  want custom popover content for certain schemas or columns and default
  popover rendering for other cells.
- `@setCellPopoverProps`: a function to customize the cell expansion
  popover. Accepts any `EuiPopover` option, except for the button and
  `closePopover`, which are controlled by the data grid.

Take a look at the below example's demo code to see the above arguments in
action.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { hash } from '@ember/helper';
import { eq } from 'ember-truth-helpers';
import {
  EuiButtonEmpty,
  EuiCopy,
  EuiDataGrid,
  EuiFlexGroup,
  EuiFlexItem,
  EuiImage,
  EuiPopoverFooter,
  EuiPopoverTitle,
  EuiText
} from '@ember-eui/core/components';

const FilterIn = <template>
  <@Component @iconType="plusCircle" aria-label="Filter in">Filter in</@Component>
</template>;
const FilterOut = <template>
  <@Component @iconType="minusCircle" aria-label="Filter out">Filter out</@Component>
</template>;

const cellActions = [FilterIn, FilterOut];

const columns = [
  { id: 'default', cellActions },
  { id: 'datetime', cellActions },
  { id: 'json', cellActions },
  { id: 'custom', schema: 'favoriteFranchise', cellActions }
];

const data = [
  ['Hartmann, Ada Jr.', 'Tue Mar 12 2024 10:41:07 GMT+0000', '20375816', '412.08', 'Wed Aug 07 2024 16:02:55 GMT+0000'],
  ['Okafor, Bruno III', 'Sat Nov 30 2024 07:15:42 GMT+0000', '61049273', '87.50', 'Mon Jan 22 2024 21:30:19 GMT+0000'],
  ['Lindqvist, Carmen Sr.', 'Thu Jun 20 2024 23:58:01 GMT+0000', '87512046', '953.71', 'Fri Oct 04 2024 05:47:33 GMT+0000'],
  ['Moreau, Dmitri IV', 'Sun Feb 04 2024 13:26:50 GMT+0000', '39268105', '230.44', 'Tue Dec 17 2024 09:11:28 GMT+0000']
].map(([name, datetime, numeric, currency, date], i) => ({
  default: name,
  datetime,
  json: JSON.stringify([{ numeric, currency, date }]),
  custom: (i + 1) % 2 === 0 ? 'Star Wars' : 'Star Trek'
}));

const valueFor = (rowIndex, columnId) => data[rowIndex][columnId];

const CellValue = <template>{{valueFor @rowIndex @columnId}}</template>;

class CellPopover extends Component {
  constructor(owner, args) {
    super(owner, args);
    // Set custom cell expansion popover props
    args.setCellPopoverProps({ panelClassName: 'customCellPopover' });
  }

  get cellText() {
    return this.args.cellContentsElement?.innerText ?? '';
  }

  get title() {
    if (this.args.schema === 'favoriteFranchise') return 'Custom popover with custom content';
    if (this.args.columnId === 'datetime') return 'Custom popover with custom actions';
    return 'Custom popover';
  }

  <template>
    {{#if (eq @columnId "json")}}
      {{! An example of conditionally falling back to the default cell popover.
          JSON schemas have automatic EuiCodeBlock and copy formatting, which
          can be nice to keep intact. For cells that have non-JSON content but
          JSON popovers, you can also pass a json schema to force it. }}
      <@DefaultCellPopover @schema="json" />
    {{else}}
      <EuiPopoverTitle>{{this.title}}</EuiPopoverTitle>
      {{#if (eq @schema "favoriteFranchise")}}
        {{! An example of custom popover content }}
        {{#if (eq this.cellText "Star Wars")}}
          <EuiImage
            @allowFullScreen={{true}}
            @size="m"
            @hasShadow={{true}}
            @caption="{{this.cellText}} is the best!"
            @alt="Random Star Wars image"
            @url="https://picsum.photos/id/35/600"
          />
        {{else}}
          <EuiImage
            @allowFullScreen={{true}}
            @size="m"
            @hasShadow={{true}}
            @caption="{{this.cellText}} is the best!"
            @alt="Random Star Trek image"
            @url="https://picsum.photos/id/120/600"
          />
        {{/if}}
      {{else}}
        {{! The default block is the cell value rendered with @isDetails }}
        <EuiText @size="s">{{yield}}</EuiText>
      {{/if}}
      {{#if (eq @columnId "datetime")}}
        {{! An example of a custom cell actions footer, and of using
            @cellContentsElement to directly access a cell's raw text }}
        <EuiPopoverFooter>
          <EuiFlexGroup @justifyContent="spaceBetween" @gutterSize="none" @responsive={{false}}>
            <EuiFlexItem class="eui-displayBlock">
              {{! When not using the default cellActions, be sure to replace them
                  with your own action buttons to ensure a consistent user experience }}
              <EuiButtonEmpty @size="xs">Filter in</EuiButtonEmpty>
              <EuiButtonEmpty @size="xs">Filter out</EuiButtonEmpty>
            </EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiCopy @textToCopy={{this.cellText}} as |copy|>
                <EuiButtonEmpty @size="xs" @color="success" {{on "click" copy}}>
                  Click to copy
                </EuiButtonEmpty>
              </EuiCopy>
            </EuiFlexItem>
          </EuiFlexGroup>
        </EuiPopoverFooter>
      {{else}}
        <@cellActions />
      {{/if}}
    {{/if}}
  </template>
}

export default class CustomPopoverRenderingDemo extends Component {
  @tracked visibleColumns = columns.map(({ id }) => id);

  setVisibleColumns = (visibleColumns) => (this.visibleColumns = visibleColumns);

  <template>
    <EuiDataGrid
      aria-label="Data grid renderCellPopover example"
      @columns={{columns}}
      @columnVisibility={{hash
        visibleColumns=this.visibleColumns
        setVisibleColumns=this.setVisibleColumns
      }}
      @rowCount={{data.length}}
      @renderCellValue={{CellValue}}
      @renderCellPopover={{CellPopover}}
    />
  </template>
}
```

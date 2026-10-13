---
order: 8
---

# Portalled items

<EuiText>
  <p>
    Upstream, <strong>EuiDraggables</strong> use fixed positioning to render and animate the item being dragged, which does not work as expected inside containers that have their own stacking context, so its <EuiCode>usePortal</EuiCode> prop renders the dragged element in a portal. Ember EUI drags items with the browser's native drag and drop (through Pragmatic drag and drop), so there is nothing to position: dragging works inside an <strong>EuiFlyout</strong>, <strong>EuiModal</strong> or <strong>EuiPopover</strong> as is, and there is no <EuiCode>@usePortal</EuiCode> arg.
  </p>
</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { EuiButton, EuiDragDropContext, EuiFlyout, EuiFlyoutBody, EuiFlyoutHeader, EuiModal, EuiModalBody, EuiModalHeader, EuiPanel, EuiPopover, EuiSpacer, EuiTitle } from '@ember-eui/core/components';
import { euiDragDropReorder } from '@ember-eui/core/utils/drag-drop';
import { on } from '@ember/modifier';
import { action } from '@ember/object';

let nextId = 0;
const makeId = () => `item-${++nextId}`;
const makeList = (number, start = 1) =>
  Array.from({ length: number }, (v, k) => k + start).map((el) => ({
    content: `Item ${el}`,
    id: makeId()
  }));

export default class PortalledDemo extends Component {
  @tracked isFlyoutOpen = false;
  @tracked isModalOpen = false;
  @tracked isPopoverOpen = false;
  @tracked list = makeList(3);

  popoverStyle = { inlineSize: '200px' };

  @action
  toggleFlyout() {
    this.isFlyoutOpen = !this.isFlyoutOpen;
  }

  @action
  closeFlyout() {
    this.isFlyoutOpen = false;
  }

  @action
  toggleModal() {
    this.isModalOpen = !this.isModalOpen;
  }

  @action
  closeModal() {
    this.isModalOpen = false;
  }

  @action
  togglePopover() {
    this.isPopoverOpen = !this.isPopoverOpen;
  }

  @action
  closePopover() {
    this.isPopoverOpen = false;
  }

  @action
  onDragEnd({ source, destination }) {
    if (source && destination) {
      this.list = euiDragDropReorder(this.list, source.index, destination.index);
    }
  }

  <template>
    <EuiButton {{on 'click' this.toggleFlyout}}>
      Toggle flyout
    </EuiButton>
    <EuiSpacer />
    <EuiButton {{on 'click' this.toggleModal}}>
      Toggle modal
    </EuiButton>

    {{#if this.isFlyoutOpen}}
      <EuiFlyout @onClose={{this.closeFlyout}}>
        <EuiFlyoutHeader>
          <EuiTitle @size='s'>
            <h2>
              Portalled <strong>EuiDraggable</strong> items
            </h2>
          </EuiTitle>
        </EuiFlyoutHeader>
        <EuiFlyoutBody>
          <EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
            <dnd.Droppable @droppableId='DROPPABLE_AREA_FLYOUT' @spacing='m' as |list|>
              {{#each this.list key='id' as |item index|}}
                <list.Draggable @spacing='m' @index={{index}} @draggableId={{item.id}} as |state|>
                  <EuiPanel @hasShadow={{state.isDragging}}>
                    {{item.content}}
                    {{#if state.isDragging}} ✨{{/if}}
                  </EuiPanel>
                </list.Draggable>
              {{/each}}
            </dnd.Droppable>
          </EuiDragDropContext>
        </EuiFlyoutBody>
      </EuiFlyout>
    {{/if}}

    {{#if this.isModalOpen}}
      <EuiModal @onClose={{this.closeModal}}>
        <EuiModalHeader>
          <EuiTitle @size='s'>
            <h2>
              Portalled <strong>EuiDraggable</strong> items
            </h2>
          </EuiTitle>
        </EuiModalHeader>
        <EuiModalBody>
          <EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
            <dnd.Droppable @droppableId='DROPPABLE_AREA_MODAL' @spacing='m' as |list|>
              {{#each this.list key='id' as |item index|}}
                <list.Draggable @spacing='m' @index={{index}} @draggableId={{item.id}} as |state|>
                  <EuiPanel @hasShadow={{state.isDragging}}>
                    {{item.content}}
                    {{#if state.isDragging}} ✨{{/if}}
                  </EuiPanel>
                </list.Draggable>
              {{/each}}
            </dnd.Droppable>
          </EuiDragDropContext>
        </EuiModalBody>
      </EuiModal>
    {{/if}}

    <EuiSpacer />

    <EuiPopover
      @isOpen={{this.isPopoverOpen}}
      @closePopover={{this.closePopover}}
      @panelPaddingSize='none'
      @panelStyle={{this.popoverStyle}}
    >
      <:button>
        <EuiButton {{on 'click' this.togglePopover}}>
          Toggle popover
        </EuiButton>
      </:button>
      <:content>
        <EuiDragDropContext @onDragEnd={{this.onDragEnd}} as |dnd|>
          <dnd.Droppable @droppableId='DROPPABLE_AREA_POPOVER' @spacing='m' as |list|>
            {{#each this.list key='id' as |item index|}}
              <list.Draggable @spacing='m' @index={{index}} @draggableId={{item.id}} as |state|>
                <EuiPanel @hasShadow={{state.isDragging}}>
                  {{item.content}}
                  {{#if state.isDragging}} ✨{{/if}}
                </EuiPanel>
              </list.Draggable>
            {{/each}}
          </dnd.Droppable>
        </EuiDragDropContext>
      </:content>
    </EuiPopover>
  </template>
}
```

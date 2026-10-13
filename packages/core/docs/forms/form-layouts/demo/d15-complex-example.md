---
order: 15
---

# Complex example

<EuiText>

This is an example of how to combine compressed form controls with form rows, labels, prepends and appends in a column layout.

**Accessibility recommendation.** Pay close attention to the patterns of using `for` and `aria-label`. For best results, each form control that is not wrapped in an `EuiFormRow` should be supplied an `id`.

</EuiText>

```gjs component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import {
  EuiButtonGroup,
  EuiColorPicker,
  EuiColorPickerSwatch,
  EuiDualRange,
  EuiFieldNumber,
  EuiFieldText,
  EuiFlexGroup,
  EuiFlexItem,
  EuiFormAppend,
  EuiFormLabel,
  EuiFormPrepend,
  EuiFormRow,
  EuiHorizontalRule,
  EuiIcon,
  EuiPanel,
  EuiRange,
  EuiScreenReaderOnly,
  EuiSelect,
  EuiSpacer,
  EuiSuperSelect,
  EuiToolTip,
} from '@ember-eui/core/components';

const selectTooltipContent =
  'Otherwise use an EuiToolTip around the label of the form row.';

export default class ComplexFormDemo extends Component {
  selectTooltipContent = selectTooltipContent;

  selectOptions = [
    { value: 'option_one', text: 'Option one' },
    { value: 'option_two', text: 'Option two' },
    { value: 'option_three', text: 'Option three' },
  ];

  fontOptions = [
    { value: 'inter', text: 'Inter UI' },
    { value: 'roboto', text: 'Roboto' },
    { value: 'comic', text: 'Comic sans' },
  ];

  borderStyleOptions = [
    { value: 'dashed', text: 'Dashed' },
    { value: 'dotted', text: 'Dotted' },
    { value: 'solid', text: 'Solid' },
  ];

  superSelectOptions = [
    { value: 'option_one', inputDisplay: 'Option one' },
    { value: 'option_two', inputDisplay: 'Option two' },
    { value: 'option_three', inputDisplay: 'Option three' },
  ];

  typeStyleToggleButtons = [
    { id: 'typeStyleToggleButton-first', label: 'Bold', name: 'bold', iconType: 'textBold' },
    { id: 'typeStyleToggleButton-second', label: 'Italic', name: 'italic', iconType: 'textItalic' },
    { id: 'typeStyleToggleButton-third', label: 'Underline', name: 'underline', iconType: 'textUnderline' },
    { id: 'typeStyleToggleButton-fourth', label: 'Strikethrough', name: 'strikethrough', iconType: 'textStrike' },
  ];

  granularityToggleButtons = [
    { id: 'granularityToggleButton-first', label: 'fine' },
    { id: 'granularityToggleButton-second', label: 'rough' },
    { id: 'granularityToggleButton-third', label: 'coarse' },
  ];

  @tracked opacityValue = '20';
  @tracked color = '#D36086';
  @tracked popoverSliderValues = 16;
  @tracked dualValue = [5, 10];
  @tracked typeStyleIdToSelectedMap = {};
  @tracked granularityIdSelected = 'granularityToggleButton-second';
  @tracked superSelectValue = 'option_one';

  @action
  onPopoverSliderValueChange(event) {
    this.popoverSliderValues = event.target.value;
  }

  @action
  onColorChange(value) {
    this.color = value;
  }

  @action
  onRangeChange(event) {
    this.opacityValue = event.target.value;
  }

  @action
  onDualChange(value) {
    this.dualValue = value;
  }

  @action
  onTypeStyleChange(optionId) {
    this.typeStyleIdToSelectedMap = {
      ...this.typeStyleIdToSelectedMap,
      [optionId]: !this.typeStyleIdToSelectedMap[optionId],
    };
  }

  @action
  onGranularityChange(optionId) {
    this.granularityIdSelected = optionId;
  }

  @action
  onSuperSelectChange(value) {
    this.superSelectValue = value;
  }

  <template>
    <EuiPanel style="max-width: 432px">
      <EuiFormRow @label="Name" @display="columnCompressed">
        <EuiFieldText placeholder="Input" @compressed={{true}}>
          <:prepend><EuiFormPrepend @label="Label" /></:prepend>
        </EuiFieldText>
      </EuiFormRow>

      <EuiFormRow @label="Visibility" @display="columnCompressed">
        <EuiDualRange
          aria-label="EuiDualRange within compressed form"
          @value={{this.dualValue}}
          @onChange={{this.onDualChange}}
          @min={{0}}
          @max={{26}}
          @compressed={{true}}
          @showInput="inputWithPopover"
          @showLabels={{true}}
        >
          <:prepend as |classes|>
            <EuiFormLabel class={{classes}}>Zoom levels</EuiFormLabel>
          </:prepend>
        </EuiDualRange>
      </EuiFormRow>

      <EuiFormRow @label="Opacity" @display="columnCompressed">
        <EuiRange
          name="range"
          @min={{0}}
          @max={{100}}
          @showInput={{true}}
          @compressed={{true}}
          @value={{this.opacityValue}}
          @onChange={{this.onRangeChange}}
        >
          <:append as |classes|>
            <EuiFormLabel class={{classes}}>%</EuiFormLabel>
          </:append>
        </EuiRange>
      </EuiFormRow>

      <EuiSpacer @size="s" />

      <EuiScreenReaderOnly>
        <span id="docsExampleSelectTooltipContent">{{this.selectTooltipContent}}</span>
      </EuiScreenReaderOnly>
      <EuiFormRow @display="columnCompressed">
        <:label>
          <EuiToolTip @content={{this.selectTooltipContent}}>
            <span>Label <EuiIcon @type="question" @color="subdued" /></span>
          </EuiToolTip>
        </:label>
        <:field>
          <EuiSelect
            @options={{this.selectOptions}}
            @compressed={{true}}
            aria-describedby="docsExampleSelectTooltipContent"
          />
        </:field>
      </EuiFormRow>

      <EuiFormRow @label="Granularity" @display="columnCompressed">
        <EuiButtonGroup
          @legend="Granularity of zoom levels"
          @options={{this.granularityToggleButtons}}
          @idSelected={{this.granularityIdSelected}}
          @onChange={{this.onGranularityChange}}
          @buttonSize="compressed"
          @isFullWidth={{true}}
        />
      </EuiFormRow>

      <EuiFormRow @label="Fill" @display="columnCompressed">
        <EuiColorPicker
          @onChange={{this.onColorChange}}
          @color={{this.color}}
          @compressed={{true}}
        />
      </EuiFormRow>

      <EuiFormRow @label="Select one" @display="columnCompressed">
        <EuiSuperSelect
          @options={{this.superSelectOptions}}
          @valueOfSelected={{this.superSelectValue}}
          @onChange={{this.onSuperSelectChange}}
          @compressed={{true}}
        />
      </EuiFormRow>

      <EuiFormRow @label="With button" @display="columnCompressed">
        <EuiFieldNumber @min={{1}} @max={{100}} @value={{10}} @compressed={{true}}>
          <:prepend>
            <EuiFormPrepend
              @element="button"
              @iconLeft="pin"
              @label="kibana_sample_ecommerce_data"
              aria-label="Dynamic toggle"
            />
          </:prepend>
          <:append><EuiFormAppend @label="px" /></:append>
        </EuiFieldNumber>
      </EuiFormRow>

      <EuiHorizontalRule />

      <EuiFormRow @label="Container" @display="columnCompressed">
        <EuiFlexGroup @gutterSize="s" @responsive={{false}} @wrap={{true}}>
          <EuiFlexItem @grow={{false}}>
            <EuiColorPicker @onChange={{this.onColorChange}} @color={{this.color}}>
              <:button as |toggle|>
                <EuiColorPickerSwatch
                  @color={{this.color}}
                  aria-label="Container color"
                  title="Container color"
                  style="width: 32px; height: 32px"
                  {{on "click" toggle}}
                />
              </:button>
            </EuiColorPicker>
          </EuiFlexItem>
          <EuiFlexItem>
            <EuiRange
              aria-label="Container padding in pixels"
              @showInput="inputWithPopover"
              @min={{0}}
              @max={{240}}
              @value={{this.popoverSliderValues}}
              @onChange={{this.onPopoverSliderValueChange}}
              @compressed={{true}}
            >
              <:prepend as |classes|>
                <EuiFormLabel class={{classes}}>Padding</EuiFormLabel>
              </:prepend>
              <:append as |classes|>
                <EuiFormLabel class={{classes}}>px</EuiFormLabel>
              </:append>
            </EuiRange>
          </EuiFlexItem>
        </EuiFlexGroup>
      </EuiFormRow>

      <EuiSpacer @size="s" />

      <EuiFormRow @label="Label" @display="columnCompressed">
        <div>
          <EuiSelect
            aria-label="Label font family"
            @options={{this.fontOptions}}
            @compressed={{true}}
          >
            <:prepend><EuiFormPrepend @label="Font" /></:prepend>
          </EuiSelect>
          <EuiSpacer @size="xs" />
          <EuiFlexGroup
            @gutterSize="s"
            @responsive={{false}}
            @wrap={{true}}
            @justifyContent="flexEnd"
          >
            <EuiFlexItem>
              <EuiRange
                aria-label="Label font size in pixels"
                @showInput="inputWithPopover"
                @min={{7}}
                @max={{140}}
                @value={{this.popoverSliderValues}}
                @onChange={{this.onPopoverSliderValueChange}}
                @compressed={{true}}
              >
                <:append as |classes|>
                  <EuiFormLabel class={{classes}}>px</EuiFormLabel>
                </:append>
              </EuiRange>
            </EuiFlexItem>
            <EuiFlexItem @grow={{false}}>
              <EuiButtonGroup
                class="eui-displayInlineBlock"
                @legend="Label text style"
                @options={{this.typeStyleToggleButtons}}
                @idToSelectedMap={{this.typeStyleIdToSelectedMap}}
                @onChange={{this.onTypeStyleChange}}
                @type="multi"
                @isIconOnly={{true}}
                @buttonSize="compressed"
              />
            </EuiFlexItem>
          </EuiFlexGroup>
        </div>
      </EuiFormRow>

      <EuiSpacer @size="s" />

      <EuiFormLabel for="docsExampleBorderSizeRange">Border</EuiFormLabel>
      <EuiSpacer @size="xs" />
      <EuiFlexGroup @gutterSize="s" @responsive={{false}} @wrap={{true}}>
        <EuiFlexItem style="flex-basis: 72px">
          <EuiRange
            id="docsExampleBorderSizeRange"
            @showInput="inputWithPopover"
            @min={{0}}
            @max={{32}}
            @value={{this.popoverSliderValues}}
            @onChange={{this.onPopoverSliderValueChange}}
            @compressed={{true}}
          >
            <:append as |classes|>
              <EuiFormLabel class={{classes}}>px</EuiFormLabel>
            </:append>
          </EuiRange>
        </EuiFlexItem>
        <EuiFlexItem @grow={{4}} style="min-width: 160px">
          <EuiSelect
            aria-label="Border style"
            @options={{this.borderStyleOptions}}
            @compressed={{true}}
          >
            <:prepend><EuiFormPrepend @label="Style" /></:prepend>
          </EuiSelect>
        </EuiFlexItem>
        <EuiFlexItem @grow={{false}}>
          <EuiColorPicker @onChange={{this.onColorChange}} @color={{this.color}}>
            <:button as |toggle|>
              <EuiColorPickerSwatch
                @color={{this.color}}
                aria-label="Border color"
                title="Border color"
                style="width: 32px; height: 32px"
                {{on "click" toggle}}
              />
            </:button>
          </EuiColorPicker>
        </EuiFlexItem>
      </EuiFlexGroup>
    </EuiPanel>
  </template>
}
```

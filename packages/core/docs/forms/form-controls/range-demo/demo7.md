---
order: 7
---

# Range kitchen sink

```hbs template
<EuiText>
  <p>
    Showcase of the different settings ranges can have
  </p>
</EuiText>
<EuiTitle>
  Simple range
</EuiTitle>
<EuiRange
  @min={{100}}
  @max={{200}}
  @value={{20}}
  @showLabels={{true}}
  @showValue={{true}}
/>
<EuiSpacer @size='xl' />
<EuiTitle>
  Simple range with input
</EuiTitle>
<EuiRange
  @min={{100}}
  @max={{200}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  @showValue={{true}}
  @showInput={{true}}
/>
<EuiSpacer @size='xl' />
<EuiTitle>
  Simple range with popover
</EuiTitle>
<EuiRange
  @min={{100}}
  @max={{200}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  @showValue={{true}}
  @showInput='inputWithPopover'
/>
<EuiSpacer @size='xl' />
<EuiTitle>
  Simple range with append and popover
</EuiTitle>
<EuiRange
  @min={{100}}
  @max={{200}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  @showValue={{true}}
  @showInput='inputWithPopover'
>
  <:append as |classes|>
    <EuiFormLabel class={{classes}}>Append</EuiFormLabel>
  </:append>
</EuiRange>
<EuiSpacer @size='xl' />
<EuiTitle>
  Dual range with append and popover
</EuiTitle>
<EuiDualRange
  @min={{100}}
  @max={{200}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  @showValue={{true}}
  @showInput='inputWithPopover'
>
  <:append as |classes|>
    <EuiFormLabel class={{classes}}>Append</EuiFormLabel>
  </:append>
</EuiDualRange>
<EuiSpacer @size='xl' />
<EuiTitle>
  Dual range with append
</EuiTitle>
<EuiCallOut
  @iconType='alert'
  @title='Content blocks and `showInput`'
  @color='warning'
>
  <:body>
    The
    <b>prepend</b>
    and
    <b>append</b>
    blocks are not shown in dual ranges unless the `showInput` value is
    `inputWithPopover`
  </:body>
</EuiCallOut>
<EuiDualRange
  @min={{100}}
  @max={{200}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  @showValue={{true}}
  @showInput={{true}}
>
  <:append as |classes|>
    <EuiFormLabel class={{classes}}>Append</EuiFormLabel>
  </:append>
</EuiDualRange>
<EuiSpacer @size='xl' />
<EuiTitle>
  Dual range
</EuiTitle>
<EuiDualRange
  @min={{100}}
  @max={{200}}
  @value={{this.value}}
  @onChange={{this.onChange}}
  @showLabels={{true}}
  @showValue={{true}}
/>
<EuiSpacer @size='xl' />
<EuiTitle>
  Ranges within forms
</EuiTitle>
<EuiChangesetForm
  @changeset={{changeset this.changeset}}
  as |Form changesetObj|
>
  <EuiFlexGroup @direction='column' @gutterSize='none'>
    <Form.FieldRangeSlider
      @fieldName='rangeSlider1'
      @label='Range slider'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
    />
    <EuiSpacer />
    <Form.FieldRangeSlider
      @fieldName='rangeSlider1'
      @label='Range slider with input'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @showInput={{true}}
    />
    <EuiSpacer />
    <Form.FieldRangeSlider
      @fieldName='rangeSlider1'
      @label='Range slider with append'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @showInput={{true}}
    >
      <:append as |classes|>
        <EuiFormLabel class={{classes}}>Append</EuiFormLabel>
      </:append>
    </Form.FieldRangeSlider>
    <EuiSpacer />
    <Form.FieldRangeSlider
      @fieldName='rangeSlider1'
      @label='Range slider with popover'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @showInput='inputWithPopover'
    >
      <:append as |classes|>
        <EuiFormLabel class={{classes}}>Append</EuiFormLabel>
      </:append>
    </Form.FieldRangeSlider>
    <EuiSpacer />
    <Form.FieldDualRangeSlider
      @fieldName='rangeSlider1'
      @label='Dual slider with popover'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @showInput='inputWithPopover'
    >
      <:append as |classes|>
        <EuiFormLabel class={{classes}}>Append</EuiFormLabel>
      </:append>
    </Form.FieldDualRangeSlider>
    <EuiSpacer />
    <Form.FieldDualRangeSlider
      @fieldName='rangeSlider1'
      @label='Dual slider with inputs'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @showInput={{true}}
    />
    <EuiSpacer />
    <Form.FieldDualRangeSlider
      @fieldName='rangeSlider1'
      @label='Plain dual slider'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
    />
    <EuiButton @type='submit' @isDisabled={{changesetObj.isInvalid}}>
      Submit form
    </EuiButton>
  </EuiFlexGroup>
</EuiChangesetForm>
<EuiSpacer @size='xl' />
<EuiTitle>
  Validated form
</EuiTitle>
<ValidatedForm as |Form|>
  <EuiFlexGroup @direction='column' @gutterSize='none'>
    <Form.FieldRangeSlider
      @fieldName='rangeSlider1'
      @label='Range slider'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @validations={{hash
        number=(hash gte=0 lte=100 allowString=true)
        presence=(hash presence=true)
      }}
    />
    <EuiSpacer />
    <Form.FieldRangeSlider
      @fieldName='rangeSlider1'
      @label='Range slider with input'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @showInput={{true}}
      @validations={{hash
        number=(hash gte=0 lte=100 allowString=true)
        presence=(hash presence=true)
      }}
    />
    <EuiSpacer />
    <Form.FieldRangeSlider
      @fieldName='rangeSlider1'
      @label='Range slider with append'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @showInput={{true}}
      @validations={{hash
        number=(hash gte=0 lte=100 allowString=true)
        presence=(hash presence=true)
      }}
    >
      <:append as |classes|>
        <EuiFormLabel class={{classes}}>Append</EuiFormLabel>
      </:append>
    </Form.FieldRangeSlider>
    <EuiSpacer />
    <Form.FieldRangeSlider
      @fieldName='rangeSlider1'
      @label='Range slider with popover'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @showInput='inputWithPopover'
      @validations={{hash
        number=(hash gte=0 lte=100 allowString=true)
        presence=(hash presence=true)
      }}
    >
      <:append as |classes|>
        <EuiFormLabel class={{classes}}>Append</EuiFormLabel>
      </:append>
    </Form.FieldRangeSlider>
    <EuiSpacer />
    <Form.FieldDualRangeSlider
      @fieldName='rangeSlider1'
      @label='Dual slider with popover'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @showInput='inputWithPopover'
      @validations={{hash
        number=(hash gte=0 lte=100 allowString=true)
        presence=(hash presence=true)
      }}
    >
      <:append as |classes|>
        <EuiFormLabel class={{classes}}>Append</EuiFormLabel>
      </:append>
    </Form.FieldDualRangeSlider>
    <EuiSpacer />
    <Form.FieldDualRangeSlider
      @fieldName='rangeSlider1'
      @label='Dual slider with inputs'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @showInput={{true}}
      @validations={{hash
        number=(hash gte=0 lte=100 allowString=true)
        presence=(hash presence=true)
      }}
    />
    <EuiSpacer />
    <Form.FieldDualRangeSlider
      @fieldName='rangeSlider1'
      @label='Plain dual slider'
      @showLabels={{true}}
      @showValue={{true}}
      @min={{0}}
      @max={{300}}
      @validations={{hash
        number=(hash gte=0 lte=100 allowString=true)
        presence=(hash presence=true)
      }}
    />
    <EuiButton @type='submit'>
      Submit form
    </EuiButton>
  </EuiFlexGroup>
</ValidatedForm>
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';

export default class DemoCardComponent extends Component {
  @tracked value = 0;
  changeset = {};
  @action
  onChange(e) {
    this.value = e.target.value;
  }
}
```

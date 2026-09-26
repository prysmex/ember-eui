# Flatpickr

<EuiText>
  <p><EuiLink @target="_blank" @href="https://flatpickr.js.org">flatpickr</EuiLink> for <strong>@ember-eui/core</strong>. Pass <EuiCode>@date</EuiCode> and <EuiCode>@onChange</EuiCode>; any other argument is passed to flatpickr as an <EuiLink @target="_blank" @href="https://flatpickr.js.org/options/">option</EuiLink>.</p>

<p><EuiCodeBlock @isCopyable={{true}}>pnpm add @ember-eui/flatpickr flatpickr</EuiCodeBlock></p>

<p>Import flatpickr's stylesheet once in your app, e.g. <EuiCode>import 'flatpickr/dist/flatpickr.css';</EuiCode></p>

</EuiText>

```hbs template
<EuiFormRow @label='Choose a date'>
  <EuiFlatpickr
    @date={{this.date}}
    {{! Required Option }}
    @onChange={{this.setDate}}
    @mode='range'
    placeholder='Choose a Date'
    @allowInput={{false}}
    @altFormat='Y-m-d'
    @altInput={{true}}
    {{! Make sure to add these classes if you want to use altInput=true }}
    @altInputClass='euiFieldText--withIcon euiFieldText--inGroup euiFieldText'
    @clickOpens={{true}}
    @dateFormat='M/D/Y'
    @defaultDate={{this.date}}
    @defaultHour={{12}}
    @defaultMinute={{0}}
    @clear={{set this 'date'}}
    @disable={{this.datesToDisable}}
    @disableMobile={{false}}
    @enable={{this.datesToEnable}}
    @enableSeconds={{false}}
    @enableTime={{true}}
    @hourIncrement={{1}}
    @inline={{false}}
    @locale='ru'
    @maxDate={{this.maxDate}}
    @minDate={{this.minDate}}
    @minuteIncrement={{5}}
    @mode='single'
    @nextArrow='>'
    @noCalendar={{false}}
    {{! Required Option }}
    @onClose={{this.onClose}}
    @onOpen={{this.onOpen}}
    @onReady={{this.onReady}}
    {{! Can be used to easily store a reference to the flatpickr input. }}
    @parseDate={{false}}
    @prevArrow='<'
    @shorthandCurrentMonth={{false}}
    @static={{false}}
    @time_24hr={{false}}
    @weekNumbers={{false}}
  />
</EuiFormRow>
{{this.date}}
```

```js component
import Component from '@glimmer/component';
import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class Hoool extends Component {
  @tracked date = new Date();

  @action
  setDate(date) {
    this.date = date;
  }
}
```

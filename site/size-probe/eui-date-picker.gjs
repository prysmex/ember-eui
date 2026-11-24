// The date picker alone: its calendar and utils/date, no moment.
import EuiDatePicker from '@ember-eui/core/components/eui-date-picker';

console.log(
  <template>
    <EuiDatePicker @value={{@value}} @onChange={{@onChange}} />
  </template>,
);

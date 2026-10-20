// What every app boots with: the root provider and the emotion service.
import EuiEmotionProvider from '@ember-eui/core/components/eui-emotion-provider';
import EuiEmotionService from '@ember-eui/core/services/eui-emotion';

console.log(
  EuiEmotionService,
  <template>
    <EuiEmotionProvider>{{yield}}</EuiEmotionProvider>
  </template>,
);

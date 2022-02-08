# Demo

```hbs template
<EuiIcon @type='logoGolang' />
<EuiIcon @type='logoGolang' @size='m' />
<EuiIcon @type='logoGolang' @size='l' />
<EuiIcon @type='logoGolang' @size='xl' />
<EuiIcon @type='logoGolang' @size='xxl' />
<br />
<EuiIcon @type='logoRedis' @size='s' />
<EuiIcon @type='logoRedis' @size='m' />
<EuiIcon @type='logoRedis' @size='l' />
<EuiIcon @type='logoRedis' @size='xl' />
<EuiIcon @type='logoRedis' @size='xxl' />
<br />
<EuiIcon @type='logoAWS' @size='s' />
<EuiIcon @type='logoAWS' @size='m' />
<EuiIcon @type='logoAWS' @size='l' />
<EuiIcon @type='logoAWS' @size='xl' />
<EuiIcon @type='logoAWS' @size='xxl' />
<br />
<EuiIcon @type='/assets/ember.svg' @size='s' />
<EuiIcon @type='/assets/ember.svg' @size='m' />
<EuiIcon @type='/assets/ember.svg' @size='l' />
<EuiIcon @type='/assets/ember.svg' @size='xl' />
<EuiIcon @type='/assets/ember.svg' @size='xxl' />
<br />
<EuiIcon
  @type='https://www.flaticon.es/svg/static/icons/svg/3445/3445045.svg'
  @size='s'
/>
<EuiIcon
  @type='https://www.flaticon.es/svg/static/icons/svg/3445/3445045.svg'
  @size='m'
/>
<EuiIcon
  @type='https://www.flaticon.es/svg/static/icons/svg/3445/3445045.svg'
  @size='l'
/>
<EuiIcon
  @type='https://www.flaticon.es/svg/static/icons/svg/3445/3445045.svg'
  @size='xl'
/>
<EuiIcon
  @type='https://www.flaticon.es/svg/static/icons/svg/3445/3445045.svg'
  @size='xxl'
/>
<br />
<EuiIcon @type='flag' @size='s' @color='green' />
<EuiIcon @type='flag' @size='m' @color='white' />
<EuiIcon @type='flag' @size='l' @color='red' />
<EuiIcon @type='flag' @size='xl' @color='green' />
<EuiIcon @type='flag' @size='xxl' @color='white' />
```

```js component
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { typeToPathMap } from '@ember-eui/core/utils/css-mappings/eui-icon';

const iconKeys = Object.keys(typeToPathMap);

export default class DemoIconComponent extends Component {
  @tracked icon = 'tokenNumber';
  icons = iconKeys;

  @action
  update() {
    this.icon = this.icons[Math.floor(Math.random() * this.icons.length)];
  }
}
```

import { helper } from '@ember/component/helper';
import Component from '@glimmer/component';
interface EuiKeyPadMenuItemComponentArgs {}

const charAt = helper(function ([str, num]: [string, number]) {
  return str?.charAt?.(num);
});

export default class EuiKeyPadMenuItemComponent extends Component<EuiKeyPadMenuItemComponentArgs> {
  charAt = charAt;
}

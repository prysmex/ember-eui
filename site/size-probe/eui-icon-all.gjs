// EuiIcon with every icon bundled up front (registerAllIcons).
import EuiIcon from '@ember-eui/core/components/eui-icon';
import { registerAllIcons } from '@ember-eui/core/utils/register-all-icons';

registerAllIcons();

console.log(<template><EuiIcon @type="search" /></template>);

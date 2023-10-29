import type EuiButton from './components/eui-button';
import type EuiButtonEmpty from './components/eui-button-empty';

export default interface EmberEuiRegistry {
  EuiButton: typeof EuiButton;
  EuiButtonEmpty: typeof EuiButtonEmpty;
}

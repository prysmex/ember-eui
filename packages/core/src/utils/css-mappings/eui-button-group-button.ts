export const baseClass = 'euiButtonGroupButton';
import { colors } from './eui-button';

const sizeMapping = {
  s: `${baseClass}--small`,
  m: ''
};

const colorMapping = {
  primary: `${baseClass}${colors.primary}`,
  accent: `${baseClass}${colors.accent}`,
  success: `${baseClass}${colors.success}`,
  warning: `${baseClass}${colors.warning}`,
  danger: `${baseClass}${colors.danger}`,
  ghost: `${baseClass}${colors.ghost}`,
  text: `${baseClass}${colors.text}`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping,
    size: sizeMapping
  }
};

export default mapping;

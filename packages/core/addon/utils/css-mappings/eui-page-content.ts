export const baseClass = 'euiPageContent';

export const verticalMapping = {
  center: `${baseClass}--verticalCenter`
};

export const horizontalMapping = {
  center: `${baseClass}--horizontalCenter`
};

const borderRadiusMapping = {
  none: `${baseClass}--borderRadiusNone`,
  m: `${baseClass}--borderRadiusMedium`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    verticalPosition: verticalMapping,
    horizontalPosition: horizontalMapping,
    borderRadius: borderRadiusMapping,
  }
};

export default mapping;

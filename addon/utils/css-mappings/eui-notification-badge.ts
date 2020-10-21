export const baseClass: string = 'euiNotificationBadge';

export const colorMapping = {
  subdued: `${baseClass}--subdued`
};

export const sizeMapping = {
  m: `${baseClass}--medium`
}

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: colorMapping,
    size: sizeMapping
  }
};

export default mapping;

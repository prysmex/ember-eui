export const baseClass: string = 'euiPageContent';

export const verticalMapping = {
  center: `${baseClass}--verticalCenter`
};

export const horizontalMapping = {
  center: `${baseClass}--horizontalCenter`
};


const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    verticalPosition: verticalMapping,
    horizontalPosition: horizontalMapping
  }
};

export default mapping;

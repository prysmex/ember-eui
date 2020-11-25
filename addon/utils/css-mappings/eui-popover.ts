const baseClass: string = 'euiPopover';

const displayMapping = {
  inlineBlock: '',
  block: `${baseClass}--displayBlock`,
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    display: displayMapping
  }
};

export default mapping;

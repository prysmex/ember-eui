export const baseClass = 'euiSelectableListItem';

export const isFocusedMapping = {
  true: `${baseClass}--isFocused`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    isFocused: isFocusedMapping
  }
};

export default mapping;

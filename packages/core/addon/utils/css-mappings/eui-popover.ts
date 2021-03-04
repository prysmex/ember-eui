export const baseClass: string = 'euiPopover';

export const anchorPositionMapping = {
  upCenter: 'euiPopover--anchorUpCenter',
  upLeft: 'euiPopover--anchorUpLeft',
  upRight: 'euiPopover--anchorUpRight',
  downCenter: 'euiPopover--anchorDownCenter',
  downLeft: 'euiPopover--anchorDownLeft',
  downRight: 'euiPopover--anchorDownRight',
  leftCenter: 'euiPopover--anchorLeftCenter',
  leftUp: 'euiPopover--anchorLeftUp',
  leftDown: 'euiPopover--anchorLeftDown',
  rightCenter: 'euiPopover--anchorRightCenter',
  rightUp: 'euiPopover--anchorRightUp',
  rightDown: 'euiPopover--anchorRightDown',
};

export const displayMapping = {
  inlineBlock: '',
  block: 'euiPopover--displayBlock',
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    position: anchorPositionMapping,
    display: displayMapping,
  },
};

export default mapping;

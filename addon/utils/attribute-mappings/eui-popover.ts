// Somehow the start/end positions have to be flipped
// for Popper to show properly
const anchorPositionMapping: Attribute = {
  upCenter: 'top',
  upLeft: 'top-end',
  upRight: 'top-start',
  downCenter: 'bottom',
  downLeft: 'bottom-end',
  downRight: 'bottom-start',
  leftCenter: 'left',
  leftUp: 'left-end',
  leftDown: 'left-start',
  rightCenter: 'right',
  rightUp: 'right-end',
  rightDown: 'right-start'
};

const mapping: AttributeMap = {
  anchorPosition: anchorPositionMapping
}

export default mapping;

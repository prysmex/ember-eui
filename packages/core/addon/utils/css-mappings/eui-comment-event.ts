export const baseClass = 'euiCommentEvent';

const commentEventTypeMapping = {
  regular: `${baseClass}--regular`,
  update: `${baseClass}--update`
};

const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    type: commentEventTypeMapping
  }
};

export default mapping;

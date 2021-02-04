const baseClass: string = 'euiProgress';

const sizeToClassMapping = {
  xs: `${baseClass}--xs`,
  s: `${baseClass}--s`,
  m: `${baseClass}--m`,
  l: `${baseClass}--l`,
};

const colorToClassMap = {
  primary: `${baseClass}--primary`,
  secondary: `${baseClass}--secondary`,
  success: `${baseClass}--success`,
  warning: `${baseClass}--warning`,
  danger: `${baseClass}--danger`,
  subdued: `${baseClass}--subdued`,
  accent: `${baseClass}--accent`,
  vis0: `${baseClass}--vis0`,
  vis1: `${baseClass}--vis1`,
  vis2: `${baseClass}--vis2`,
  vis3: `${baseClass}--vis3`,
  vis4: `${baseClass}--vis4`,
  vis5: `${baseClass}--vis5`,
  vis6: `${baseClass}--vis6`,
  vis7: `${baseClass}--vis7`,
  vis8: `${baseClass}--vis8`,
  vis9: `${baseClass}--vis9`,
};

const dataColorToClassMap = {
  primary: `${baseClass}__data--primary`,
  secondary: `${baseClass}__data--secondary`,
  success: `${baseClass}__data--success`,
  warning: `${baseClass}__data--warning`,
  danger: `${baseClass}__data--danger`,
  subdued: `${baseClass}__data--subdued`,
  accent: `${baseClass}__data--accent`,
  vis0: `${baseClass}__data--vis0`,
  vis1: `${baseClass}__data--vis1`,
  vis2: `${baseClass}__data--vis2`,
  vis3: `${baseClass}__data--vis3`,
  vis4: `${baseClass}__data--vis4`,
  vis5: `${baseClass}__data--vis5`,
  vis6: `${baseClass}__data--vis6`,
  vis7: `${baseClass}__data--vis7`,
  vis8: `${baseClass}__data--vis8`,
  vis9: `${baseClass}__data--vis9`,
};

const positionsToClassMap = {
  fixed: `${baseClass}--fixed`,
  absolute: `${baseClass}--absolute`,
  static: '',
};

export const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    size: sizeToClassMapping,
    position: positionsToClassMap,
    color: colorToClassMap,
    secondaryColor: dataColorToClassMap,
  },
};

export default mapping;

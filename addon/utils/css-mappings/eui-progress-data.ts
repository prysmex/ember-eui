const baseClass: string = 'euiProgress__data';

const dataColorToClassMap = {
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

export const mapping: ComponentMapping = {
  base: baseClass,
  properties: {
    color: dataColorToClassMap,
  }
}

export default mapping;
interface PropertyMapping {
  [size: string]: string | null;
}

interface ComponentProperty {
  [property: string]: PropertyMapping;
}

interface ComponentMapping {
  base: string;
  properties: ComponentProperty;
  inlineStyles?(styles: Record<string, unknown>): Record<string, unknown>;
}

interface Styling {
  [i: string]: string | null;
}

interface Mapping {
  [componentName: string]: ComponentMapping;
}

type rgbDef = [number, number, number];

interface HSV {
  h: number;
  s: number;
  v: number;
}
interface RGB {
  r: number;
  g: number;
  b: number;
}

interface Tab {
  id: string | number;
  name: string;
  content: string;
}

type HEX = string;

interface Select {
  selected: any;
  actions: {
    search: (str: string) => void;
    choose: (opt: any, select: Select) => void;
  };
}

declare module 'ember-changeset-validations/*' {
  type Options = {};
  type Validator = (options: Options) => unknown;
  const validatePresence: Validator;
  const validateLength: Validator;
  const validateConfirmation: Validator;
  const validateFormat: Validator;
  const validateNumber: Validator;
  export {
    validateConfirmation,
    validateFormat,
    validateLength,
    validateNumber,
    validatePresence
  };
}

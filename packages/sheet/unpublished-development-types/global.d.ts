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

// import type OptionalHelper from './ember-composable-helpers/helpers/optional';


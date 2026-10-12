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


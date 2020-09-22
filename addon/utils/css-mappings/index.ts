import EuiLoadingSpinner from './eui-loading-spinner';

interface PropertyMapping {
  [size: string]: string
};

interface ComponentProperty {
  [property: string]: PropertyMapping;
}

interface ComponentMapping {
  base: string;
  properties: ComponentProperty;
};

interface Mapping {
  [componentName: string]: ComponentMapping;
};

const mapping: Mapping = {
  EuiLoadingSpinner
}

export default mapping;

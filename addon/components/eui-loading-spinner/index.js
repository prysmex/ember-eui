import Component from '@glimmer/component';

const sizeToClassNameMap = {
  s: 'euiLoadingSpinner--small',
  m: 'euiLoadingSpinner--medium',
  l: 'euiLoadingSpinner--large',
  xl: 'euiLoadingSpinner--xLarge'
};

export default class EuiLoadingSpinnerIndexComponent extends Component {
  get size () {
    return this.args.size ?? 'm';
  }

  get sizeClass () {
    return sizeToClassNameMap[this.size];
  }

  get classes () {
    return [
      'euiLoadingSpinner',
      this.sizeClass,
      this.args.className
    ].join(' ');
  }
}

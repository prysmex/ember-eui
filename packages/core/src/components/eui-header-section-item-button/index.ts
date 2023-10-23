import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';

const keyframes: Keyframe[] = [
  { transform: 'rotate(0)', offset: 0, easing: 'ease-in-out' },
  {
    transform: 'rotate(30deg)',
    offset: 0.01,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-28deg)',
    offset: 0.03,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(34deg)',
    offset: 0.05,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-32deg)',
    offset: 0.07,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(30deg)',
    offset: 0.09,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-28deg)',
    offset: 0.11,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(26deg)',
    offset: 0.13,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-24deg)',
    offset: 0.15,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(22deg)',
    offset: 0.17,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-20deg)',
    offset: 0.19,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(18deg)',
    offset: 0.21,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-16deg)',
    offset: 0.23,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(14deg)',
    offset: 0.25,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-12deg)',
    offset: 0.27,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(10deg)',
    offset: 0.29,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-8deg)',
    offset: 0.31,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(6deg)',
    offset: 0.33,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-4deg)',
    offset: 0.35,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(2deg)',
    offset: 0.37,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(-1deg)',
    offset: 0.39,
    easing: 'ease-in-out'
  },
  {
    transform: 'rotate(1deg)',
    offset: 0.41,
    easing: 'ease-in-out'
  },
  { transform: 'rotate(0)', offset: 0.43, easing: 'ease-in-out' },
  { transform: 'rotate(0)', offset: 1, easing: 'ease-in-out' }
];

interface EuiHeaderSectionItemButtonComponentArgs {
  ref?: (api: { euiAnimate: () => void }) => void;
}

export default class EuiHeaderSectionItemButtonComponent extends Component<EuiHeaderSectionItemButtonComponentArgs> {
  @tracked buttonRef: HTMLButtonElement | undefined;
  @tracked animationTargetRef: HTMLSpanElement | undefined;

  setAnimationTargetRef = (ele: HTMLSpanElement) => {
    this.animationTargetRef = ele;
    this.args.ref?.({ euiAnimate: this.animate });
  };

  animate = () => {
    this.animationTargetRef?.animate(keyframes, { duration: 5000 });
  };
}

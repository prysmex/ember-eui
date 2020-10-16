import GlimmerComponent from '@glimmer/component';
import { toInitials } from '../../utils';
import { isColorDark, hexToRgb, isValidHex } from '../../utils/color';
import { euiPaletteColorBlindBehindText } from '../../utils';
import { sizeMapping, typeMapping } from 'ember-eui/utils/css-mappings/eui-avatar';
// import { keysOf } from '../common';
import { argOrDefaultDecorator as argOrDefault } from 'ember-eui/helpers/arg-or-default';
import  { htmlSafe } from '@ember/string';

export type EuiAvatarSize = keyof typeof sizeMapping;
export type EuiAvatarType = keyof typeof typeMapping;

export type EuiAvatarProps = {
  /**
   * Full name of avatar for title attribute and calculating initial if not provided
   */
  name: string;

  /**
   * Accepts hex value `#FFFFFF`, `#000` otherwise a viz palette color will be assigned
   */
  color?: string;

  /**
   * Custom initials (max 2 characters).
   * By default will take the first character (of each word).
   */
  initials?: string;

  /**
   * Specify how many characters to show (max 2 allowed).
   * By default, will show based on number of words.
   */
  initialsLength?: 1 | 2;

  /**
   * The type of avatar this is displaying
   */
  type?: EuiAvatarType;
  imageUrl?: string;
  size?: EuiAvatarSize;
};

export default class EuiAvatarComponent extends GlimmerComponent<EuiAvatarProps> {

  @argOrDefault('user') type!: EuiAvatarType;
  @argOrDefault('m') size!: EuiAvatarSize;

  visColors = euiPaletteColorBlindBehindText();

  get optionalInitial () {
    if (this.args.name && !this.args.imageUrl) {
      const calculatedInitials = toInitials(this.args.name, this.args.initialsLength, this.args.initials);
      return htmlSafe(`<span aria-hidden="true">${calculatedInitials}</span>`);
    } else {
      return;
    }
  }

  _assignedColor = this.args.color || this.visColors[Math.floor(this.args.name.length % this.visColors.length)];

  _textColor = isColorDark(...hexToRgb(this._assignedColor)) ? '#FFFFFF' : '#000000';

  _backgroundImage = this.args.imageUrl ? `url(${this.args.imageUrl})` : 'none';

  get avatarStyles () {
    return htmlSafe(
      `
        background-image: ${this._backgroundImage};
        background-color: ${this._assignedColor};
        color: ${this._textColor}
      `
    );
  }

}
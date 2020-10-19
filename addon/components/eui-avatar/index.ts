import GlimmerComponent from '@glimmer/component';
import { isColorDark, hexToRgb, isValidHex } from '../../utils/color';
import { euiPaletteColorBlindBehindText } from '../../utils';
import  { htmlSafe } from '@ember/string';

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
  imageUrl?: string;
};

export default class EuiAvatarComponent extends GlimmerComponent<EuiAvatarProps> {

  visColors = euiPaletteColorBlindBehindText();

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
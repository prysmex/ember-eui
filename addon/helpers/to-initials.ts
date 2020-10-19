import { helper } from '@ember/component/helper';

export const MAX_INITIALS = 2;


export function toInitials([name, initialsLength, initials]: [string, 1 | 2, string]): string | null {
  // Calculate the number of initials to show, maxing out at MAX_INITIALS
  let calculatedInitialsLength: number = initials
    ? initials.split(' ').length
    : name.split(' ').length;

  calculatedInitialsLength =
    calculatedInitialsLength > MAX_INITIALS
      ? MAX_INITIALS
      : calculatedInitialsLength;

  // Check if initialsLength was passed and set to calculated, unless greater than MAX_INITIALS
  if (initialsLength) {
    calculatedInitialsLength =
      initialsLength <= MAX_INITIALS ? initialsLength : MAX_INITIALS;
  }

  let calculatedInitials;
  // A. Set to initials prop if exists (but truncate to 2 characters max unless length is supplied)
  if (initials) {
    calculatedInitials = initials.substring(0, calculatedInitialsLength);
  } else {
    if (name.trim() && name.split(' ').length > 1) {
      // B. If there are any spaces in the name, set to first letter of each word
      calculatedInitials = name.match(/\b(\w)/g);
      calculatedInitials =
        calculatedInitials &&
        calculatedInitials.join('').substring(0, calculatedInitialsLength);
    } else {
      // C. Set to the name's initials truncated based on calculated length
      calculatedInitials = name.substring(0, calculatedInitialsLength);
    }
  }

  return calculatedInitials;
}

export default helper(toInitials);
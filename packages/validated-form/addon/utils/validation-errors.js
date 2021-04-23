import { assign } from '@ember/polyfills';

export default function buildMessage(messages, key, result) {
  let description = messages.getDescriptionFor(key);

  if (result.message) {
    return result.message;
  }

  let { type, context = {} } = result;

  return messages.getMessageFor(type, assign({ description }, context));
}

export default function buildMessage(messages, key, result = {}) {
  let description = messages.getDescriptionFor(key);

  if (result?.context?.message) {
    return result.context.message;
  }

  let { type, context = {} } = result;

  return messages.getMessageFor(type, Object.assign({ description }, context));
}

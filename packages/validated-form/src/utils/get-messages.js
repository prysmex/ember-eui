import { isPresent } from '@ember/utils';
import { isNone } from '@ember/utils';

import Messages from 'ember-validators/messages';

let cachedRef = null;

/**
 * Find and load messages module on consuming app. Defaults to addon messages.
 * To define a custom message map, create `my-app/app/validators/messages.js`
 * that extends from ember-validators/messages
 *
 * @param  {Object} owner
 * @param  {Boolean} useCache Pass `false` to ignore cached key
 * @return {Object}
 */
export default function getMessages(owner, useCache = true) {
  let messagesModule = Messages;

  if (useCache && isPresent(cachedRef)) {
    return cachedRef;
  }

  if (!isNone(owner)) {
    messagesModule = owner.factoryFor('validator:messages').create()
  }

  cachedRef = messagesModule;

  return messagesModule;
}

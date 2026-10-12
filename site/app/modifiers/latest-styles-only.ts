import { modifier } from 'ember-modifier';

/** The migration preview deliberately runs without the Amsterdam stylesheet. */
export default modifier(() => {
  const link = document.getElementById('eui-theme') as HTMLLinkElement | null;
  if (!link) return;
  const previouslyDisabled = link.disabled;
  link.disabled = true;
  return () => {
    link.disabled = previouslyDisabled;
  };
});

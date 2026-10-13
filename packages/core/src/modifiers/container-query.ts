import { modifier } from 'ember-modifier';

import { matchContainer } from '../utils/container-query/match-container.ts';

/**
 * Reports whether a CSS container query matches the element it is attached to
 * (the Ember counterpart of upstream's `useEuiContainerQuery`):
 *
 * ```hbs
 * <div {{containerQuery "(width > 400px)" onChange=this.setWide}}>…</div>
 * ```
 *
 * The element the modifier is attached to is the one queried: it must be
 * inside a container (an ancestor with e.g. `euiContainerCSS('inline-size')`
 * as its `@css`), and the query is evaluated against that container. `onChange`
 * is called with the current result once and then on every change. `name` is the optional container
 * name (`sidebar`).
 */
const containerQuery = modifier<{
  Element: HTMLElement;
  Args: {
    Positional: [condition: string];
    Named: { name?: string; onChange: (matches: boolean) => void };
  };
}>((element, [condition], { name, onChange }) => {
  const queryList = matchContainer(
    element,
    name ? `${name} ${condition}` : condition
  );
  const handleChange = () => onChange(queryList.matches);

  onChange(queryList.matches);
  queryList.addEventListener('change', handleChange);

  return () => {
    queryList.removeEventListener('change', handleChange);
    queryList.dispose();
  };
});

export default containerQuery;

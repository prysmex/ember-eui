import Route from '@ember/routing/route';
import { service } from '@ember/service';

import { iconsFromGlob } from '@ember-eui/core/utils/icons-from-glob';

import enUs from '../../translations/en-us.json';
import { scrollToHash } from '../utils/scroll-to-hash';

import type EuiConfigService from '@ember-eui/core/services/eui-config';
import type RouterService from '@ember/routing/router-service';
import type { IntlService } from 'ember-intl';

export default class ApplicationRoute extends Route {
  @service declare euiConfig: EuiConfigService;
  @service declare intl: IntlService;
  @service declare router: RouterService;

  beforeModel() {
    this.intl.addTranslations(
      'en-us',
      enUs as unknown as Parameters<IntlService['addTranslations']>[1],
    );
    this.intl.setLocale('en-us');

    // app/icons/*.svg become <EuiIcon @type="site-rocket" /> etc., as shown on
    // the icons docs page
    this.euiConfig.updateConfig({
      'euiIcon.icons': iconsFromGlob(
        import.meta.glob('../icons/**/*.svg', { eager: true }),
        { prefix: 'site-' },
      ),
    });

    // deep links like /docs/core/docs/forms/combo-box#async scroll to the
    // section once the page renders
    this.router.on('routeDidChange', () => scrollToHash(window.location.hash));
  }
}

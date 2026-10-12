import Component from '@glimmer/component';
import { cached, tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { getEuiThemeContext } from '../../utils/emotion/consume.ts';
import { euiClass, useEuiBorealisStyles } from '../../utils/eui/styles.ts';
import { euiCodeBlockAnnotationsStyles } from '../../utils/eui/styles.generated.ts';
import EuiIcon from '../eui-icon.gts';
import EuiPopover from '../eui-popover.gts';

import type EuiI18n from '../../services/eui-i18n.ts';
import type { TemplateOnlyComponent } from '@ember/component/template-only';

/** Scoped stand-in for upstream's global button reset, composed first. */
const BUTTON_RESET = {
  padding: 0,
  margin: 0,
  border: 'none',
  font: 'inherit',
  color: 'inherit',
  cursor: 'pointer'
};

/** Upstream's `AnnotationInfoIcon` glyph. */
const AnnotationInfoIcon: TemplateOnlyComponent<{ Element: SVGElement }> =
  <template>
    <svg
      width="11"
      height="11"
      viewBox="0 0 16 16"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      ...attributes
    ><path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M7.139 14l-.052-6.007H5V6.28h4.111l.052 6.007h1.915V14h-3.94zM6.712 3.38c0-.396.118-.725.354-.987S7.639 2 8.077 2c.438 0 .777.131 1.016.393.24.262.359.591.359.987 0 .39-.12.714-.359.972s-.578.388-1.016.388c-.438 0-.775-.13-1.011-.388-.236-.258-.354-.582-.354-.972z"
      /></svg>
  </template>;

/**
 * @private A line annotation of EuiCodeBlock (upstream
 * `EuiCodeBlockAnnotation`): a round info button next to the line number
 * opening a popover with the note.
 */
interface EuiCodeBlockAnnotationSignature {
  Args: {
    /** The annotated line. */
    lineNumber: number;
  };
  Blocks: {
    /** The note. */
    default: [];
  };
}

export default class EuiCodeBlockAnnotation extends Component<EuiCodeBlockAnnotationSignature> {
  @service declare euiI18n: EuiI18n;
  @tracked isOpen = false;

  icon = AnnotationInfoIcon;

  get context() {
    return getEuiThemeContext(this);
  }

  get styles() {
    return useEuiBorealisStyles(this.context, euiCodeBlockAnnotationsStyles);
  }

  /** Composed into EuiPopover's root (upstream passes it as `css`). */
  get popoverCss() {
    return this.styles.euiCodeBlockAnnotation;
  }

  @cached
  get buttonClasses() {
    return `euiCodeBlockAnnotation__buttonIcon ${euiClass(
      this.context,
      BUTTON_RESET,
      this.styles.euiCodeBlockAnnotation__buttonIcon
    )}`;
  }

  get iconColor() {
    const { upstream } = this.context;
    return upstream.colorMode === 'DARK'
      ? upstream.euiTheme.colors.textInk
      : 'ghost';
  }

  /** Above the full screen mask (upstream). */
  get zIndex() {
    return Number(this.context.upstream.euiTheme.levels.mask) + 1;
  }

  get ariaLabel() {
    return this.euiI18n.lookupToken(
      'euiCodeBlockAnnotations.ariaLabel',
      ({ lineNumber }) =>
        `Click to view a code annotation for line ${lineNumber as number}`,
      { lineNumber: this.args.lineNumber }
    );
  }

  @action
  toggle() {
    this.isOpen = !this.isOpen;
  }

  @action
  close() {
    this.isOpen = false;
  }

  <template>
    <EuiPopover
      class="euiCodeBlock__lineAnnotation"
      @rootCss={{this.popoverCss}}
      @isOpen={{this.isOpen}}
      @closePopover={{this.close}}
      @anchorPosition="downLeft"
      @zIndex={{this.zIndex}}
    >
      <:button>
        <button
          type="button"
          class={{this.buttonClasses}}
          aria-label={{this.ariaLabel}}
          data-test-subj="euiCodeBlockAnnotationIcon"
          {{on "click" this.toggle}}
        >
          <EuiIcon @type={{this.icon}} @size="s" @color={{this.iconColor}} />
        </button>
      </:button>
      <:content>
        <div data-test-subj="euiCodeBlockAnnotationPopover">{{yield}}</div>
      </:content>
    </EuiPopover>
  </template>
}

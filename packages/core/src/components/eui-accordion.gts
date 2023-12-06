import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';
import { action } from '@ember/object';
import didInsert from '@ember/render-modifiers/modifiers/did-insert';
import didUpdate from '@ember/render-modifiers/modifiers/did-update';
import { htmlSafe } from '@ember/template';
import resizeObserver from '../modifiers/resize-observer';

import queue from 'ember-composable-helpers/helpers/queue';
import { element } from 'ember-element-helper';
import set from 'ember-set-helper/helpers/set';
import { and, eq, not } from 'ember-truth-helpers';

import argOrDefault, { argOrDefaultDecorator } from '../helpers/arg-or-default';
import classNames from '../helpers/class-names';

import EuiButtonIcon from './eui-button-icon.gts';
import EuiLoadingSpinner from './eui-loading-spinner.gts';

import type { CommonArgs } from './common.ts';
import type { paddingMapping } from '../utils/css-mappings/eui-accordion';

import uniqueId from 'ember-unique-id-helper-polyfill/helpers/unique-id';

type EuiAccordionPaddingSize = keyof typeof paddingMapping;

type AccordionArgs = {
  id?: string;

  element?: 'div' | 'fieldset';
  /**
   * Class that will apply to the trigger for the accordion.
   */
  buttonClassName?: string;

  buttonProps?: CommonArgs;

  /**
   * Applied to the main button receiving the `onToggle` event.
   * Anything other than the default `button` does not support removing the arrow display (for accessibility of focus).
   */
  buttonElement?: 'div' | 'legend' | 'button';
  /**
   * Extra props to pass to the EuiButtonIcon containing the arrow.
   */
  arrowProps?: {
    className?: string;
  };

  /**
   * Class that will apply to the trigger content for the accordion.
   */
  buttonContentClassName?: string;
  /**
   * The content of the clickable trigger
   */
  buttonContent?: Component;
  /**
   * Will appear right aligned against the button. Useful for separate actions like deletions.
   */
  extraAction?: Component;
  /**
   * The accordion will start in the open state.
   */
  initialIsOpen?: boolean;
  /**
   * Optional callback method called on open and close with a single `isOpen` parameter
   */
  onToggle?: (isOpen: boolean) => void;
  /**
   * The padding around the exposed accordion content.
   */
  paddingSize?: EuiAccordionPaddingSize;
  /**
   * Placement of the arrow indicator, or 'none' to hide it.
   */
  arrowDisplay?: 'left' | 'right' | 'none';
  /**
   * Control the opening of accordion via prop
   */
  forceState?: 'closed' | 'open';
  /**
   * Change `extraAction` and children into a loading spinner
   */
  isLoading?: boolean;
  /**
   * Choose whether the loading message replaces the content. Customize the message by passing a node
   */
  isLoadingMessage?: boolean | Component;

  isOpen?: boolean;

  childClassName?: string;
  triggerClassName?: string;
  childContentClassName?: string;
};

export interface EuiAccordionSignature {
  Element: any;
  Args: AccordionArgs;
  Blocks: {
    buttonContent: [boolean | undefined];
    content: [];
    extraAction: [boolean | undefined];
  };
}

export default class EuiAccordionAccordionComponent extends Component<EuiAccordionSignature> {
  // Defaults
  @argOrDefaultDecorator(false) isLoading!: boolean;
  @argOrDefaultDecorator(false) isLoadingMessage!: boolean;
  @argOrDefaultDecorator(false) initialIsOpen!: boolean;
  @argOrDefaultDecorator('none') paddingSize!: EuiAccordionPaddingSize;
  @argOrDefaultDecorator('left') arrowDisplay!: AccordionArgs['arrowDisplay'];

  @tracked _opened;
  @tracked childWrapper: HTMLDivElement | null = null;
  @tracked childContent: HTMLDivElement | null = null;

  constructor(owner: unknown, args: AccordionArgs) {
    super(owner, args);

    this._opened = this.args.forceState
      ? this.args.forceState === 'open'
      : this.args.initialIsOpen;
  }

  get buttonElement() {
    return this.args.element === 'fieldset' ? 'legend' : 'button';
  }

  get buttonElementIsFocusable() {
    return this.buttonElement === 'button';
  }

  get _arrowDisplay() {
    return this.arrowDisplay === 'none' && !this.buttonElementIsFocusable
      ? 'left'
      : this.arrowDisplay;
  }

  get isOpen(): boolean | undefined {
    return this.args.forceState
      ? this.args.forceState === 'open'
      : this._opened;
  }

  get hasLoadingMessage(): boolean {
    return this.isLoadingMessage && this.isLoadingMessage !== true;
  }

  get buttonClasses(): string {
    return [
      'euiAccordion__button',
      this.args.buttonClassName,
      this.args.buttonProps?.className
    ].join(' ');
  }

  get buttonContentClasses(): string {
    return [
      'euiAccordion__buttonContent',
      this.args.buttonContentClassName
    ].join(' ');
  }

  get childContentStyle(): string | ReturnType<typeof htmlSafe> {
    return this._opened ? '' : htmlSafe(`height: 0px;`);
  }

  setChildContentHeight = () => {
    const { forceState } = this.args;

    requestAnimationFrame(() => {
      const height =
        this.childContent && (forceState ? forceState === 'open' : this._opened)
          ? this.childContent.clientHeight
          : 0;

      this.childWrapper &&
        this.childWrapper.setAttribute('style', `height: ${height}px`);
    });
  };

  @action
  onToggle(): void {
    if (this.args.forceState) {
      this.args.onToggle?.(this.args.forceState === 'open' ? false : true);
    } else {
      this._opened = !this._opened;

      if (this._opened && this.childWrapper) {
        this.childWrapper.focus();
      }

      this.args.onToggle?.(this._opened);
    }
  }

  <template>
    {{#let (argOrDefault @element "div") as |tagName|}}
      {{#if tagName}}
        {{#let
          (element tagName) (element this.buttonElement)
          as |Accordion ButtonElement|
        }}
          {{#if (and Accordion ButtonElement)}}
            <Accordion
              class={{classNames
                (if this.isOpen "euiAccordion-isOpen")
                componentName="EuiAccordion"
              }}
              ...attributes
            >
              <div
                class={{classNames
                  "euiAccordion__triggerWrapper"
                  @triggerClassName
                }}
              >
                {{#if (eq this._arrowDisplay "left")}}
                  <EuiButtonIcon
                    @color="text"
                    @iconClasses={{classNames
                      "euiAccordion__iconButton"
                      (if this.isOpen "euiAccordion__iconButton-isOpen")
                      (if
                        (eq this._arrowDisplay "right")
                        "euiAccordion__iconButton--right"
                      )
                      (if @arrowProps.className @arrowProps.className)
                    }}
                    @iconType="arrowRight"
                    {{on "click" this.onToggle}}
                    aria-controls={{@id}}
                    aria-expanded={{this.isOpen}}
                    tabindex={{if this.buttonElementIsFocusable "-1" "0"}}
                  />
                {{/if}}
                <ButtonElement
                  type="button"
                  id={{argOrDefault @buttonProps.id (uniqueId)}}
                  class={{this.buttonClasses}}
                  aria-controls={{@id}}
                  aria-expanded={{this.isOpen}}
                  aria-labelledby={{argOrDefault @buttonProps.id (uniqueId)}}
                  {{on "click" this.onToggle}}
                >
                  <span class={{this.buttonContentClasses}}>
                    {{yield this.isOpen to="buttonContent"}}
                  </span>
                </ButtonElement>
                {{#if
                  (and
                    @extraAction (has-block "extraAction") (not this.isLoading)
                  )
                }}
                  <div class="euiAccordion__optionalAction">
                    {{yield this.isOpen to="extraAction"}}
                  </div>
                {{else if this.isLoading}}
                  <div class="euiAccordion__optionalAction">
                    <EuiLoadingSpinner />
                  </div>
                {{/if}}
                {{#if (eq this._arrowDisplay "right")}}
                  <EuiButtonIcon
                    @color="text"
                    class={{classNames
                      "euiAccordion__iconButton"
                      (if this.isOpen "euiAccordion__iconButton-isOpen")
                      (if
                        (eq this._arrowDisplay "right")
                        "euiAccordion__iconButton--right"
                      )
                      (if @arrowProps.className @arrowProps.className)
                    }}
                    @iconType="arrowRight"
                    {{on "click" this.onToggle}}
                    aria-controls={{@id}}
                    aria-expanded={{this.isOpen}}
                    tabindex={{if this.buttonElementIsFocusable "-1" "0"}}
                  />
                {{/if}}
              </div>
              <div
                class="euiAccordion__childWrapper"
                style={{this.childContentStyle}}
                id={{@id}}
                {{didInsert (set this "childWrapper")}}
                tabindex="-1"
                role="region"
              >
                <div
                  class={{classNames
                    (if this.isLoading "euiAccordion__children-isLoading")
                    @childClassName
                  }}
                  {{didInsert
                    (queue (set this "childContent") this.setChildContentHeight)
                  }}
                  {{resizeObserver onResize=this.setChildContentHeight}}
                  {{didUpdate this.setChildContentHeight @forceState}}
                >
                  {{#if (and this.isLoading this.isLoadingMessage)}}
                    <EuiLoadingSpinner class="euiAccordion__spinner" />
                    <span>
                      {{#if this.hasLoadingMessage}}
                        {{this.isLoadingMessage}}
                      {{else}}
                        {{! <EuiI18n @token="euiAccordion.isLoading" @default="Loading" /> }}
                        Loading...
                      {{/if}}
                    </span>
                  {{else}}
                    <div
                      class={{classNames
                        componentName="EuiAccordion"
                        paddingSize=this.paddingSize
                      }}
                    >
                      {{yield to="content"}}
                    </div>
                  {{/if}}
                </div>
              </div>
            </Accordion>
          {{/if}}
        {{/let}}
      {{/if}}
    {{/let}}
  </template>
}

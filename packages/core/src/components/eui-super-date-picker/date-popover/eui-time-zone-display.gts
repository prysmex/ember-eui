import Component from '@glimmer/component';
import { cached } from '@glimmer/tracking';

import { getEuiThemeContext } from '../../../utils/emotion/consume.ts';
import EuiFlexGroup from '../../eui-flex-group.gts';
import EuiIcon from '../../eui-icon.gts';
import EuiText from '../../eui-text.gts';

import type { TOC } from '@ember/component/template-only';
import type { ComponentLike } from '@glint/template';
import type { Moment } from 'moment';

/**
 * Upstream `EuiTimeZoneDisplayProps`. `customRender` is a component (instead
 * of a render function) rendered with `@nameDisplay` (a component showing
 * the globe icon and the label), `@utcOffset` (`'UTC+1'`) and
 * `@timeZoneName` (`'Europe/Brussels'`).
 */
export interface EuiTimeZoneDisplayProps {
  /**
   * An IANA time zone name, e.g. `'America/Los_Angeles'`, or `'Browser'`
   * (the browser's zone) or `'UTC'`. Nothing renders without a valid one.
   */
  timeZone?: string;
  /** Reference date for the UTC offset (daylight saving edge cases). */
  date?: Moment;
  /** Extra content next to (or instead of) the name, see above. */
  customRender?: ComponentLike<{
    Args: {
      nameDisplay: ComponentLike;
      utcOffset?: string;
      timeZoneName?: string;
    };
  }>;
  /** `id` of the display (upstream spreads `div` props). */
  id?: string;
}

/**
 * Port of upstream `useEuiUTCOffsetDisplay`: the UTC offset label of an
 * IANA zone name ("UTC+2"), through `Intl.DateTimeFormat`.
 */
export function useEuiUTCOffsetDisplay(timeZoneName: string, date?: Date) {
  try {
    if (timeZoneName === 'UTC') {
      return { utc: 'UTC', name: '', isInvalid: false };
    }

    const ianaName =
      timeZoneName === 'Browser'
        ? new Intl.DateTimeFormat().resolvedOptions().timeZone
        : timeZoneName;
    const formatter = new Intl.DateTimeFormat(undefined, {
      timeZone: ianaName,
      timeZoneName: 'shortOffset'
    });
    const formattedParts = formatter.formatToParts(date ?? new Date());
    const timeZoneNamePart =
      formattedParts.find((part) => part.type === 'timeZoneName')?.value ||
      '';

    return {
      utc: timeZoneNamePart.replace('GMT', 'UTC'),
      name: ianaName,
      isInvalid: false
    };
  } catch {
    return { utc: '', name: timeZoneName, isInvalid: true };
  }
}

const NameDisplay: TOC<{ Args: { label: string } }> = <template>
  <EuiIcon @type="globe" @color="subdued" />
  <EuiText @color="subdued" @size="s">{{@label}}</EuiText>
</template>;

/** @private Time zone information under the date popover tabs. */
export interface EuiTimeZoneDisplaySignature {
  Args: EuiTimeZoneDisplayProps;
}

export default class EuiTimeZoneDisplay extends Component<EuiTimeZoneDisplaySignature> {
  NameDisplay = NameDisplay;

  get offset() {
    return useEuiUTCOffsetDisplay(
      this.args.timeZone ?? 'Browser',
      this.args.date ? this.args.date.toDate() : undefined
    );
  }

  get isVisible() {
    return Boolean(this.args.timeZone) && !this.offset.isInvalid;
  }

  get label() {
    const { utc, name } = this.offset;
    return !name ? utc : `${utc} (${name})`;
  }

  /** Upstream `euiTimeZoneDisplayStyles`: `s` padding at the sides and bottom. */
  @cached
  get css() {
    const { size } = getEuiThemeContext(this).upstream.euiTheme;
    return { paddingInline: size.s, paddingBlockEnd: size.s };
  }

  <template>
    {{#if this.isVisible}}
      <EuiFlexGroup
        @alignItems="center"
        @gutterSize="xs"
        @css={{this.css}}
        id={{@id}}
        aria-label={{this.label}}
        data-test-subj="euiTimeZoneDisplay"
      >
        {{#if @customRender}}
          <@customRender
            @nameDisplay={{component this.NameDisplay label=this.label}}
            @utcOffset={{this.offset.utc}}
            @timeZoneName={{this.offset.name}}
          />
        {{else}}
          <this.NameDisplay @label={{this.label}} />
        {{/if}}
      </EuiFlexGroup>
    {{/if}}
  </template>
}

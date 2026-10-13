import type { ComponentLike } from '@glint/template';

export interface DurationRange {
  end: ShortDate;
  label?: string;
  start: ShortDate;
}

export type ShortDate = NowDateMode | string;

export type NowDateMode = 'now';

export type TimeUnitId = 's' | 'm' | 'h' | 'd' | 'w' | 'M' | 'y';

export type TimeUnitFromNowId = 's+' | 'm+' | 'h+' | 'd+' | 'w+' | 'M+' | 'y+';

export interface RelativeParts {
  count: number;
  round: boolean;
  roundUnit?: TimeUnitId;
  unit: string;
}

export type Milliseconds = number;

export interface RelativeOption {
  text: string;
  value: TimeUnitAllId;
}

export type TimeUnitAllId = TimeUnitId | TimeUnitFromNowId;

/** Units of the refresh interval: seconds, minutes or hours. */
export type RefreshUnitsOptions = 's' | 'm' | 'h';

export type OnRefreshChangeArgs = {
  isPaused: boolean;
  refreshInterval: number;
  /** The unit the user picked (upstream `OnRefreshChangeProps`). */
  intervalUnits?: RefreshUnitsOptions;
};

export type ApplyRefreshInterval = (args: OnRefreshChangeArgs) => void;

interface ApplyTimeArgs extends DurationRange {
  start: string;
  end: string;
  keepPopoverOpen?: boolean;
  quickSelect?: QuickSelect;
}
export type ApplyTime = (args: ApplyTimeArgs) => void;

/**
 * A custom panel of the quick select popover (upstream `QuickSelectPanel`):
 * `content` is a component, rendered with `@applyTime` (call it with
 * `{ start, end }` to apply a range and close the popover).
 */
export interface QuickSelectPanel {
  title: string;
  content: ComponentLike<{ Args: { applyTime: ApplyTime } }>;
}

export interface QuickSelect {
  timeTense: string;
  timeValue: number;
  timeUnits: TimeUnitId;
}

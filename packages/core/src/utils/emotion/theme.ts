/** Experimental tokens for the Emotion spike; not an upstream EUI theme. */
export type EuiColorMode = 'light' | 'dark';
export interface EuiEmotionTheme {
  colors: {
    background: string;
    text: string;
    primary: string;
    success: string;
    warning: string;
    danger: string;
    onPrimary: string;
    onSuccess: string;
    onWarning: string;
    onDanger: string;
    disabled: string;
    focus: string;
  };
  fontFamily: string;
  borderRadius: number;
  spacing: number;
}
export type EuiThemeOverrides = Partial<Omit<EuiEmotionTheme, 'colors'>> & {
  colors?: Partial<EuiEmotionTheme['colors']>;
};

export function defaultTheme(mode: EuiColorMode): EuiEmotionTheme {
  const dark = mode === 'dark';
  return {
    colors: {
      background: dark ? '#1d1e24' : '#ffffff',
      text: dark ? '#f1f4fa' : '#1a1c21',
      primary: dark ? '#79b8ff' : '#005a9e',
      success: dark ? '#75d8b4' : '#006b45',
      warning: dark ? '#f5c86a' : '#805500',
      danger: dark ? '#ff9b9b' : '#b4232c',
      onPrimary: dark ? '#12151c' : '#ffffff',
      onSuccess: dark ? '#12151c' : '#ffffff',
      onWarning: dark ? '#12151c' : '#ffffff',
      onDanger: dark ? '#12151c' : '#ffffff',
      disabled: dark ? '#9da7b8' : '#596579',
      focus: dark ? '#a4caff' : '#005a9e',
    },
    fontFamily: 'Inter, system-ui, sans-serif',
    borderRadius: 6,
    spacing: 8,
  };
}

export function mergeTheme(base: EuiEmotionTheme, overrides?: EuiThemeOverrides): EuiEmotionTheme {
  return { ...base, ...overrides, colors: { ...base.colors, ...overrides?.colors } };
}

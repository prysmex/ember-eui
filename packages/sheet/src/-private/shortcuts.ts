/**
 * The shortcut list's table (V03 5.5): what the docs' editing page
 * (`docs/sheet/editing/index.md`, "Keyboard") documents, one row each, by
 * section. Plain data: `shortcut-list.gts`
 * draws it, and every text is a message (`src/core/messages.ts`), key
 * names included, so `@messages` and `eui-i18n` translate it.
 */
import type { SheetMessages } from '../core/messages.ts';

/** What decides whether a row is listed. */
export interface ShortcutContext {
  readOnly: boolean;
  canInsert: boolean;
  rowNumbers: boolean;
  fieldDrag: boolean;
  /** Row drag (`@canMove`, V03 10.1). */
  canMove?: boolean;
}

/** Messages without parameters: every text of the list. */
type MessageKey = {
  [K in keyof SheetMessages]: SheetMessages[K] extends () => string ? K : never;
}[keyof SheetMessages];

export interface ShortcutRow {
  /** Alternatives, each a combination: `[['Mod', 'Shift', 'Z'], ['Ctrl', 'Y']]`. */
  keys: string[][];
  message: MessageKey;
  /** Left out when false (its feature is off). */
  when?: (context: ShortcutContext) => boolean;
}

export interface ShortcutSection {
  title: MessageKey;
  rows: ShortcutRow[];
}

const editable = (context: ShortcutContext) => !context.readOnly;
const inserts = (context: ShortcutContext) => context.canInsert;
const rowNumbers = (context: ShortcutContext) => context.rowNumbers;

export const SHORTCUT_SECTIONS: readonly ShortcutSection[] = [
  {
    title: 'shortcutsNavigation',
    rows: [
      { keys: [['Arrows']], message: 'shortcutMove' },
      { keys: [['Home'], ['End']], message: 'shortcutRowEdges' },
      {
        keys: [
          ['Mod', 'Home'],
          ['Mod', 'End']
        ],
        message: 'shortcutDataEdges'
      },
      { keys: [['Mod', 'Arrows']], message: 'shortcutJump' },
      { keys: [['PageUp'], ['PageDown']], message: 'shortcutPage' },
      { keys: [['Tab']], message: 'shortcutLeave' }
    ]
  },
  {
    title: 'shortcutsSelection',
    rows: [
      { keys: [['Shift', 'Arrows']], message: 'shortcutExtend' },
      {
        keys: [
          ['Shift', 'Home'],
          ['Shift', 'End']
        ],
        message: 'shortcutExtendRow'
      },
      {
        keys: [
          ['Mod', 'Shift', 'Home'],
          ['Mod', 'Shift', 'End']
        ],
        message: 'shortcutExtendRecords'
      },
      { keys: [['Mod', 'Shift', 'Arrows']], message: 'shortcutExtendJump' },
      { keys: [['Mod', 'A']], message: 'shortcutSelectAll' },
      {
        keys: [
          ['Shift', '↑'],
          ['Shift', '↓']
        ],
        message: 'shortcutSelectRows',
        when: rowNumbers
      }
    ]
  },
  {
    title: 'shortcutsEditing',
    rows: [
      { keys: [['Enter'], ['F2']], message: 'shortcutEdit', when: editable },
      { keys: [['Character']], message: 'shortcutType', when: editable },
      { keys: [['Enter']], message: 'shortcutSaveDown', when: editable },
      {
        keys: [['Tab'], ['Shift', 'Tab']],
        message: 'shortcutSaveRight',
        when: editable
      },
      { keys: [['Escape']], message: 'shortcutCancelEdit', when: editable },
      {
        keys: [['Delete'], ['Backspace']],
        message: 'shortcutClear',
        when: editable
      },
      { keys: [['Space']], message: 'shortcutSpace' },
      { keys: [['Mod', 'D']], message: 'shortcutFillDown', when: editable },
      { keys: [['Mod', 'R']], message: 'shortcutFillRight', when: editable }
    ]
  },
  {
    title: 'shortcutsRecords',
    rows: [
      {
        keys: [['Shift', 'Enter']],
        message: 'shortcutInsertBelow',
        when: inserts
      },
      { keys: [['Enter']], message: 'shortcutAddRecord', when: inserts },
      { keys: [['Enter']], message: 'shortcutExpand', when: rowNumbers },
      { keys: [['Space']], message: 'shortcutCheckRow', when: rowNumbers },
      {
        keys: [['Shift', 'F10'], ['Menu'], ['RightClick']],
        message: 'shortcutRowMenu'
      },
      { keys: [['Enter'], ['RightClick']], message: 'shortcutFieldMenu' },
      {
        keys: [['Space']],
        message: 'shortcutMoveField',
        when: (context) => context.fieldDrag
      },
      {
        keys: [
          ['Alt', 'Shift', '↑'],
          ['Alt', 'Shift', '↓']
        ],
        message: 'shortcutMoveRecords',
        when: (context) => !!context.canMove
      }
    ]
  },
  {
    title: 'shortcutsClipboard',
    rows: [
      { keys: [['Mod', 'C']], message: 'shortcutCopy' },
      { keys: [['Mod', 'X']], message: 'shortcutCut', when: editable },
      { keys: [['Mod', 'V']], message: 'shortcutPaste', when: editable },
      { keys: [['Mod', 'Z']], message: 'shortcutUndo', when: editable },
      {
        keys: [
          ['Mod', 'Shift', 'Z'],
          ['Ctrl', 'Y']
        ],
        message: 'shortcutRedo',
        when: editable
      },
      { keys: [['Mod', '/']], message: 'shortcutShowList' }
    ]
  }
];

/** Key ids drawn from a message; any other id is drawn as it is (`A`, `F2`, `↑`). */
const KEY_MESSAGES: Readonly<Record<string, MessageKey>> = {
  Ctrl: 'shortcutKeyCtrl',
  Shift: 'shortcutKeyShift',
  Alt: 'shortcutKeyAlt',
  Enter: 'shortcutKeyEnter',
  Escape: 'shortcutKeyEscape',
  Tab: 'shortcutKeyTab',
  Space: 'shortcutKeySpace',
  Delete: 'shortcutKeyDelete',
  Backspace: 'shortcutKeyBackspace',
  Home: 'shortcutKeyHome',
  End: 'shortcutKeyEnd',
  PageUp: 'shortcutKeyPageUp',
  PageDown: 'shortcutKeyPageDown',
  Arrows: 'shortcutKeyArrows',
  Menu: 'shortcutKeyMenu',
  Character: 'shortcutKeyCharacter',
  RightClick: 'shortcutKeyRightClick'
};

/** Whether `Mod` is ⌘ (Apple platforms) rather than Ctrl. */
export function isApplePlatform(): boolean {
  if (typeof navigator === 'undefined') return false;
  const platform =
    (navigator as Navigator & { userAgentData?: { platform?: string } })
      .userAgentData?.platform ?? navigator.platform;
  return /mac|iphone|ipad|ipod/i.test(platform ?? '');
}

/** A key's label: `Mod` is ⌘ on a Mac and Ctrl elsewhere (5.5). */
export function keyLabel(
  key: string,
  messages: SheetMessages,
  apple: boolean
): string {
  if (key === 'Mod') return apple ? '⌘' : messages.shortcutKeyCtrl();
  const message = KEY_MESSAGES[key];
  return message ? messages[message]() : key;
}

export interface ShortcutListRow {
  /** Alternatives, each a list of key labels. */
  keys: string[][];
  text: string;
}

export interface ShortcutListSection {
  title: string;
  rows: ShortcutListRow[];
}

/** The sections to draw, translated, without the rows whose feature is off and without empty sections. */
export function shortcutList(
  context: ShortcutContext,
  messages: SheetMessages,
  apple = isApplePlatform()
): ShortcutListSection[] {
  const sections: ShortcutListSection[] = [];
  for (const section of SHORTCUT_SECTIONS) {
    const rows = section.rows
      .filter((row) => !row.when || row.when(context))
      .map((row) => ({
        keys: row.keys.map((combo) =>
          combo.map((key) => keyLabel(key, messages, apple))
        ),
        text: messages[row.message]()
      }));
    if (rows.length) {
      sections.push({ title: messages[section.title](), rows });
    }
  }
  return sections;
}

---
'@ember-eui/core': patch
---

`euiClass` remembers the class it composed, per Emotion cache and styles, so components rendered many times with the same styles (table rows, list items, badges) no longer serialize and hash them on every render: about 10x faster per call for typical args (0.84µs to 0.08µs in a Node benchmark; 5.3µs to 0.1µs for a few large style objects). Serialized styles are remembered by identity and plain objects by content; styles containing functions are serialized as before, and a flushed cache starts over. The classes are the same as before.

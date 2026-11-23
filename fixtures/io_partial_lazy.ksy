meta: {id: io_partial_lazy}
instances:
  entries: {pos: 0, type: entry, size: 2, repeat: expr, repeat-expr: 2}
types:
  entry:
    seq:
      - {id: link, type: u1}
      - {id: value, type: u1, if: link != 0 and previous == 0x11}
    instances:
      previous: {io: '_root.entries[0]._io', pos: 1, type: u1}

meta:
  id: stream_control
  endian: le
seq:
  - {id: prefix, contents: [170]}
  - {id: block, type: block, size: 4}
  - {id: tail, type: u1}
  - {id: tag, type: u1}
  - id: choice
    size: 4
    type:
      switch-on: tag
      cases:
        1: word
        2: message
  - {id: unicode, type: str, size: 4, encoding: UTF-16LE}
  - {id: lines, type: strz, encoding: UTF-8, repeat: eos}
  - {id: empty_steps, size: 0, repeat: until, repeat-until: _index == 1}
types:
  block:
    seq:
      - {id: first, type: u1}
    instances:
      at_zero: {type: u1, pos: 0}
      at_end: {type: u1, pos: 3}
      outside: {type: u1, pos: 4}
      cursor: {value: _io.pos}
      stream_size: {value: _io.size}
  word:
    seq:
      - {id: value, type: u4}
  message:
    seq:
      - {id: value, type: strz, encoding: ASCII}

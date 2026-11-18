meta:
  id: conditional_layout
  endian: le
seq:
  - id: flag
    type: u1
  - id: count
    type: u1
  - id: payload
    size: count
    if: flag != 0
  - id: checksum
    type: u2be
    if: (flag & 1) == 1 and not false
    valid: 0x1234
  - id: entries
    type: entry
    repeat: expr
    repeat-expr: count
    if: flag == 2
  - id: tail
    type: u1
instances:
  last:
    pos: _io.size - 1
    type: u1
  following:
    type: u1
  repeated:
    pos: 2
    size: 1
    repeat: expr
    repeat-expr: count
  never:
    pos: -1
    type: u1
    if: false
  bad_position:
    pos: -1
    type: u1
  bad_read:
    pos: _io.size - 1
    type: u4
  derived:
    value: (count + 2) * 3
  chained:
    value: derived + 1
  cursor:
    value: _io.pos
  position_after:
    value: _io.pos
  short_circuit:
    value: false and (1 / 0 == 0)
  choice:
    value: 'true ? 9 : 1 / 0'
  overflow:
    value: 9223372036854775807 + 1
  zero_divide:
    value: 1 / 0
  minimum:
    value: '-9223372036854775808'
  division_overflow:
    value: minimum / -1
  negative_remainder:
    value: -9837 % 13
  has_payload:
    value: flag != 0
  boolean_dependency:
    value: has_payload and true
  bits:
    value: (1 << 8) | 2
  loop_a:
    pos: loop_b
    type: u1
  loop_b:
    pos: loop_a
    type: u1
types:
  entry:
    seq:
      - id: code
        type: u1
      - id: extra
        type: s1
        if: code % 2 == 0

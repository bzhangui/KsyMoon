meta: {id: cross_stream_layout, endian: le}
seq:
  - {id: head, type: u1}
  - {id: left, size: 4, type: slot}
  - {id: right, size: 4, type: slot}
  - {id: absent, size: 4, type: slot, if: false}
  - {id: tail, type: u1}
types:
  slot:
    seq:
      - {id: marker, type: u1}
    instances:
      root_marker: {io: _root._io, pos: 0, type: u1}
      parent_marker: {io: _parent._io, pos: 0, type: u1}
  pair:
    seq:
      - {id: first, type: u1}
      - {id: second, type: u1}
    instances:
      parent_marker: {io: _parent._io, pos: 0, type: u1}
instances:
  chosen: {io: 'head + 1 == 0xab ? left._io : right._io', pos: 1, type: u1}
  next_left: {io: left._io, type: u1}
  positioned: {io: left._io, pos: 3, type: u1}
  owner_position: {value: _io.pos}
  left_position: {value: left._io.pos}
  right_position: {value: right._io.pos}
  left_remaining: {io: left._io, size-eos: true}
  pair: {io: left._io, pos: 1, size: 2, type: pair}
  eos_items: {io: right._io, pos: 1, type: u1, repeat: eos}
  until_items: {io: right._io, pos: 1, type: u1, repeat: until, repeat-until: _ == 0}
  skipped: {io: absent._io, pos: -1, type: u1, if: false}
  invalid: {io: absent._io, type: u1}
  out_of_bounds: {io: left._io, pos: 5, type: u1}
  raw_switch:
    io: right._io
    pos: 1
    size: 2
    type: {switch-on: head, cases: {1: u1}}

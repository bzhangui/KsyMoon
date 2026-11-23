meta: {id: io_budget, endian: le}
seq:
  - {id: quantity, type: u4}
  - {id: rest, size-eos: true}
instances:
  cached: {io: _root._io, pos: 0, type: u1, repeat: expr, repeat-expr: quantity}
  failing: {io: _root._io, pos: 0, type: u4, repeat: expr, repeat-expr: cached.length}
  small: {io: _root._io, pos: 0, type: u1, repeat: expr, repeat-expr: 400001}

meta: {id: reader_edges}
seq:
  - {id: n, type: u1}
instances:
  sized_text: {pos: 1, type: strz, encoding: ASCII, size: n - 1}
  padded_bytes: {pos: 1, size: n - 1, pad-right: 0}
  conditional_text: {pos: 1, type: strz, encoding: ASCII, size: n - 1, if: n > 0}
  explicit_text: {pos: 1, type: str, encoding: UTF-16LE, terminator: 124, eos-error: false}
  explicit_strz: {pos: 1, type: strz, encoding: UTF-16LE, terminator: 124, eos-error: false}
  explicit_sized: {pos: 1, type: str, encoding: UTF-16LE, terminator: 124, size-eos: true}
  explicit_included: {pos: 1, type: str, encoding: UTF-16LE, terminator: 124, include: true}
  implicit_strz: {pos: 1, type: strz, encoding: UTF-16LE}
  unpositioned: {type: str, encoding: UTF-16LE, terminator: 124, eos-error: false}
  following: {size-eos: true}
  cursor: {value: _io.pos}

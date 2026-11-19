meta: {id: pure_stream_value}
seq:
  - {id: header, type: header, if: _io.size > 0}
instances:
  peek: {type: header, pos: 0}
types:
  header:
    instances:
      number: {value: 42}
      stream_size: {value: _io.size}

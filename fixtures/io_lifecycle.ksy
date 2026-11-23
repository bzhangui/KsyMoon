meta: {id: io_lifecycle, endian: le}
seq:
  - {id: source, size: 2, type: source}
types:
  source:
    seq:
      - {id: marker, type: u1}
  broken:
    seq:
      - {id: word, type: u2}
instances:
  failed: {io: source._io, pos: 0, size: 1, type: broken}

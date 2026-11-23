meta: {id: cast_navigation}
seq:
  - {id: tag, type: u1}
  - id: section
    size: 1
    type:
      switch-on: tag
      cases: {1: outer::left, 2: right}
types:
  outer:
    types:
      left:
        seq:
          - {id: marker, type: u1}
  right:
    seq:
      - {id: marker, type: u1}
instances:
  narrowed: {value: 'section.as<outer::left>'}

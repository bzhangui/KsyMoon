meta: {id: pure_repeated_value}
seq:
  - {id: headers, type: pure_repeated_value, repeat: expr, repeat-expr: 2}
instances:
  single: {type: pure_repeated_value}
  choice:
    type:
      switch-on: 1
      cases:
        _: pure_repeated_value
types:
  pure_repeated_value:
    instances:
      number: {value: 42}

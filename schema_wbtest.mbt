///|
fn expect_schema_error(source : String, message : String) -> Unit raise {
  try generate(source) catch {
    InvalidSchema(actual) => assert_eq(actual, message)
  } noraise {
    _ => fail("expected schema validation to fail")
  }
}

///|
test "scalar validation rejects impossible ranges before generating code" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - id: version
    #|    type: u1
    #|    valid: {min: 10, max: 2}
  expect_schema_error(source, "seq[0].valid: minimum exceeds maximum")
  expect_schema_error(
    source.replace_all(old="{min: 10, max: 2}", new="{eq: 256}"),
    "seq[0].valid: constraint is outside the integer field's range",
  )
}

///|
test "contents rejects values outside a byte" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - id: magic
    #|    contents: [0, 256]
  expect_schema_error(
    source, "seq[0].contents[1]: expected a byte (0..255) or a UTF-8 string",
  )
}

///|
test "conditions must be boolean rather than integer truthiness" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - id: flag
    #|    type: u1
    #|  - id: data
    #|    size: 1
    #|    if: flag
  expect_schema_error(source, "seq[1].if: expected a boolean expression")
}

///|
test "expressions reject forward fields and optional numeric references" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - {id: optional, type: u1, if: true}
    #|  - {id: data, type: u1, if: optional == 1}
  expect_schema_error(
    source, "seq[1].if: expression requires a nonoptional scalar field",
  )
  expect_schema_error(
    source.replace_all(old="optional == 1", new="later == 1"),
    "seq[1].if: unknown or forward field 'later'",
  )
}

///|
test "instances reject cyclic value dependencies" {
  let source =
    #|meta: {id: example}
    #|instances:
    #|  first: {value: second + 1}
    #|  second: {value: first + 1}
  try validate(source) catch {
    InvalidSchema(message) =>
      assert_true(message.contains("cyclic instance dependency"))
  } noraise {
    _ => fail("accepted cyclic instances")
  }
}

///|
test "expression input is parsed rather than interpolated into output" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - {id: flag, type: u1, if: "true); abort(\"bad\")"}
  try generate(source) catch {
    InvalidSchema(message) =>
      assert_true(message.has_prefix("seq[0].if: unexpected expression token"))
  } noraise {
    _ => fail("accepted invalid expression syntax")
  }
}

///|
test "flat operator chains respect the expression depth bound" {
  let sum = Array::make(100, "1").join(" + ")
  let source = "meta: {id: example}\ninstances:\n  total: {value: '\{sum}'}\n"
  expect_schema_error(
    source, "instances.total.value: expression nesting exceeds 64",
  )
}

///|
test "schema sizes can only reference previously read unsigned fields" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - id: data
    #|    size: length
    #|  - id: length
    #|    type: u1
  expect_schema_error(
    source, "seq[0].size: expected an earlier scalar u1, u2 or u4 field, optionally minus an integer",
  )
}

///|
test "signed fields cannot be used as unsigned lengths" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - id: length
    #|    type: s1
    #|  - id: data
    #|    size: length
  expect_schema_error(
    source, "seq[1].size: expected an earlier scalar u1, u2 or u4 field, optionally minus an integer",
  )
}

///|
test "64-bit integers cannot silently narrow to a length" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - id: length
    #|    type: u8le
    #|  - id: data
    #|    size: length
  expect_schema_error(
    source, "seq[1].size: expected an earlier scalar u1, u2 or u4 field, optionally minus an integer",
  )
}

///|
test "recursive type definitions cannot generate unbounded parsing" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - id: value
    #|    type: node
    #|types:
    #|  node:
    #|    seq:
    #|      - id: next
    #|        type: node
  expect_schema_error(source, "types.node: recursive type reference")
}

///|
test "a schema id does not shadow a MoonBit builtin type" {
  let source =
    #|meta: {id: bytes}
    #|seq:
    #|  - id: payload
    #|    size: 3
  let generated = generate(source)
  assert_true(
    generated.contains("pub fn parse_bytes(input : Bytes) -> BytesRecord"),
  )
}

///|
test "repeat modes reject missing or contradictory controls" {
  let source = "meta: {id: example}\nseq:\n  - {id: entries, type: u1, repeat: until}\n"
  expect_schema_error(
    source, "seq[0].repeat: expected expr/repeat-expr, eos, or until/repeat-until",
  )
  expect_schema_error(
    source.replace_all(old="repeat: until", new="repeat: eos, repeat-expr: 2"),
    "seq[0].repeat: expected expr/repeat-expr, eos, or until/repeat-until",
  )
}

///|
test "sized streams reject contradictory size and eos bounds" {
  expect_schema_error(
    "meta: {id: example}\nseq:\n  - {id: data, size: 4, size-eos: true}\n", "seq[0]: size and size-eos are mutually exclusive; size-eos must be boolean",
  )
}

///|
test "encoding and padding options have explicit validation" {
  expect_schema_error(
    "meta: {id: example}\nseq:\n  - {id: text, type: str, size: 4, encoding: SJIS}\n",
    "seq[0].encoding: encoding is awaiting implementation: SJIS",
  )
  expect_schema_error(
    "meta: {id: example}\nseq:\n  - {id: text, terminator: 0, pad-right: 32}\n",
    "seq[0].pad-right: padding requires a sized field",
  )
}

///|
test "until members resolve against the element definition" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - {id: rows, type: row, repeat: until, repeat-until: '_.missing == 0'}
    #|types:
    #|  row:
    #|    seq:
    #|      - {id: marker, type: u1}
  expect_schema_error(source, "rows: unknown element member 'missing'")
}

///|
test "switch case types agree with selector types" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - {id: tag, type: u1}
    #|  - id: body
    #|    type:
    #|      switch-on: tag
    #|      cases:
    #|        '"x"': u1
  expect_schema_error(source, "seq[1]: expected an integer expression")
}

///|
test "numeric YAML keys remain intact and duplicates are rejected" {
  expect_schema_error(
    "meta: {id: example}\nseq:\n  - id: body\n    type:\n      switch-on: 1\n      cases: {1: u1, 1: u2le}\n",
    "YAML line 7: 1: duplicated key in mapping",
  )
}

///|
test "scope flattening rejects colliding type names" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - {id: data, type: a}
    #|types:
    #|  a:
    #|    seq:
    #|      - {id: data, type: b}
    #|    types:
    #|      b:
    #|        seq:
    #|          - {id: data, type: u1}
    #|  a_b:
    #|    seq:
    #|      - {id: data, type: u1}
  expect_schema_error(source, "types.a_b: flattened type name collision")
}

///|
test "cross-stream selectors reject invalid objects and stream types" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - {id: raw, size: 1}
    #|  - {id: left, type: slot}
    #|types:
    #|  slot:
    #|    seq:
    #|      - {id: marker, type: u1}
    #|instances:
    #|  selected: {io: 'SELECTOR', type: u1}
  for
    selector in [
      "1", "raw", "_parent._io", "_root.missing._io", "left.marker._io", "left._io[0]",
      "left[true]._io", "left[0]._io", "true ? left._io : 0",
    ] {
    try generate(source.replace_all(old="SELECTOR", new=selector)) catch {
      InvalidSchema(message) =>
        assert_true(message.contains("instances.selected"))
    } noraise {
      _ => fail("accepted invalid io selector: " + selector)
    }
  }
}

///|
test "unused io definitions and value instances remain validated" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - {id: marker, type: u1}
    #|types:
    #|  unused:
    #|    instances:
    #|      selected: {io: 1, type: u1}
  try generate(source) catch {
    InvalidSchema(message) =>
      assert_true(message.contains("instances.selected"))
  } noraise {
    _ => fail("accepted invalid unused stream selector")
  }
  let source =
    #|meta: {id: example}
    #|instances:
    #|  selected: {io: _io, value: 1}
  try generate(source) catch {
    InvalidSchema(message) => assert_true(message.contains("io"))
  } noraise {
    _ => fail("accepted io on a value instance")
  }
}

///|
test "context navigation retains expression type and cycle checks" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - {id: marker, type: u1}
    #|instances:
    #|  selected: {io: _io, type: u1}
    #|  a: {value: b}
    #|  b: {value: a}
  try generate(source) catch {
    InvalidSchema(message) => assert_true(message.contains("cyclic"))
  } noraise {
    _ => fail("accepted cyclic navigation values")
  }
}

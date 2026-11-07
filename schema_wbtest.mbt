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
test "schema keywords that change layout fail with a field path" {
  let source =
    #|meta: {id: example}
    #|seq:
    #|  - id: flag
    #|    type: u1
    #|  - id: data
    #|    size: 1
    #|    if: flag
  expect_schema_error(source, "seq[1].if: unsupported key")
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

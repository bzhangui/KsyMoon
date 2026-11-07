///|
fn wire_sample() -> Bytes {
  b"KSY!\x00\xC3\xA9\xFF" +
  b"\x80\x7F\x00\x80\x7F\xFF\x80\x00\x00\x00\xFF\xFF\xFF\x7F"
}

///|
test "contents accepts UTF-8 strings and mixed byte arrays" {
  let record = @wire.parse_wire_checks(wire_sample())
  assert_eq(record.magic.to_owned(), b"KSY!")
  assert_eq(record.marker.to_owned(), b"\x00\xC3\xA9\xFF")
}

///|
test "signed integers decode 8, 16 and 32-bit boundaries across byte orders" {
  let record = @wire.parse_wire_checks(wire_sample())
  assert_eq(record.byte_min, -128)
  assert_eq(record.byte_max, 127)
  assert_eq(record.short_min, -32768)
  assert_eq(record.short_max, 32767)
  assert_eq(record.word_min, -2147483648)
  assert_eq(record.word_max, 2147483647)
}

///|
test "contents reports the first mismatching byte and field" {
  try @wire.parse_wire_checks(b"KSY!\x00\xC3\xA8\xFE") catch {
    @wire.WireChecksContentsMismatch(field~, offset~, expected~, actual~) => {
      assert_eq(field, "wire_checks.marker")
      assert_eq(offset, 6)
      assert_eq(expected, 0xA9)
      assert_eq(actual, 0xA8)
    }
    err => raise err
  } noraise {
    _ => fail("expected a signature mismatch")
  }
}

///|
test "contents keeps the ordinary truncation diagnostic for short inputs" {
  try @wire.parse_wire_checks(b"KSY!\x00") catch {
    @wire.WireChecksTruncated(field~, offset~, needed~, remaining~) => {
      assert_eq(field, "wire_checks.marker")
      assert_eq(offset, 4)
      assert_eq(needed, 4L)
      assert_eq(remaining, 1)
    }
    err => raise err
  } noraise {
    _ => fail("expected a truncated signature")
  }
}

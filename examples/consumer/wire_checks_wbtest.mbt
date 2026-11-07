///|
test "contents accepts UTF-8 strings and mixed byte arrays" {
  let record = @wire.parse_wire_checks(b"KSY!\x00\xC3\xA9\xFF")
  assert_eq(record.magic.to_owned(), b"KSY!")
  assert_eq(record.marker.to_owned(), b"\x00\xC3\xA9\xFF")
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

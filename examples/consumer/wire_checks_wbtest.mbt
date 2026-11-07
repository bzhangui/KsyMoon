///|
fn wire_prefix() -> Bytes {
  b"KSY!\x00\xC3\xA9\xFF" +
  b"\x80\x7F\x00\x80\x7F\xFF\x80\x00\x00\x00\xFF\xFF\xFF\x7F"
}

///|
fn wire_sample() -> Bytes {
  wire_prefix() + b"\x07\xFF\x0F\xFF" + b"\x80\x12\x34\x56\x78\x9A\xBC\xDE"
}

///|
test "scalar validation accepts exact values and inclusive bounds" {
  let record = @wire.parse_wire_checks(wire_sample())
  assert_eq(record.version, 7U)
  assert_eq(record.adc, 4095U)
  assert_eq(record.delta, -1)
  assert_eq(
    @wire.parse_wire_checks(
      wire_prefix() + b"\x07\x00\x00\x80" + b"\x80\x12\x34\x56\x78\x9A\xBC\xDE",
    ).adc,
    0U,
  )
}

///|
test "unsigned 64-bit integers decode all bytes in big-endian order" {
  assert_eq(
    @wire.parse_wire_checks(wire_sample()).big_tick,
    0x80123456789ABCDEUL,
  )
}

///|
test "scalar validation locates an out-of-range field after its read" {
  try @wire.parse_wire_checks(wire_prefix() + b"\x07\x00\x10\xFF") catch {
    @wire.WireChecksInvalidValue(field~, offset~, value~, minimum~, maximum~) => {
      assert_eq(field, "wire_checks.adc")
      assert_eq(offset, 23)
      assert_eq(value, 4096L)
      assert_eq(minimum, 0L)
      assert_eq(maximum, 4095L)
    }
    err => raise err
  } noraise {
    _ => fail("accepted an out-of-range ADC value")
  }
}

///|
test "scalar validation rejects an incorrect exact value before later fields" {
  try @wire.parse_wire_checks(wire_prefix() + b"\x08") catch {
    @wire.WireChecksInvalidValue(field~, offset~, value~, minimum~, maximum~) => {
      assert_eq(field, "wire_checks.version")
      assert_eq(offset, 22)
      assert_eq(value, 8L)
      assert_eq(minimum, 7L)
      assert_eq(maximum, 7L)
    }
    err => raise err
  } noraise {
    _ => fail("accepted an incorrect version")
  }
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

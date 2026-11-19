// Expected values and prefix outcomes from official Kaitai Struct 0.11.
// Inputs, binary samples and Python specifications are pinned in fixtures/kaitai/manifest.json.
// Refresh: python scripts/kaitai-reference.py examples/consumer --refresh-stream-golden

///|
test "Kaitai reference upstream repeat_eos_u4" {
  let frame = @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00\x00\x15\x08\x00\x00")
  assert_eq(frame.numbers.length(), 4)
  assert_eq(frame.numbers[0].to_int64(), 0L)
  assert_eq(frame.numbers[1].to_int64(), 66L)
  assert_eq(frame.numbers[2].to_int64(), 66L)
  assert_eq(frame.numbers[3].to_int64(), 2069L)
}

///|
test "Kaitai reference prefix outcomes repeat_eos_u4" {
  ignore(@repeat_eos_u4.parse_repeat_eos_u4(b""))
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 1") }
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 2") }
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 3") }
  ignore(@repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00"))
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 5") }
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 6") }
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 7") }
  ignore(@repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00\x00\x00"))
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 9") }
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 10") }
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 11") }
  ignore(@repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00\x00"))
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00\x00\x15") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 13") }
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00\x00\x15\x08") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 14") }
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00\x00\x15\x08\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_u4 prefix 15") }
}

///|
test "Kaitai reference upstream repeat_eos_struct" {
  let frame = @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00\x00\x15\x08\x00\x00")
  assert_eq(frame.chunks.length(), 2)
  assert_eq(frame.chunks[0].offset.to_int64(), 0L)
  assert_eq(frame.chunks[0].len.to_int64(), 66L)
  assert_eq(frame.chunks[1].offset.to_int64(), 66L)
  assert_eq(frame.chunks[1].len.to_int64(), 2069L)
}

///|
test "Kaitai reference prefix outcomes repeat_eos_struct" {
  ignore(@repeat_eos_struct.parse_repeat_eos_struct(b""))
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 1") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 2") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 3") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 4") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 5") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 6") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 7") }
  ignore(@repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00\x00\x00"))
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 9") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 10") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 11") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 12") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00\x00\x15") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 13") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00\x00\x15\x08") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 14") }
  try @repeat_eos_struct.parse_repeat_eos_struct(b"\x00\x00\x00\x00\x42\x00\x00\x00\x42\x00\x00\x00\x15\x08\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_struct prefix 15") }
}

///|
test "Kaitai reference upstream repeat_until_s4" {
  let frame = @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF\xFF\xFF\xFF\x66\x6F\x6F\x62\x61\x72\x00")
  assert_eq(frame.entries.length(), 4)
  assert_eq(frame.entries[0].to_int64(), 66L)
  assert_eq(frame.entries[1].to_int64(), 4919L)
  assert_eq(frame.entries[2].to_int64(), -251658241L)
  assert_eq(frame.entries[3].to_int64(), -1L)
  assert_eq(frame.afterall, "foobar")
}

///|
test "Kaitai reference prefix outcomes repeat_until_s4" {
  try @repeat_until_s4.parse_repeat_until_s4(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 0") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 1") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 2") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 3") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 4") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 5") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 6") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 7") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 8") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 9") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 10") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 11") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 12") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 13") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 14") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF\xFF\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 15") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF\xFF\xFF\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 16") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF\xFF\xFF\xFF\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 17") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF\xFF\xFF\xFF\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 18") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF\xFF\xFF\xFF\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 19") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF\xFF\xFF\xFF\x66\x6F\x6F\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 20") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF\xFF\xFF\xFF\x66\x6F\x6F\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 21") }
  try @repeat_until_s4.parse_repeat_until_s4(b"\x42\x00\x00\x00\x37\x13\x00\x00\xFF\xFF\xFF\xF0\xFF\xFF\xFF\xFF\x66\x6F\x6F\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_s4 prefix 22") }
}

///|
test "Kaitai reference upstream repeat_until_sized" {
  let frame = @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55\x55\x55\x55")
  assert_eq(frame.records.length(), 3)
  assert_eq(frame.records[0].marker.to_int64(), 232L)
  assert_eq(frame.records[0].body.to_int64(), 2863311546L)
  assert_eq(frame.records[1].marker.to_int64(), 250L)
  assert_eq(frame.records[1].body.to_int64(), 2863315102L)
  assert_eq(frame.records[2].marker.to_int64(), 170L)
  assert_eq(frame.records[2].body.to_int64(), 1431655765L)
}

///|
test "Kaitai reference prefix outcomes repeat_until_sized" {
  try @repeat_until_sized.parse_repeat_until_sized(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 0") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 1") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 2") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 3") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 4") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 5") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA\xFA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 6") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 7") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 8") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 9") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 10") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 11") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 12") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55\x55") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 13") }
  try @repeat_until_sized.parse_repeat_until_sized(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55\x55\x55") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_sized prefix 14") }
}

///|
test "Kaitai reference upstream repeat_until_complex" {
  let frame = @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04\x00\x00\x00\x66\x6F\x6F\x62\x61\x72\x00")
  assert_eq(frame.first.length(), 3)
  assert_eq(frame.first[0].count.to_int64(), 4L)
  assert_eq(frame.first[0].values.length(), 4)
  assert_eq(frame.first[0].values[0].to_int64(), 1L)
  assert_eq(frame.first[0].values[1].to_int64(), 2L)
  assert_eq(frame.first[0].values[2].to_int64(), 3L)
  assert_eq(frame.first[0].values[3].to_int64(), 4L)
  assert_eq(frame.first[1].count.to_int64(), 2L)
  assert_eq(frame.first[1].values.length(), 2)
  assert_eq(frame.first[1].values[0].to_int64(), 1L)
  assert_eq(frame.first[1].values[1].to_int64(), 2L)
  assert_eq(frame.first[2].count.to_int64(), 0L)
  assert_eq(frame.first[2].values.length(), 0)
  assert_eq(frame.second.length(), 4)
  assert_eq(frame.second[0].count.to_int64(), 6L)
  assert_eq(frame.second[0].values.length(), 6)
  assert_eq(frame.second[0].values[0].to_int64(), 1L)
  assert_eq(frame.second[0].values[1].to_int64(), 2L)
  assert_eq(frame.second[0].values[2].to_int64(), 3L)
  assert_eq(frame.second[0].values[3].to_int64(), 4L)
  assert_eq(frame.second[0].values[4].to_int64(), 5L)
  assert_eq(frame.second[0].values[5].to_int64(), 6L)
  assert_eq(frame.second[1].count.to_int64(), 3L)
  assert_eq(frame.second[1].values.length(), 3)
  assert_eq(frame.second[1].values[0].to_int64(), 1L)
  assert_eq(frame.second[1].values[1].to_int64(), 2L)
  assert_eq(frame.second[1].values[2].to_int64(), 3L)
  assert_eq(frame.second[2].count.to_int64(), 4L)
  assert_eq(frame.second[2].values.length(), 4)
  assert_eq(frame.second[2].values[0].to_int64(), 1L)
  assert_eq(frame.second[2].values[1].to_int64(), 2L)
  assert_eq(frame.second[2].values[2].to_int64(), 3L)
  assert_eq(frame.second[2].values[3].to_int64(), 4L)
  assert_eq(frame.second[3].count.to_int64(), 0L)
  assert_eq(frame.second[3].values.length(), 0)
  assert_eq(frame.third.length(), 7)
  assert_eq(frame.third[0].to_int64(), 102L)
  assert_eq(frame.third[1].to_int64(), 111L)
  assert_eq(frame.third[2].to_int64(), 111L)
  assert_eq(frame.third[3].to_int64(), 98L)
  assert_eq(frame.third[4].to_int64(), 97L)
  assert_eq(frame.third[5].to_int64(), 114L)
  assert_eq(frame.third[6].to_int64(), 0L)
}

///|
test "Kaitai reference prefix outcomes repeat_until_complex" {
  try @repeat_until_complex.parse_repeat_until_complex(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 0") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 1") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 2") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 3") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 4") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 5") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 6") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 7") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 8") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 9") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 10") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 11") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 12") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 13") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 14") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 15") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 16") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 17") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 18") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 19") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 20") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 21") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 22") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 23") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 24") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 25") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 26") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 27") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 28") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 29") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 30") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 31") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 32") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 33") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 34") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 35") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 36") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 37") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 38") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 39") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 40") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 41") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 42") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 43") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04\x00\x00\x00\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 44") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04\x00\x00\x00\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 45") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04\x00\x00\x00\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 46") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04\x00\x00\x00\x66\x6F\x6F\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 47") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04\x00\x00\x00\x66\x6F\x6F\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 48") }
  try @repeat_until_complex.parse_repeat_until_complex(b"\x04\x01\x02\x03\x04\x02\x01\x02\x00\x06\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x03\x00\x01\x00\x02\x00\x03\x00\x04\x00\x01\x00\x02\x00\x03\x00\x04\x00\x00\x00\x66\x6F\x6F\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_until_complex prefix 49") }
}

///|
test "Kaitai reference upstream repeat_eos_bytes" {
  let frame = @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55\x55\x55\x55")
  assert_eq(frame.records.length(), 3)
  assert_eq(frame.records[0].to_owned(), b"\xE8\xBA\xAA\xAA\xAA")
  assert_eq(frame.records[1].to_owned(), b"\xFA\x9E\xB8\xAA\xAA")
  assert_eq(frame.records[2].to_owned(), b"\xAA\x55\x55\x55\x55")
}

///|
test "Kaitai reference prefix outcomes repeat_eos_bytes" {
  ignore(@repeat_eos_bytes.parse_repeat_eos_bytes(b""))
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 1") }
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 2") }
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 3") }
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 4") }
  ignore(@repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA"))
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA\xFA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 6") }
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 7") }
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 8") }
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 9") }
  ignore(@repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA"))
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 11") }
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 12") }
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55\x55") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 13") }
  try @repeat_eos_bytes.parse_repeat_eos_bytes(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55\x55\x55") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes prefix 14") }
}

///|
test "Kaitai reference upstream repeat_eos_bytes_pad_term" {
  let frame = @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55\x55\x55\x55")
  assert_eq(frame.records.length(), 3)
  assert_eq(frame.records[0].to_owned(), b"\xE8\xBA")
  assert_eq(frame.records[1].to_owned(), b"\xFA\x9E\xB8")
  assert_eq(frame.records[2].to_owned(), b"\xAA\x55")
}

///|
test "Kaitai reference prefix outcomes repeat_eos_bytes_pad_term" {
  ignore(@repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b""))
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 1") }
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 2") }
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 3") }
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 4") }
  ignore(@repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA"))
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA\xFA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 6") }
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 7") }
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 8") }
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 9") }
  ignore(@repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA"))
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 11") }
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 12") }
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55\x55") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 13") }
  try @repeat_eos_bytes_pad_term.parse_repeat_eos_bytes_pad_term(b"\xE8\xBA\xAA\xAA\xAA\xFA\x9E\xB8\xAA\xAA\xAA\x55\x55\x55") catch {
    _ => ()
  } noraise { _ => fail("accepted repeat_eos_bytes_pad_term prefix 14") }
}

///|
test "Kaitai reference upstream switch_integers" {
  let frame = @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00\x00\x08\x37\x13\x00\x00\x00\x00\x00\x00")
  assert_eq(frame.opcodes.length(), 4)
  assert_eq(frame.opcodes[0].code.to_int64(), 1L)
  guard frame.opcodes[0].body is Case0(branch_0) else { fail("wrong switch case at frame.opcodes[0].body") }
  assert_eq(branch_0.to_int64(), 7L)
  assert_eq(frame.opcodes[1].code.to_int64(), 2L)
  guard frame.opcodes[1].body is Case1(branch_1) else { fail("wrong switch case at frame.opcodes[1].body") }
  assert_eq(branch_1.to_int64(), 16448L)
  assert_eq(frame.opcodes[2].code.to_int64(), 4L)
  guard frame.opcodes[2].body is Case2(branch_2) else { fail("wrong switch case at frame.opcodes[2].body") }
  assert_eq(branch_2.to_int64(), 4919L)
  assert_eq(frame.opcodes[3].code.to_int64(), 8L)
  guard frame.opcodes[3].body is Case3(branch_3) else { fail("wrong switch case at frame.opcodes[3].body") }
  assert_eq(branch_3, 4919UL)
}

///|
test "Kaitai reference prefix outcomes switch_integers" {
  ignore(@switch_integers.parse_switch_integers(b""))
  try @switch_integers.parse_switch_integers(b"\x01") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 1") }
  ignore(@switch_integers.parse_switch_integers(b"\x01\x07"))
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 3") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 4") }
  ignore(@switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40"))
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 6") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 7") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 8") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 9") }
  ignore(@switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00\x00"))
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00\x00\x08") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 11") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00\x00\x08\x37") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 12") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00\x00\x08\x37\x13") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 13") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00\x00\x08\x37\x13\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 14") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00\x00\x08\x37\x13\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 15") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00\x00\x08\x37\x13\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 16") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00\x00\x08\x37\x13\x00\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 17") }
  try @switch_integers.parse_switch_integers(b"\x01\x07\x02\x40\x40\x04\x37\x13\x00\x00\x08\x37\x13\x00\x00\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_integers prefix 18") }
}

///|
test "Kaitai reference upstream switch_manual_int" {
  let frame = @switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49\x42\x49\x37\x53\x00")
  assert_eq(frame.opcodes.length(), 4)
  assert_eq(frame.opcodes[0].code.to_int64(), 83L)
  guard frame.opcodes[0].body is Case1(branch_0) else { fail("wrong switch case at frame.opcodes[0].body") }
  assert_eq(branch_0.value, "foobar")
  assert_eq(frame.opcodes[1].code.to_int64(), 73L)
  guard frame.opcodes[1].body is Case0(branch_1) else { fail("wrong switch case at frame.opcodes[1].body") }
  assert_eq(branch_1.value.to_int64(), 66L)
  assert_eq(frame.opcodes[2].code.to_int64(), 73L)
  guard frame.opcodes[2].body is Case0(branch_2) else { fail("wrong switch case at frame.opcodes[2].body") }
  assert_eq(branch_2.value.to_int64(), 55L)
  assert_eq(frame.opcodes[3].code.to_int64(), 83L)
  guard frame.opcodes[3].body is Case1(branch_3) else { fail("wrong switch case at frame.opcodes[3].body") }
  assert_eq(branch_3.value, "")
}

///|
test "Kaitai reference prefix outcomes switch_manual_int" {
  ignore(@switch_manual_int.parse_switch_manual_int(b""))
  try @switch_manual_int.parse_switch_manual_int(b"\x53") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int prefix 1") }
  try @switch_manual_int.parse_switch_manual_int(b"\x53\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int prefix 2") }
  try @switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int prefix 3") }
  try @switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int prefix 4") }
  try @switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int prefix 5") }
  try @switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int prefix 6") }
  try @switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int prefix 7") }
  ignore(@switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F\x62\x61\x72\x00"))
  try @switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int prefix 9") }
  ignore(@switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49\x42"))
  try @switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49\x42\x49") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int prefix 11") }
  ignore(@switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49\x42\x49\x37"))
  try @switch_manual_int.parse_switch_manual_int(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49\x42\x49\x37\x53") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int prefix 13") }
}

///|
test "Kaitai reference upstream switch_manual_int_else" {
  let frame = @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA\x00\x00\x49\x07")
  assert_eq(frame.opcodes.length(), 4)
  assert_eq(frame.opcodes[0].code.to_int64(), 83L)
  guard frame.opcodes[0].body is Case1(branch_0) else { fail("wrong switch case at frame.opcodes[0].body") }
  assert_eq(branch_0.value, "foo")
  assert_eq(frame.opcodes[1].code.to_int64(), 88L)
  guard frame.opcodes[1].body is Default(branch_1) else { fail("wrong switch case at frame.opcodes[1].body") }
  assert_eq(branch_1.filler.to_int64(), 66L)
  assert_eq(frame.opcodes[2].code.to_int64(), 89L)
  guard frame.opcodes[2].body is Default(branch_2) else { fail("wrong switch case at frame.opcodes[2].body") }
  assert_eq(branch_2.filler.to_int64(), 51966L)
  assert_eq(frame.opcodes[3].code.to_int64(), 73L)
  guard frame.opcodes[3].body is Case0(branch_3) else { fail("wrong switch case at frame.opcodes[3].body") }
  assert_eq(branch_3.value.to_int64(), 7L)
}

///|
test "Kaitai reference prefix outcomes switch_manual_int_else" {
  ignore(@switch_manual_int_else.parse_switch_manual_int_else(b""))
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 1") }
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 2") }
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 3") }
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 4") }
  ignore(@switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00"))
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 6") }
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 7") }
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 8") }
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 9") }
  ignore(@switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00"))
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 11") }
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 12") }
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 13") }
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 14") }
  ignore(@switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA\x00\x00"))
  try @switch_manual_int_else.parse_switch_manual_int_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA\x00\x00\x49") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_else prefix 16") }
}

///|
test "Kaitai reference upstream switch_manual_int_size" {
  let frame = @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80\xFF\x00\x00\x00\x00")
  assert_eq(frame.chunks.length(), 4)
  assert_eq(frame.chunks[0].code.to_int64(), 17L)
  assert_eq(frame.chunks[0].size.to_int64(), 9L)
  guard frame.chunks[0].body is Case0(branch_0) else { fail("wrong switch case at frame.chunks[0].body") }
  assert_eq(branch_0.title, "Stuff")
  assert_eq(branch_0.author, "Me")
  assert_eq(frame.chunks[1].code.to_int64(), 34L)
  assert_eq(frame.chunks[1].size.to_int64(), 12L)
  guard frame.chunks[1].body is Case1(branch_1) else { fail("wrong switch case at frame.chunks[1].body") }
  assert_eq(branch_1.entries.length(), 3)
  assert_eq(branch_1.entries[0], "AAAA")
  assert_eq(branch_1.entries[1], "BBBB")
  assert_eq(branch_1.entries[2], "CCCC")
  assert_eq(frame.chunks[2].code.to_int64(), 51L)
  assert_eq(frame.chunks[2].size.to_int64(), 8L)
  guard frame.chunks[2].body is Raw(branch_2) else { fail("wrong switch case at frame.chunks[2].body") }
  assert_eq(branch_2.to_owned(), b"\x10\x20\x30\x40\x50\x60\x70\x80")
  assert_eq(frame.chunks[3].code.to_int64(), 255L)
  assert_eq(frame.chunks[3].size.to_int64(), 0L)
  guard frame.chunks[3].body is Raw(branch_3) else { fail("wrong switch case at frame.chunks[3].body") }
  assert_eq(branch_3.to_owned(), b"")
}

///|
test "Kaitai reference prefix outcomes switch_manual_int_size" {
  ignore(@switch_manual_int_size.parse_switch_manual_int_size(b""))
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 1") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 2") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 3") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 4") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 5") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 6") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 7") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 8") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 9") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 10") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 11") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 12") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 13") }
  ignore(@switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00"))
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 15") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 16") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 17") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 18") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 19") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 20") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 21") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 22") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 23") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 24") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 25") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 26") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 27") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 28") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 29") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 30") }
  ignore(@switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43"))
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 32") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 33") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 34") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 35") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 36") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 37") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 38") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 39") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 40") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 41") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 42") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 43") }
  ignore(@switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80"))
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 45") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80\xFF\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 46") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80\xFF\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 47") }
  try @switch_manual_int_size.parse_switch_manual_int_size(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80\xFF\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size prefix 48") }
}

///|
test "Kaitai reference upstream switch_manual_int_size_else" {
  let frame = @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80\xFF\x00\x00\x00\x00")
  assert_eq(frame.chunks.length(), 4)
  assert_eq(frame.chunks[0].code.to_int64(), 17L)
  assert_eq(frame.chunks[0].size.to_int64(), 9L)
  guard frame.chunks[0].body is Case0(branch_0) else { fail("wrong switch case at frame.chunks[0].body") }
  assert_eq(branch_0.title, "Stuff")
  assert_eq(branch_0.author, "Me")
  assert_eq(frame.chunks[1].code.to_int64(), 34L)
  assert_eq(frame.chunks[1].size.to_int64(), 12L)
  guard frame.chunks[1].body is Case1(branch_1) else { fail("wrong switch case at frame.chunks[1].body") }
  assert_eq(branch_1.entries.length(), 3)
  assert_eq(branch_1.entries[0], "AAAA")
  assert_eq(branch_1.entries[1], "BBBB")
  assert_eq(branch_1.entries[2], "CCCC")
  assert_eq(frame.chunks[2].code.to_int64(), 51L)
  assert_eq(frame.chunks[2].size.to_int64(), 8L)
  guard frame.chunks[2].body is Default(branch_2) else { fail("wrong switch case at frame.chunks[2].body") }
  assert_eq(branch_2.rest.to_owned(), b"\x10\x20\x30\x40\x50\x60\x70\x80")
  assert_eq(frame.chunks[3].code.to_int64(), 255L)
  assert_eq(frame.chunks[3].size.to_int64(), 0L)
  guard frame.chunks[3].body is Default(branch_3) else { fail("wrong switch case at frame.chunks[3].body") }
  assert_eq(branch_3.rest.to_owned(), b"")
}

///|
test "Kaitai reference prefix outcomes switch_manual_int_size_else" {
  ignore(@switch_manual_int_size_else.parse_switch_manual_int_size_else(b""))
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 1") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 2") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 3") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 4") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 5") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 6") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 7") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 8") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 9") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 10") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 11") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 12") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 13") }
  ignore(@switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00"))
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 15") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 16") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 17") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 18") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 19") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 20") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 21") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 22") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 23") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 24") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 25") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 26") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 27") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 28") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 29") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 30") }
  ignore(@switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43"))
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 32") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 33") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 34") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 35") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 36") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 37") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 38") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 39") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 40") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 41") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 42") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 43") }
  ignore(@switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80"))
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 45") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80\xFF\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 46") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80\xFF\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 47") }
  try @switch_manual_int_size_else.parse_switch_manual_int_size_else(b"\x11\x09\x00\x00\x00\x53\x74\x75\x66\x66\x00\x4D\x65\x00\x22\x0C\x00\x00\x00\x41\x41\x41\x41\x42\x42\x42\x42\x43\x43\x43\x43\x33\x08\x00\x00\x00\x10\x20\x30\x40\x50\x60\x70\x80\xFF\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_int_size_else prefix 48") }
}

///|
test "Kaitai reference upstream switch_manual_str" {
  let frame = @switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49\x42\x49\x37\x53\x00")
  assert_eq(frame.opcodes.length(), 4)
  assert_eq(frame.opcodes[0].code, "S")
  guard frame.opcodes[0].body is Case1(branch_0) else { fail("wrong switch case at frame.opcodes[0].body") }
  assert_eq(branch_0.value, "foobar")
  assert_eq(frame.opcodes[1].code, "I")
  guard frame.opcodes[1].body is Case0(branch_1) else { fail("wrong switch case at frame.opcodes[1].body") }
  assert_eq(branch_1.value.to_int64(), 66L)
  assert_eq(frame.opcodes[2].code, "I")
  guard frame.opcodes[2].body is Case0(branch_2) else { fail("wrong switch case at frame.opcodes[2].body") }
  assert_eq(branch_2.value.to_int64(), 55L)
  assert_eq(frame.opcodes[3].code, "S")
  guard frame.opcodes[3].body is Case1(branch_3) else { fail("wrong switch case at frame.opcodes[3].body") }
  assert_eq(branch_3.value, "")
}

///|
test "Kaitai reference prefix outcomes switch_manual_str" {
  ignore(@switch_manual_str.parse_switch_manual_str(b""))
  try @switch_manual_str.parse_switch_manual_str(b"\x53") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str prefix 1") }
  try @switch_manual_str.parse_switch_manual_str(b"\x53\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str prefix 2") }
  try @switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str prefix 3") }
  try @switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str prefix 4") }
  try @switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str prefix 5") }
  try @switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str prefix 6") }
  try @switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str prefix 7") }
  ignore(@switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F\x62\x61\x72\x00"))
  try @switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str prefix 9") }
  ignore(@switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49\x42"))
  try @switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49\x42\x49") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str prefix 11") }
  ignore(@switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49\x42\x49\x37"))
  try @switch_manual_str.parse_switch_manual_str(b"\x53\x66\x6F\x6F\x62\x61\x72\x00\x49\x42\x49\x37\x53") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str prefix 13") }
}

///|
test "Kaitai reference upstream switch_manual_str_else" {
  let frame = @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA\x00\x00\x49\x07")
  assert_eq(frame.opcodes.length(), 4)
  assert_eq(frame.opcodes[0].code, "S")
  guard frame.opcodes[0].body is Case1(branch_0) else { fail("wrong switch case at frame.opcodes[0].body") }
  assert_eq(branch_0.value, "foo")
  assert_eq(frame.opcodes[1].code, "X")
  guard frame.opcodes[1].body is Default(branch_1) else { fail("wrong switch case at frame.opcodes[1].body") }
  assert_eq(branch_1.filler.to_int64(), 66L)
  assert_eq(frame.opcodes[2].code, "Y")
  guard frame.opcodes[2].body is Default(branch_2) else { fail("wrong switch case at frame.opcodes[2].body") }
  assert_eq(branch_2.filler.to_int64(), 51966L)
  assert_eq(frame.opcodes[3].code, "I")
  guard frame.opcodes[3].body is Case0(branch_3) else { fail("wrong switch case at frame.opcodes[3].body") }
  assert_eq(branch_3.value.to_int64(), 7L)
}

///|
test "Kaitai reference prefix outcomes switch_manual_str_else" {
  ignore(@switch_manual_str_else.parse_switch_manual_str_else(b""))
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 1") }
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 2") }
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 3") }
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 4") }
  ignore(@switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00"))
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 6") }
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 7") }
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 8") }
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 9") }
  ignore(@switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00"))
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 11") }
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 12") }
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 13") }
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 14") }
  ignore(@switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA\x00\x00"))
  try @switch_manual_str_else.parse_switch_manual_str_else(b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA\x00\x00\x49") catch {
    _ => ()
  } noraise { _ => fail("accepted switch_manual_str_else prefix 16") }
}

///|
test "Kaitai reference upstream str_eos" {
  let frame = @str_eos.parse_str_eos(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61\x7A\x40")
  assert_eq(frame.str, "foo|bar|baz@")
}

///|
test "Kaitai reference prefix outcomes str_eos" {
  ignore(@str_eos.parse_str_eos(b""))
  ignore(@str_eos.parse_str_eos(b"\x66"))
  ignore(@str_eos.parse_str_eos(b"\x66\x6F"))
  ignore(@str_eos.parse_str_eos(b"\x66\x6F\x6F"))
  ignore(@str_eos.parse_str_eos(b"\x66\x6F\x6F\x7C"))
  ignore(@str_eos.parse_str_eos(b"\x66\x6F\x6F\x7C\x62"))
  ignore(@str_eos.parse_str_eos(b"\x66\x6F\x6F\x7C\x62\x61"))
  ignore(@str_eos.parse_str_eos(b"\x66\x6F\x6F\x7C\x62\x61\x72"))
  ignore(@str_eos.parse_str_eos(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C"))
  ignore(@str_eos.parse_str_eos(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62"))
  ignore(@str_eos.parse_str_eos(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61"))
  ignore(@str_eos.parse_str_eos(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61\x7A"))
}

///|
test "Kaitai reference upstream str_pad_term" {
  let frame = @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E")
  assert_eq(frame.str_pad, "str1")
  assert_eq(frame.str_term, "str2foo")
  assert_eq(frame.str_term_and_pad, "str+++3bar+++")
  assert_eq(frame.str_term_include, "str4baz@")
}

///|
test "Kaitai reference prefix outcomes str_pad_term" {
  try @str_pad_term.parse_str_pad_term(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 0") }
  try @str_pad_term.parse_str_pad_term(b"\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 1") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 2") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 3") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 4") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 5") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 6") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 7") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 8") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 9") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 10") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 11") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 12") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 13") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 14") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 15") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 16") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 17") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 18") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 19") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 20") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 21") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 22") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 23") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 24") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 25") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 26") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 27") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 28") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 29") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 30") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 31") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 32") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 33") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 34") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 35") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 36") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 37") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 38") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 39") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 40") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 41") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 42") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 43") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 44") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 45") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 46") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 47") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 48") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 49") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 50") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 51") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 52") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 53") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 54") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 55") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 56") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 57") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 58") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 59") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 60") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 61") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 62") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 63") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 64") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 65") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 66") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 67") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 68") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 69") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 70") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 71") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 72") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 73") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 74") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 75") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 76") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 77") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 78") }
  try @str_pad_term.parse_str_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term prefix 79") }
}

///|
test "Kaitai reference upstream str_pad_term_empty" {
  let frame = @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E")
  assert_eq(frame.str_pad, "")
  assert_eq(frame.str_term, "")
  assert_eq(frame.str_term_and_pad, "")
  assert_eq(frame.str_term_include, "@")
}

///|
test "Kaitai reference prefix outcomes str_pad_term_empty" {
  try @str_pad_term_empty.parse_str_pad_term_empty(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 0") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 1") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 2") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 3") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 4") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 5") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 6") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 7") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 8") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 9") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 10") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 11") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 12") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 13") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 14") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 15") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 16") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 17") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 18") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 19") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 20") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 21") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 22") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 23") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 24") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 25") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 26") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 27") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 28") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 29") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 30") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 31") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 32") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 33") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 34") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 35") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 36") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 37") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 38") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 39") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 40") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 41") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 42") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 43") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 44") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 45") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 46") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 47") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 48") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 49") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 50") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 51") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 52") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 53") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 54") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 55") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 56") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 57") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 58") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 59") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 60") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 61") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 62") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 63") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 64") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 65") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 66") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 67") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 68") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 69") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 70") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 71") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 72") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 73") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 74") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 75") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 76") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 77") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 78") }
  try @str_pad_term_empty.parse_str_pad_term_empty(b"\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x40\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x40\x40\x40\x40\x40\x40\x40\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_empty prefix 79") }
}

///|
test "Kaitai reference upstream str_pad_term_equal" {
  let frame = @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E")
  assert_eq(frame.s1, "str1")
  assert_eq(frame.s2, "str2foo@")
  assert_eq(frame.s3, "str")
  assert_eq(frame.s4, "str4baz@.")
}

///|
test "Kaitai reference prefix outcomes str_pad_term_equal" {
  try @str_pad_term_equal.parse_str_pad_term_equal(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 0") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 1") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 2") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 3") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 4") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 5") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 6") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 7") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 8") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 9") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 10") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 11") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 12") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 13") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 14") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 15") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 16") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 17") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 18") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 19") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 20") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 21") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 22") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 23") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 24") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 25") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 26") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 27") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 28") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 29") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 30") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 31") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 32") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 33") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 34") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 35") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 36") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 37") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 38") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 39") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 40") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 41") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 42") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 43") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 44") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 45") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 46") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 47") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 48") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 49") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 50") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 51") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 52") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 53") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 54") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 55") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 56") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 57") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 58") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 59") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 60") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 61") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 62") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 63") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 64") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 65") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 66") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 67") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 68") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 69") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 70") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 71") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 72") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 73") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 74") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 75") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 76") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 77") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 78") }
  try @str_pad_term_equal.parse_str_pad_term_equal(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_equal prefix 79") }
}

///|
test "Kaitai reference upstream str_pad_term_zero_size" {
  let frame = @str_pad_term_zero_size.parse_str_pad_term_zero_size(b"\xFF\x01")
  assert_eq(frame.str_pad, "")
  assert_eq(frame.str_term, "")
  assert_eq(frame.str_term_and_pad, "")
  assert_eq(frame.str_term_include, "")
}

///|
test "Kaitai reference prefix outcomes str_pad_term_zero_size" {
  ignore(@str_pad_term_zero_size.parse_str_pad_term_zero_size(b""))
  ignore(@str_pad_term_zero_size.parse_str_pad_term_zero_size(b"\xFF"))
}

///|
test "Kaitai reference upstream str_eos_pad_term" {
  let frame = @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E")
  assert_eq(frame.str_pad.value, "str1")
  assert_eq(frame.str_term.value, "str2foo")
  assert_eq(frame.str_term_and_pad.value, "str+++3bar+++")
  assert_eq(frame.str_term_include.value, "str4baz@")
}

///|
test "Kaitai reference prefix outcomes str_eos_pad_term" {
  try @str_eos_pad_term.parse_str_eos_pad_term(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 0") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 1") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 2") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 3") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 4") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 5") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 6") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 7") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 8") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 9") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 10") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 11") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 12") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 13") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 14") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 15") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 16") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 17") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 18") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 19") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 20") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 21") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 22") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 23") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 24") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 25") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 26") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 27") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 28") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 29") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 30") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 31") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 32") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 33") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 34") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 35") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 36") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 37") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 38") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 39") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 40") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 41") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 42") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 43") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 44") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 45") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 46") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 47") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 48") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 49") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 50") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 51") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 52") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 53") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 54") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 55") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 56") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 57") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 58") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 59") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 60") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 61") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 62") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 63") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 64") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 65") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 66") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 67") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 68") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 69") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 70") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 71") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 72") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 73") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 74") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 75") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 76") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 77") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 78") }
  try @str_eos_pad_term.parse_str_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted str_eos_pad_term prefix 79") }
}

///|
test "Kaitai reference upstream term_strz" {
  let frame = @term_strz.parse_term_strz(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61\x7A\x40")
  assert_eq(frame.s1, "foo")
  assert_eq(frame.s2, "bar")
  assert_eq(frame.s3, "|baz@")
}

///|
test "Kaitai reference prefix outcomes term_strz" {
  try @term_strz.parse_term_strz(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 0") }
  try @term_strz.parse_term_strz(b"\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 1") }
  try @term_strz.parse_term_strz(b"\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 2") }
  try @term_strz.parse_term_strz(b"\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 3") }
  try @term_strz.parse_term_strz(b"\x66\x6F\x6F\x7C") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 4") }
  try @term_strz.parse_term_strz(b"\x66\x6F\x6F\x7C\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 5") }
  try @term_strz.parse_term_strz(b"\x66\x6F\x6F\x7C\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 6") }
  try @term_strz.parse_term_strz(b"\x66\x6F\x6F\x7C\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 7") }
  try @term_strz.parse_term_strz(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 8") }
  try @term_strz.parse_term_strz(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 9") }
  try @term_strz.parse_term_strz(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 10") }
  try @term_strz.parse_term_strz(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61\x7A") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz prefix 11") }
}

///|
test "Kaitai reference upstream term_strz2" {
  let frame = @term_strz2.parse_term_strz2(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61\x7A\x40")
  assert_eq(frame.s1, "foo")
  assert_eq(frame.s2, "bar|")
  assert_eq(frame.s3, "baz")
}

///|
test "Kaitai reference prefix outcomes term_strz2" {
  try @term_strz2.parse_term_strz2(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 0") }
  try @term_strz2.parse_term_strz2(b"\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 1") }
  try @term_strz2.parse_term_strz2(b"\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 2") }
  try @term_strz2.parse_term_strz2(b"\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 3") }
  try @term_strz2.parse_term_strz2(b"\x66\x6F\x6F\x7C") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 4") }
  try @term_strz2.parse_term_strz2(b"\x66\x6F\x6F\x7C\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 5") }
  try @term_strz2.parse_term_strz2(b"\x66\x6F\x6F\x7C\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 6") }
  try @term_strz2.parse_term_strz2(b"\x66\x6F\x6F\x7C\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 7") }
  try @term_strz2.parse_term_strz2(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 8") }
  try @term_strz2.parse_term_strz2(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 9") }
  try @term_strz2.parse_term_strz2(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 10") }
  try @term_strz2.parse_term_strz2(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61\x7A") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz2 prefix 11") }
}

///|
test "Kaitai reference upstream term_strz3" {
  let frame = @term_strz3.parse_term_strz3(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61\x7A\x40")
  assert_eq(frame.s1, "foo")
  assert_eq(frame.s2, "|bar|baz")
  assert_eq(frame.s3, "")
}

///|
test "Kaitai reference prefix outcomes term_strz3" {
  try @term_strz3.parse_term_strz3(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 0") }
  try @term_strz3.parse_term_strz3(b"\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 1") }
  try @term_strz3.parse_term_strz3(b"\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 2") }
  try @term_strz3.parse_term_strz3(b"\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 3") }
  try @term_strz3.parse_term_strz3(b"\x66\x6F\x6F\x7C") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 4") }
  try @term_strz3.parse_term_strz3(b"\x66\x6F\x6F\x7C\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 5") }
  try @term_strz3.parse_term_strz3(b"\x66\x6F\x6F\x7C\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 6") }
  try @term_strz3.parse_term_strz3(b"\x66\x6F\x6F\x7C\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 7") }
  try @term_strz3.parse_term_strz3(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 8") }
  try @term_strz3.parse_term_strz3(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 9") }
  try @term_strz3.parse_term_strz3(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 10") }
  try @term_strz3.parse_term_strz3(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61\x7A") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz3 prefix 11") }
}

///|
test "Kaitai reference upstream term_strz4" {
  let frame = @term_strz4.parse_term_strz4(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61\x7A\x40")
  assert_eq(frame.s1.value, "foo")
  assert_eq(frame.skip_term1.to_int64(), 124L)
  assert_eq(frame.s2.value, "bar")
  assert_eq(frame.skip_term2.to_int64(), 124L)
  assert_eq(frame.s3.value, "baz")
}

///|
test "Kaitai reference prefix outcomes term_strz4" {
  try @term_strz4.parse_term_strz4(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 0") }
  try @term_strz4.parse_term_strz4(b"\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 1") }
  try @term_strz4.parse_term_strz4(b"\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 2") }
  try @term_strz4.parse_term_strz4(b"\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 3") }
  try @term_strz4.parse_term_strz4(b"\x66\x6F\x6F\x7C") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 4") }
  try @term_strz4.parse_term_strz4(b"\x66\x6F\x6F\x7C\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 5") }
  try @term_strz4.parse_term_strz4(b"\x66\x6F\x6F\x7C\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 6") }
  try @term_strz4.parse_term_strz4(b"\x66\x6F\x6F\x7C\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 7") }
  try @term_strz4.parse_term_strz4(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 8") }
  try @term_strz4.parse_term_strz4(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 9") }
  try @term_strz4.parse_term_strz4(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz4 prefix 10") }
  ignore(@term_strz4.parse_term_strz4(b"\x66\x6F\x6F\x7C\x62\x61\x72\x7C\x62\x61\x7A"))
}

///|
test "Kaitai reference upstream bytes_eos_pad_term" {
  let frame = @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E")
  assert_eq(frame.str_pad.value.to_owned(), b"\x73\x74\x72\x31")
  assert_eq(frame.str_term.value.to_owned(), b"\x73\x74\x72\x32\x66\x6F\x6F")
  assert_eq(frame.str_term_and_pad.value.to_owned(), b"\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B")
  assert_eq(frame.str_term_include.value.to_owned(), b"\x73\x74\x72\x34\x62\x61\x7A\x40")
}

///|
test "Kaitai reference prefix outcomes bytes_eos_pad_term" {
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 0") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 1") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 2") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 3") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 4") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 5") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 6") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 7") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 8") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 9") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 10") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 11") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 12") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 13") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 14") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 15") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 16") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 17") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 18") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 19") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 20") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 21") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 22") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 23") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 24") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 25") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 26") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 27") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 28") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 29") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 30") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 31") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 32") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 33") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 34") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 35") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 36") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 37") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 38") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 39") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 40") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 41") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 42") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 43") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 44") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 45") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 46") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 47") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 48") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 49") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 50") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 51") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 52") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 53") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 54") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 55") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 56") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 57") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 58") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 59") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 60") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 61") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 62") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 63") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 64") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 65") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 66") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 67") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 68") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 69") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 70") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 71") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 72") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 73") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 74") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 75") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 76") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 77") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 78") }
  try @bytes_eos_pad_term.parse_bytes_eos_pad_term(b"\x73\x74\x72\x31\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x40\x73\x74\x72\x32\x66\x6F\x6F\x40\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x2B\x2B\x2B\x33\x62\x61\x72\x2B\x2B\x2B\x40\x2B\x2B\x2B\x2B\x2B\x2B\x73\x74\x72\x34\x62\x61\x7A\x40\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E\x2E") catch {
    _ => ()
  } noraise { _ => fail("accepted bytes_eos_pad_term prefix 79") }
}

///|
test "Kaitai reference upstream term_strz_utf16_v1" {
  let frame = @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00\x00\x00")
  assert_eq(frame.s1, "aȀb")
  assert_eq(frame.s2, "cȀd")
  assert_eq(frame.term.to_int64(), 0L)
  assert_eq(frame.s3, "eȀf\u0000")
}

///|
test "Kaitai reference prefix outcomes term_strz_utf16_v1" {
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 0") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 1") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 2") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 3") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 4") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 5") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 6") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 7") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 8") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 9") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 10") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 11") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 12") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 13") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 14") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 15") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 16") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 17") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 18") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 19") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 20") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 21") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 22") }
  try @term_strz_utf16_v1.parse_term_strz_utf16_v1(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v1 prefix 23") }
}

///|
test "Kaitai reference upstream term_strz_utf16_v2" {
  let frame = @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00\x00\x00")
  assert_eq(frame.s1, "aȀb")
  assert_eq(frame.s2, "cȀd\u0000")
  assert_eq(frame.s3, "eȀf")
}

///|
test "Kaitai reference prefix outcomes term_strz_utf16_v2" {
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 0") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 1") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 2") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 3") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 4") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 5") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 6") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 7") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 8") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 9") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 10") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 11") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 12") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 13") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 14") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 15") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 16") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 17") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 18") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 19") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 20") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 21") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 22") }
  try @term_strz_utf16_v2.parse_term_strz_utf16_v2(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v2 prefix 23") }
}

///|
test "Kaitai reference upstream term_strz_utf16_v3" {
  let frame = @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00\x00\x00")
  assert_eq(frame.s1, "aȀb")
  assert_eq(frame.term.to_int64(), 0L)
  assert_eq(frame.s2, "cȀd")
  assert_eq(frame.s3, "")
}

///|
test "Kaitai reference prefix outcomes term_strz_utf16_v3" {
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 0") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 1") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 2") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 3") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 4") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 5") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 6") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 7") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 8") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 9") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 10") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 11") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 12") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 13") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 14") }
  try @term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v3 prefix 15") }
  ignore(@term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00"))
  ignore(@term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65"))
  ignore(@term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00"))
  ignore(@term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00"))
  ignore(@term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02"))
  ignore(@term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66"))
  ignore(@term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00"))
  ignore(@term_strz_utf16_v3.parse_term_strz_utf16_v3(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00\x00"))
}

///|
test "Kaitai reference upstream term_strz_utf16_v4" {
  let frame = @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00\x00\x00")
  assert_eq(frame.s1.value, "aȀb")
  assert_eq(frame.skip_term1.to_owned(), b"\x00\x00")
  assert_eq(frame.s2.value, "cȀd")
  assert_eq(frame.skip_term2.to_owned(), b"\x00\x00")
  assert_eq(frame.s3.value, "eȀf")
}

///|
test "Kaitai reference prefix outcomes term_strz_utf16_v4" {
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 0") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 1") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 2") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 3") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 4") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 5") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 6") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 7") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 8") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 9") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 10") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 11") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 12") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 13") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 14") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 15") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 16") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 17") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 18") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 19") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 20") }
  try @term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted term_strz_utf16_v4 prefix 21") }
  ignore(@term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00"))
  ignore(@term_strz_utf16_v4.parse_term_strz_utf16_v4(b"\x61\x00\x00\x02\x62\x00\x00\x00\x63\x00\x00\x02\x64\x00\x00\x00\x65\x00\x00\x02\x66\x00\x00"))
}

///|
test "Kaitai reference upstream str_pad_term_utf16" {
  let frame = @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0\xD8\x65\x00\x00\x02\x66\x00\x2B\x2B\x2B")
  assert_eq(frame.str_term, "aȀb")
  assert_eq(frame.str_term_include, "cȀd\u0000")
  assert_eq(frame.str_term_and_pad, "eȀf")
}

///|
test "Kaitai reference prefix outcomes str_pad_term_utf16" {
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 0") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 1") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 2") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 3") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 4") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 5") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 6") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 7") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 8") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 9") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 10") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 11") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 12") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 13") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 14") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 15") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 16") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 17") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 18") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 19") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0\xD8") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 20") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0\xD8\x65") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 21") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0\xD8\x65\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 22") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0\xD8\x65\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 23") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0\xD8\x65\x00\x00\x02") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 24") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0\xD8\x65\x00\x00\x02\x66") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 25") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0\xD8\x65\x00\x00\x02\x66\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 26") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0\xD8\x65\x00\x00\x02\x66\x00\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 27") }
  try @str_pad_term_utf16.parse_str_pad_term_utf16(b"\x61\x00\x00\x02\x62\x00\x00\x00\xC0\xD8\x63\x00\x00\x02\x64\x00\x00\x00\xC0\xD8\x65\x00\x00\x02\x66\x00\x2B\x2B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_pad_term_utf16 prefix 28") }
}

///|
test "Kaitai reference upstream str_encodings_utf16" {
  let frame = @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x30")
  assert_eq(frame.len_be.to_int64(), 12L)
  assert_eq(frame.be_bom_removed.bom.to_int64(), 65279L)
  assert_eq(frame.be_bom_removed.str, "こんにちは")
  assert_eq(frame.len_le.to_int64(), 12L)
  assert_eq(frame.le_bom_removed.bom.to_int64(), 65279L)
  assert_eq(frame.le_bom_removed.str, "こんにちは")
}

///|
test "Kaitai reference prefix outcomes str_encodings_utf16" {
  try @str_encodings_utf16.parse_str_encodings_utf16(b"") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 0") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 1") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 2") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 3") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 4") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 5") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 6") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 7") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 8") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 9") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 10") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 11") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 12") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 13") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 14") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 15") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 16") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 17") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 18") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 19") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 20") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 21") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 22") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE\x53") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 23") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE\x53\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 24") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE\x53\x30\x93") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 25") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE\x53\x30\x93\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 26") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE\x53\x30\x93\x30\x6B") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 27") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE\x53\x30\x93\x30\x6B\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 28") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE\x53\x30\x93\x30\x6B\x30\x61") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 29") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE\x53\x30\x93\x30\x6B\x30\x61\x30") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 30") }
  try @str_encodings_utf16.parse_str_encodings_utf16(b"\x0C\x00\x00\x00\xFE\xFF\x30\x53\x30\x93\x30\x6B\x30\x61\x30\x6F\x0C\x00\x00\x00\xFF\xFE\x53\x30\x93\x30\x6B\x30\x61\x30\x6F") catch {
    _ => ()
  } noraise { _ => fail("accepted str_encodings_utf16 prefix 31") }
}

///|
test "Kaitai reference bounded stream tag 1" {
  let frame = @stream_control.parse_stream_control(b"\xAA\x10\x20\x30\x40\x55\x01\x78\x56\x34\x12\x41\x00\x42\x00\x6F\x6E\x65\x00\x74\x77\x6F\x00")
  assert_eq(frame.block.at_zero(), 16U)
  assert_eq(frame.block.at_end(), 64U)
  assert_eq(frame.block.cursor(), 1L)
  assert_eq(frame.block.stream_size(), 4L)
  assert_eq(frame.tail, 85U)
  assert_eq(frame.unicode, "AB")
  assert_eq(frame.lines, ["one", "two"])
  assert_eq(frame.empty_steps.length(), 2)
  guard frame.choice is Case0(word) else { fail("word switch") }
  assert_eq(word.value, 305419896U)
}

///|
test "Kaitai reference bounded stream tag 2" {
  let frame = @stream_control.parse_stream_control(b"\xAA\x10\x20\x30\x40\x55\x02\x48\x69\x00\x21\x41\x00\x42\x00\x6F\x6E\x65\x00\x74\x77\x6F\x00")
  assert_eq(frame.block.at_zero(), 16U)
  assert_eq(frame.block.at_end(), 64U)
  assert_eq(frame.block.cursor(), 1L)
  assert_eq(frame.block.stream_size(), 4L)
  assert_eq(frame.tail, 85U)
  assert_eq(frame.unicode, "AB")
  assert_eq(frame.lines, ["one", "two"])
  assert_eq(frame.empty_steps.length(), 2)
  guard frame.choice is Case1(message) else { fail("string switch") }
  assert_eq(message.value, "Hi")
}

///|
test "Kaitai reference bounded stream tag 99" {
  let frame = @stream_control.parse_stream_control(b"\xAA\x10\x20\x30\x40\x55\x63\x52\x41\x57\x21\x41\x00\x42\x00\x6F\x6E\x65\x00\x74\x77\x6F\x00")
  assert_eq(frame.block.at_zero(), 16U)
  assert_eq(frame.block.at_end(), 64U)
  assert_eq(frame.block.cursor(), 1L)
  assert_eq(frame.block.stream_size(), 4L)
  assert_eq(frame.tail, 85U)
  assert_eq(frame.unicode, "AB")
  assert_eq(frame.lines, ["one", "two"])
  assert_eq(frame.empty_steps.length(), 2)
  guard frame.choice is Raw(raw) else { fail("raw switch") }
  assert_eq(raw.to_owned(), b"\x52\x41\x57\x21")
}

///|
test "Kaitai reference negative sized byte options" {
  let frame = @reader_edges.parse_reader_edges(b"\x00\x41\x00")
  assert_true(frame.conditional_text() is None)
  try frame.sized_text() catch { _ => () } noraise { _ => fail("negative terminated size") }
  try frame.padded_bytes() catch { _ => () } noraise { _ => fail("negative padded size") }
}

///|
test "Kaitai reference explicit UTF16 byte terminators" {
  let frame = @reader_edges.parse_reader_edges(b"\x00\x41\x00\x7C\x00\x42\x00")
  assert_eq(frame.explicit_text(), "A")
  assert_eq(frame.explicit_strz(), "A")
  assert_eq(frame.explicit_sized(), "A")
  assert_eq(frame.unpositioned(), "A")
  assert_eq(frame.following().to_owned(), b"\x00\x42\x00")
}

///|
test "Kaitai reference implicit UTF16 double byte terminator" {
  let frame = @reader_edges.parse_reader_edges(b"\x00\x41\x00\x42\x00\x00\x00\x52\x45\x53\x54")
  assert_eq(frame.implicit_strz(), "AB")
}

///|
test "Kaitai reference pure nested value record" {
  let frame = @pure_nested_value.parse_pure_nested_value(b"")
  assert_eq(frame.header.number(), 42L)
  assert_eq(frame.header.label(), "ok")
}

///|
test "Kaitai reference pure stream input length 0" {
  let frame = @pure_stream_value.parse_pure_stream_value(b"")
  assert_eq(frame.peek().number(), 42L)
  assert_eq(frame.peek().stream_size(), 0L)
  assert_true(frame.header is None)
}

///|
test "Kaitai reference pure stream input length 3" {
  let frame = @pure_stream_value.parse_pure_stream_value(b"\x41\x42\x43")
  assert_eq(frame.peek().number(), 42L)
  assert_eq(frame.peek().stream_size(), 3L)
  assert_eq(frame.header.unwrap().stream_size(), 3L)
}

///|
test "Kaitai reference pure repeated and default branch records" {
  let frame = @pure_repeated_value.parse_pure_repeated_value(b"")
  assert_eq(frame.headers.length(), 2)
  assert_eq(frame.headers[0].number(), 42L)
  assert_eq(frame.single().number(), 42L)
  guard frame.choice() is Default(header)
  assert_eq(header.number(), 42L)
}

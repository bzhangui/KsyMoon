///|
fn stream_sample() -> Bytes {
  b"\xaa\x10\x20\x30\x40\x55\x01\x78\x56\x34\x12A\x00B\x00one\x00two\x00"
}

///|
test "bounded child instances cannot escape into the parent stream" {
  let frame = @stream_control.parse_stream_control(stream_sample())
  assert_eq(frame.block.at_zero(), 16U)
  assert_eq(frame.block.at_end(), 64U)
  for _ in 0..<2 {
    try frame.block.outside() catch {
      @stream_control.StreamControlTruncated(
        field~,
        offset~,
        needed~,
        remaining~
      ) => {
        assert_eq(field, "stream_control.block.outside")
        assert_eq(offset, 4)
        assert_eq(needed, 1L)
        assert_eq(remaining, 0)
      }
      _ => fail("unexpected parse error variant")
    } noraise {
      _ => fail("child escaped its stream")
    }
  }
  assert_eq(frame.block.cursor(), 1L)
  assert_eq(frame.block.stream_size(), 4L)
  assert_eq(frame.tail, 85U)
  assert_eq(frame.lines, ["one", "two"])
}

///|
test "bounded read rejects truncation before reading a child" {
  try @stream_control.parse_stream_control(b"\xaa\x10\x20\x30") catch {
    @stream_control.StreamControlTruncated(field~, offset~, needed~, remaining~) => {
      assert_eq(field, "stream_control.block")
      assert_eq(offset, 1)
      assert_eq(needed, 4L)
      assert_eq(remaining, 3)
    }
    _ => fail("unexpected parse error variant")
  } noraise {
    _ => fail("accepted truncated block")
  }
}

///|
test "until includes the sentinel and fails without it" {
  let parsed = @repeat_until_s4.parse_repeat_until_s4(
    b"\x01\x00\x00\x00\xff\xff\xff\xffOK\x00",
  )
  assert_eq(parsed.entries, [1, -1])
  assert_eq(parsed.afterall, "OK")
  try @repeat_until_s4.parse_repeat_until_s4(b"\x01\x00\x00\x00") catch {
    @repeat_until_s4.RepeatUntilS4Truncated(field~, offset~, ..) => {
      assert_eq(field, "repeat_until_s4.entries[1]")
      assert_eq(offset, 4)
    }
    _ => fail("unexpected parse error variant")
  } noraise {
    _ => fail("accepted missing until sentinel")
  }
}

///|
test "eos supports empty streams and rejects a partial last item" {
  assert_eq(@repeat_eos_u4.parse_repeat_eos_u4(b"").numbers.length(), 0)
  try @repeat_eos_u4.parse_repeat_eos_u4(b"\x01\x00\x00\x00\xff") catch {
    @repeat_eos_u4.RepeatEosU4Truncated(field~, offset~, remaining~, ..) => {
      assert_eq(field, "repeat_eos_u4.numbers[1]")
      assert_eq(offset, 4)
      assert_eq(remaining, 1)
    }
    _ => fail("unexpected parse error variant")
  } noraise {
    _ => fail("accepted partial eos item")
  }
}

///|
test "eos detects a zero byte iteration instead of looping" {
  assert_eq(
    @repeat_zero_progress.parse_repeat_zero_progress(b"").values.length(),
    0,
  )
  try @repeat_zero_progress.parse_repeat_zero_progress(b"x") catch {
    @repeat_zero_progress.RepeatZeroProgressNoProgress(field~, offset~) => {
      assert_eq(field, "repeat_zero_progress.values[0]")
      assert_eq(offset, 0)
    }
    _ => fail("unexpected parse error variant")
  } noraise {
    _ => fail("accepted non-progressing repetition")
  }
}

///|
test "terminated string rejects missing terminator" {
  try @term_strz.parse_term_strz(b"foo") catch {
    @term_strz.TermStrzMissingTerminator(field~, offset~) => {
      assert_eq(field, "term_strz.s1")
      assert_eq(offset, 3)
    }
    _ => fail("unexpected parse error variant")
  } noraise {
    _ => fail("accepted unterminated string")
  }
}

///|
test "UTF8 rejects overlong surrogate out of range and incomplete encodings" {
  for
    bytes in [
      b"\xc0\x80", b"\xed\xa0\x80", b"\xf4\x90\x80\x80", b"\xe4\xb8", b"\x80",
    ] {
    try @str_eos.parse_str_eos(bytes) catch {
      @str_eos.StrEosInvalidEncoding(field~, offset~, encoding~) => {
        assert_eq(field, "str_eos.str")
        assert_eq(offset, 0)
        assert_eq(encoding, "UTF-8")
      }
      _ => fail("unexpected parse error variant")
    } noraise {
      _ => fail("accepted invalid UTF8")
    }
  }
  assert_eq(
    @str_eos.parse_str_eos(b"\xe4\xb8\xad\xf0\x9f\x8c\x99").str,
    "中🌙",
  )
}

///|
test "repeat budget is enforced on eos" {
  let input = Bytes::make(4_000_004, 0)
  try @repeat_eos_u4.parse_repeat_eos_u4(input) catch {
    @repeat_eos_u4.RepeatEosU4RepeatLimit(field~, offset~, count~) => {
      assert_eq(field, "repeat_eos_u4.numbers[1000000]")
      assert_eq(offset, 4_000_000)
      assert_eq(count, 1L)
    }
    _ => fail("unexpected parse error variant")
  } noraise {
    _ => fail("repeat budget exceeded")
  }
}

///|
test "until may terminate by index without consuming bytes" {
  let frame = @stream_control.parse_stream_control(stream_sample())
  assert_eq(frame.empty_steps.length(), 2)
}

///|
test "UTF16 validates surrogate pairs and ASCII rejects non ASCII bytes" {
  let valid = stream_sample().to_array()
  valid[11] = 0x3C
  valid[12] = 0xD8
  valid[13] = 0x19
  valid[14] = 0xDF
  assert_eq(
    @stream_control.parse_stream_control(Bytes::from_array(valid[:])).unicode,
    "🌙",
  )
  valid[13] = 0x41
  valid[14] = 0
  try @stream_control.parse_stream_control(Bytes::from_array(valid[:])) catch {
    @stream_control.StreamControlInvalidEncoding(field~, offset~, encoding~) => {
      assert_eq(field, "stream_control.unicode")
      assert_eq(offset, 11)
      assert_eq(encoding, "UTF-16LE")
    }
    _ => fail("unexpected UTF16 failure")
  } noraise {
    _ => fail("accepted unpaired UTF16 surrogate")
  }
  let ascii = stream_sample().to_array()
  ascii[6] = 2
  ascii[7] = 0xFF
  ascii[8] = 0
  try @stream_control.parse_stream_control(Bytes::from_array(ascii[:])) catch {
    @stream_control.StreamControlInvalidEncoding(field~, offset~, encoding~) => {
      assert_eq(field, "stream_control.choice.value")
      assert_eq(offset, 0)
      assert_eq(encoding, "ASCII")
    }
    _ => fail("unexpected ASCII failure")
  } noraise {
    _ => fail("accepted non ASCII byte")
  }
}

///|
test "audit UDP rejects all 11 proper prefixes" {
  let sample = udp_sample()
  assert_eq(sample.length(), 11)
  for length in 0..<sample.length() {
    try @udp.parse_udp_datagram(sample[:length].to_owned()) catch {
      @udp.UdpDatagramTruncated(field~, offset~, needed~, remaining~) => {
        assert_true(field.has_prefix("udp_datagram."))
        assert_eq(offset + remaining, length)
        assert_true(needed > remaining.to_int64())
      }
      error => raise error
    } noraise {
      _ => fail("accepted UDP prefix of length \{length}")
    }
  }
}

///|
test "audit STL rejects all 184 proper prefixes" {
  let sample = stl_sample()
  assert_eq(sample.length(), 184)
  for length in 0..<sample.length() {
    try @stl.parse_stl(sample[:length].to_owned()) catch {
      @stl.StlTruncated(field~, offset~, needed~, remaining~) => {
        assert_true(field.has_prefix("stl."))
        assert_eq(offset + remaining, length)
        assert_true(needed > remaining.to_int64())
      }
      error => raise error
    } noraise {
      _ => fail("accepted STL prefix of length \{length}")
    }
  }
}

///|
test "audit STM32 rejects all 13 proper prefixes" {
  let sample = stm32_sample()
  assert_eq(sample.length(), 13)
  for length in 0..<sample.length() {
    try @stm32.parse_stm32_sample_frame(sample[:length].to_owned()) catch {
      @stm32.Stm32SampleFrameTruncated(field~, offset~, needed~, remaining~) => {
        assert_true(field.has_prefix("stm32_sample_frame."))
        assert_eq(offset + remaining, length)
        assert_true(needed > remaining.to_int64())
      }
      error => raise error
    } noraise {
      _ => fail("accepted STM32 prefix of length \{length}")
    }
  }
}

///|
test "STM32 zero samples consume only the header" {
  let frame = @stm32.parse_stm32_sample_frame(b"\x34\x12\x40\x42\x0F\x00\x00")
  assert_eq(frame.sequence, 0x1234U)
  assert_eq(frame.tick_ms, 1_000_000U)
  assert_eq(frame.sample_count, 0U)
  assert_true(frame.samples.is_empty())
}

///|
test "STM32 maximum byte count reads exactly 255 samples and locates a short final sample" {
  let input = b"\x34\x12\x40\x42\x0F\x00\xFF" +
    Bytes::make(508, 0) +
    b"\xFF\x0F"
  let frame = @stm32.parse_stm32_sample_frame(input)
  assert_eq(frame.samples.length(), 255)
  assert_eq(frame.samples[254], 4095U)
  try @stm32.parse_stm32_sample_frame(input[:516].to_owned()) catch {
    @stm32.Stm32SampleFrameTruncated(field~, offset~, needed~, remaining~) => {
      assert_eq(field, "stm32_sample_frame.samples[254]")
      assert_eq(offset, 515)
      assert_eq(needed, 2L)
      assert_eq(remaining, 1)
    }
    err => raise err
  } noraise {
    _ => fail("accepted an incomplete last sample")
  }
}

///|
fn stm32_sample() -> Bytes {
  // Sequence 0x1234, tick 1,000,000 ms, then three raw ADC values.
  b"\x34\x12\x40\x42\x0F\x00\x03\x00\x00\x00\x08\xFF\x0F"
}

///|
fn verify_stm32_valid() -> Unit raise {
  let frame = @stm32.parse_stm32_sample_frame(stm32_sample())
  assert_eq(frame.sequence, 0x1234U)
  assert_eq(frame.tick_ms, 1_000_000U)
  assert_eq(frame.sample_count, 3U)
  assert_eq(frame.samples, [0U, 2048U, 4095U])
}

///|
fn verify_stm32_truncated() -> Unit raise {
  let sample = stm32_sample()
  let truncated = sample[:sample.length() - 1].to_owned()
  try @stm32.parse_stm32_sample_frame(truncated) catch {
    @stm32.Stm32SampleFrameTruncated(field~, offset~, needed~, remaining~) => {
      assert_eq(field, "stm32_sample_frame.samples[2]")
      assert_eq(offset, 11)
      assert_eq(needed, 2L)
      assert_eq(remaining, 1)
    }
    error => raise error
  } noraise {
    _ => fail("truncated STM32 sample was accepted")
  }
}

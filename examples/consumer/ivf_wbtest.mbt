///|
fn ivf_sample() -> Bytes {
  let header = b"DKIF\x00\x00\x20\x00VP80\x40\x01\xF0\x00" +
    b"\x1E\x00\x00\x00\x01\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00"
  let first_frame = b"\x03\x00\x00\x00\x10\x32\x54\x76\x98\xBA\xDC\xFEABC"
  let second_frame = b"\x01\x00\x00\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFFZ"
  header + first_frame + second_frame
}

///|
test "upstream IVF decodes frame sizes and full 64-bit timestamps" {
  let ivf = @ivf.parse_vp8_duck_ivf(ivf_sample())
  assert_eq(ivf.magic1.to_owned(), b"DKIF")
  assert_eq(ivf.codec.to_owned(), b"VP80")
  assert_eq(ivf.len_header, 32U)
  assert_eq(ivf.width, 320U)
  assert_eq(ivf.height, 240U)
  assert_eq(ivf.num_frames, 2U)
  assert_eq(ivf.image_data.length(), 2)
  let first = ivf.image_data[0].entries
  assert_eq(first.len_frame, 3U)
  assert_eq(first.timestamp, 0xFEDCBA9876543210UL)
  assert_eq(first.framedata.to_owned(), b"ABC")
  let second = ivf.image_data[1].entries
  assert_eq(second.len_frame, 1U)
  assert_eq(second.timestamp, 0xFFFFFFFFFFFFFFFFUL)
  assert_eq(second.framedata.to_owned(), b"Z")
}

///|
test "upstream IVF locates a truncated 64-bit timestamp" {
  let truncated = ivf_sample()[0:40].to_owned()
  try @ivf.parse_vp8_duck_ivf(truncated) catch {
    @ivf.Vp8DuckIvfTruncated(field~, offset~, needed~, remaining~) => {
      assert_eq(field, "vp8_duck_ivf.image_data[0].entries.timestamp")
      assert_eq(offset, 36)
      assert_eq(needed, 8L)
      assert_eq(remaining, 4)
    }
    err => raise err
  } noraise {
    _ => fail("accepted a truncated IVF timestamp")
  }
}

///|
test "upstream IVF locates a truncated nested frame payload" {
  let truncated = ivf_sample()[0:59].to_owned()
  try @ivf.parse_vp8_duck_ivf(truncated) catch {
    @ivf.Vp8DuckIvfTruncated(field~, offset~, needed~, remaining~) => {
      assert_eq(field, "vp8_duck_ivf.image_data[1].entries.framedata")
      assert_eq(offset, 59)
      assert_eq(needed, 1L)
      assert_eq(remaining, 0)
    }
    err => raise err
  } noraise {
    _ => fail("accepted a truncated IVF payload")
  }
}

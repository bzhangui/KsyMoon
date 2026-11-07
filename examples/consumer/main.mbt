///|
fn udp_sample() -> Bytes {
  b"\x04\xD2\x16\x2E\x00\x0B\x12\x34ABC"
}

///|
fn verify_udp_valid() -> Unit raise {
  let datagram = @udp.parse_udp_datagram(udp_sample())
  assert_eq(datagram.src_port, 1234U)
  assert_eq(datagram.dst_port, 5678U)
  assert_eq(datagram.length, 11U)
  assert_eq(datagram.checksum, 0x1234U)
  assert_eq(datagram.body.to_owned(), b"ABC")
}

///|
fn verify_udp_truncated() -> Unit raise {
  let truncated = udp_sample()[:10].to_owned()
  try @udp.parse_udp_datagram(truncated) catch {
    @udp.UdpDatagramTruncated(field~, offset~, needed~, remaining~) => {
      assert_eq(field, "udp_datagram.body")
      assert_eq(offset, 8)
      assert_eq(needed, 3L)
      assert_eq(remaining, 2)
    }
    error => raise error
  } noraise {
    _ => fail("truncated UDP payload was accepted")
  }
}

///|
fn verify_udp_invalid_length() -> Unit raise {
  try @udp.parse_udp_datagram(b"\x04\xD2\x16\x2E\x00\x07\x00\x00") catch {
    @udp.UdpDatagramInvalidLength(field~, offset~, length~) => {
      assert_eq(field, "udp_datagram.body")
      assert_eq(offset, 8)
      assert_eq(length, -1L)
    }
    error => raise error
  } noraise {
    _ => fail("UDP length smaller than the header was accepted")
  }
}

///|
fn main {
  try {
    verify_udp_valid()
    println("UDP valid: 1234 -> 5678, length=11, checksum=0x1234, body=ABC")
    verify_udp_truncated()
    println("UDP truncated: udp_datagram.body at byte 8, need 3, have 2")
    verify_udp_invalid_length()
    println("UDP invalid length: declared datagram length is below 8")
    verify_stl_valid()
    println(
      "STL valid: triangles=2, triangles[1].vertices[1]=(-0.5, 2.5, 0), attribute=0x5678",
    )
    verify_stl_truncated()
    println("STL truncated: stl.triangles[1].abr at byte 182, need 2, have 1")
    verify_stl_repeat_limit()
    println("STL repeat limit: rejected triangle count 4294967295")
    verify_stm32_valid()
    println(
      "STM32 valid: sequence=0x1234, tick_ms=1000000, samples=[0, 2048, 4095]",
    )
    verify_stm32_truncated()
    println(
      "STM32 truncated: stm32_sample_frame.samples[2] at byte 11, need 2, have 1",
    )
  } catch {
    _ => abort("generated parser verification failed")
  }
}

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
fn main {
  try {
    verify_udp_valid()
    println("UDP valid: 1234 -> 5678, length=11, checksum=0x1234, body=ABC")
    verify_udp_truncated()
    println("UDP truncated: udp_datagram.body at byte 8, need 3, have 2")
  } catch {
    _ => abort("UDP verification failed")
  }
}

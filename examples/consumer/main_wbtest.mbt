///|
test "generated UDP parser reads a valid datagram" {
  verify_udp_valid()
}

///|
test "generated UDP parser rejects a truncated payload" {
  verify_udp_truncated()
}

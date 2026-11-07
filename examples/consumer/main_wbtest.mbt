///|
test "generated UDP parser reads a valid datagram" {
  verify_udp_valid()
}

///|
test "generated UDP parser rejects a truncated payload" {
  verify_udp_truncated()
}

///|
test "generated UDP parser rejects a length below the header size" {
  verify_udp_invalid_length()
}

///|
test "generated STL parser reads two triangles and IEEE 754 float coordinates" {
  verify_stl_valid()
}

///|
test "generated STL parser locates a truncated field inside the second triangle" {
  verify_stl_truncated()
}

///|
test "generated STL parser bounds unsigned triangle counts before allocating" {
  verify_stl_repeat_limit()
}

///|
test "generated STM32 parser reads little-endian ADC samples" {
  verify_stm32_valid()
}

///|
test "generated STM32 parser locates the truncated ADC reading" {
  verify_stm32_truncated()
}

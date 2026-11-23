///|
test "qualified casts verify the selected object before exposing it" {
  let frame = parse_cast_navigation(b"\x01\x37")
  assert_eq(frame.narrowed().marker, 55U)
  for tag in [2, 3] {
    let frame = parse_cast_navigation(Bytes::from_array([tag.to_byte(), 55]))
    try frame.narrowed() catch {
      CastNavigationContextError(field~, offset~, message~) => {
        assert_eq(field, "cast_navigation.narrowed")
        assert_eq(offset, 2)
        assert_eq(message, "record is not of type outer::left")
      }
      _ => fail("wrong error for failed object cast")
    } noraise { _ => fail("invalid object cast succeeded") }
  }
}

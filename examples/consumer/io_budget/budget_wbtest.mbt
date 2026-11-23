///|
test "failed outer getter cannot refund independently cached repetitions" {
  let bytes = Array::make(600000, b'0')
  bytes[0] = 192
  bytes[1] = 39
  bytes[2] = 9
  bytes[3] = 0
  let frame = parse_io_budget(Bytes::from_array(bytes))
  for _ in 0..<3 {
    try frame.failing() catch {
      _ => ()
    } noraise {
      _ => fail("bypassed shared repeat budget")
    }
    assert_eq(frame.cached().length(), 600000)
    let root = frame._ksy_arena.frames[frame._ksy_context].unwrap()
    assert_eq(root.reader.budget, [400000, 3, 0, 600000])
    assert_eq(root.reader.offset, 600000)
    try frame.small() catch {
      _ => ()
    } noraise {
      _ => fail("refunded a cached allocation")
    }
    assert_eq(root.reader.budget, [400000, 3, 0, 600000])
  }
}

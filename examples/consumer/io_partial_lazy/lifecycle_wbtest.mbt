///|
test "partial array failure clears unpublished objects and refunds its own budget" {
  let frame = parse_io_partial_lazy(b"\\x00\\x11\\x01")
  for _ in 0..<1000 {
    try frame.entries() catch {
      _ => ()
    } noraise {
      _ => fail("accepted short array")
    }
    let root = frame._ksy_arena.frames[frame._ksy_context].unwrap()
    assert_eq(root.partial.length(), 0)
    assert_eq(root.cache.length(), 0)
    assert_eq(root.children.length(), 0)
    assert_eq(root.reader.offset, 0)
    assert_eq(root.reader.budget, [1_000_000, 3, 0, 0])
    assert_eq(frame._ksy_arena.frames.length(), 2)
    assert_eq(frame._ksy_arena.free.length(), 1)
  }
}

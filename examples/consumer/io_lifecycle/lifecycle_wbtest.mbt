///|
test "failed cross-stream bounded records reclaim contexts on every retry" {
  let frame = parse_io_lifecycle(b"\\x11\\x22")
  for _ in 0..<1000 {
    try frame.failed() catch {
      IoLifecycleTruncated(field~, offset~, needed~, remaining~) => {
        assert_eq(field, "io_lifecycle.failed.word")
        assert_eq(offset, 0)
        assert_eq(needed, 2)
        assert_eq(remaining, 1)
      }
      _ => fail("unexpected error")
    } noraise {
      _ => fail("accepted truncated instance")
    }
    assert_eq(
      frame._ksy_arena.frames[frame.source._ksy_context].unwrap().reader.offset,
      1,
    )
    assert_eq(frame._ksy_arena.frames.length(), 3)
    assert_eq(frame._ksy_arena.free.length(), 1)
  }
}

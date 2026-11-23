///|
test "upstream instance io reads the shared late string substream" {
  let frame = @instance_io_user.parse_instance_io_user(
    b"\x03\x00\x00\x00\x00\x00\x00\x00\xFF\xFF\xFF\xFF\x04\x00\x00\x00\xFF\xFF\xFF\xFE\x0A\x00\x00\x00\xFF\xFF\xFF\xFD\x74\x68\x65\x00\x72\x61\x69\x6E\x79\x00\x64\x61\x79\x20\x69\x74\x20\x69\x73\x00",
  )
  assert_eq(frame.qty_entries, 3U)
  assert_eq(frame.entries[0].name(), "the")
  assert_eq(frame.entries[1].name(), "rainy")
  assert_eq(frame.entries[2].name(), "day it is")
  assert_eq(frame.entries[0].name(), "the")
  assert_eq(frame.strings.str, ["the", "rainy", "day it is"])
}

///|
test "upstream early io uses owner expressions and conditional child bounds" {
  let frame = @instance_io_user_earlier.parse_instance_io_user_earlier(
    b"\x53\x66\x6F\x6F\x00\x58\x42\x00\x00\x00\x59\xFE\xCA\x00\x00\x49\x07",
  )
  assert_eq(frame.sized_a.content, Some(83U))
  assert_eq(frame.sized_b.content, Some(66U))
  assert_eq(frame.into_a.inst().content, Some(102U))
  assert_eq(frame.into_b.inst().content, Some(0U))
  assert_eq(frame.a_mid(), 28527U)
  assert_eq(frame.b_mid(), 0U)
  assert_eq(frame.into_a.inst().last(), Some(0U))
  assert_eq(frame.into_b.inst().last(), Some(89U))
  assert_eq(frame.sized_a.last(), Some(88U))
  assert_eq(frame.sized_b.last(), Some(254U))
  assert_eq(frame.into_a_skipped.inst().content, None)
  assert_eq(frame.into_a_skipped.inst().last(), None)
  assert_eq(frame.into_a.bar, Some(73U))
  assert_eq(frame.last_accessor.v, Some(7U))
}

///|
test "upstream parent navigation preserves the owner of switched root reads" {
  let frame = @nav_parent2.parse_nav_parent2(
    b"\x08\x00\x00\x00\x02\x00\x00\x00\x52\x41\x48\x43\x20\x00\x00\x00\x03\x00\x00\x00\x52\x41\x48\x43\x23\x00\x00\x00\x06\x00\x00\x00\x66\x6F\x6F\x62\x61\x72\x62\x61\x7A",
  )
  assert_eq(frame.num_tags, 2U)
  guard frame.tags[0].tag_content() is Case0(first) else {
    fail("wrong tag case")
  }
  guard frame.tags[1].tag_content() is Case0(second) else {
    fail("wrong tag case")
  }
  assert_eq(first.content, "foo")
  assert_eq(second.content, "barbaz")
}

///|
test "upstream root positioned array preserves parent navigation" {
  let frame = @nav_parent3.parse_nav_parent3(
    b"\x08\x00\x00\x00\x02\x00\x00\x00\x52\x41\x48\x43\x20\x00\x00\x00\x03\x00\x00\x00\x52\x41\x48\x43\x23\x00\x00\x00\x06\x00\x00\x00\x66\x6F\x6F\x62\x61\x72\x62\x61\x7A",
  )
  let tags = frame.tags()
  assert_eq(tags.length(), 2)
  guard tags[0].tag_content() is Case0(first) else { fail("wrong tag case") }
  guard tags[1].tag_content() is Case0(second) else { fail("wrong tag case") }
  assert_eq(first.content, "foo")
  assert_eq(second.content, "barbaz")
}

///|
test "cross-stream selectors preserve owner and selected stream semantics" {
  let frame = @cross_stream_layout.parse_cross_stream_layout(
    b"\xAA\x10\x11\x12\x13\x20\x21\x00\x23\x55",
  )
  assert_eq(frame.chosen(), 17U)
  assert_eq(frame.positioned(), 19U)
  assert_eq(frame.left.root_marker(), 170U)
  assert_eq(frame.right.parent_marker(), 170U)
  assert_eq(frame.pair().first, 17U)
  assert_eq(frame.pair().second, 18U)
  assert_eq(frame.pair().parent_marker(), 170U)
  assert_eq(frame.eos_items(), [33U, 0U, 35U])
  assert_eq(frame.until_items(), [33U, 0U])
  assert_eq(frame.owner_position(), 10L)
  assert_eq(frame.left_position(), 1L)
  assert_eq(frame.right_position(), 1L)
  assert_eq(frame.skipped(), None)
  assert_eq(frame.next_left(), 17U)
  assert_eq(frame.next_left(), 17U)
  assert_eq(frame.left_remaining().to_owned(), b"\x12\x13")
  guard frame.raw_switch() is Raw(bytes) else { fail("missing raw branch") }
  assert_eq(bytes.to_owned(), b"\x21\x00")
  for _ in 0..<3 {
    try frame.invalid() catch {
      _ => ()
    } noraise {
      _ => fail("accepted missing stream")
    }
    try frame.out_of_bounds() catch {
      _ => ()
    } noraise {
      _ => fail("accepted invalid stream position")
    }
  }
}

///|
test "array elements expose earlier streams during sequential and lazy parsing" {
  let data = b"\x00\x11\x01\x22"
  let frame = @io_partial_seq.parse_io_partial_seq(data)
  assert_eq(frame.entries[0].value, None)
  assert_eq(frame.entries[1].value, Some(34U))
  let frame = @io_partial_lazy.parse_io_partial_lazy(data)
  let entries = frame.entries()
  assert_eq(entries[0].value, None)
  assert_eq(entries[1].value, Some(34U))
  entries[0] = entries[1]
  assert_eq(frame.entries()[0].value, Some(34U))
}

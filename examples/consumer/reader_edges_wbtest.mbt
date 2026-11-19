///|
test "negative sized terminated fields reject and restore the lazy cursor" {
  let frame = @reader_edges.parse_reader_edges(b"\x00A\x00")
  assert_true(frame.conditional_text() is None)
  for _ in 0..<2 {
    try frame.sized_text() catch {
      @reader_edges.ReaderEdgesInvalidLength(field~, offset~, length~) => {
        assert_eq(field, "reader_edges.sized_text")
        assert_eq(offset, 1)
        assert_eq(length, -1L)
      }
      _ => fail("unexpected negative length error")
    } noraise {
      _ => fail("accepted negative size")
    }
  }
  assert_eq(frame.cursor(), 1L)
}

///|
test "negative sized padded bytes cannot enter unbounded mode" {
  let frame = @reader_edges.parse_reader_edges(b"\x00AB")
  try frame.padded_bytes() catch {
    @reader_edges.ReaderEdgesInvalidLength(field~, offset~, length~) => {
      assert_eq(field, "reader_edges.padded_bytes")
      assert_eq(offset, 1)
      assert_eq(length, -1L)
    }
    _ => fail("unexpected padded length error")
  } noraise {
    _ => fail("accepted negative padded size")
  }
}

///|
test "zero sized terminated and padded fields return empty values" {
  let frame = @reader_edges.parse_reader_edges(b"\x01UNREAD")
  assert_eq(frame.sized_text(), "")
  assert_eq(frame.padded_bytes().length(), 0)
  assert_eq(frame.conditional_text(), Some(""))
  assert_eq(frame.cursor(), 1L)
}

///|
test "explicit UTF16 terminators are bytes and preserve the following byte" {
  let frame = @reader_edges.parse_reader_edges(b"\x00A\x00|\x00B\x00")
  assert_eq(frame.explicit_text(), "A")
  assert_eq(frame.explicit_strz(), "A")
  assert_eq(frame.explicit_sized(), "A")
  assert_eq(frame.unpositioned(), "A")
  assert_eq(frame.following().to_owned(), b"\x00B\x00")
}

///|
test "included explicit UTF16 byte terminator validates odd length" {
  let frame = @reader_edges.parse_reader_edges(b"\x00A\x00|\x00B\x00")
  try frame.explicit_included() catch {
    @reader_edges.ReaderEdgesInvalidEncoding(field~, offset~, ..) => {
      assert_eq(field, "reader_edges.explicit_included")
      assert_eq(offset, 3)
    }
    _ => fail("unexpected UTF16 include error")
  } noraise {
    _ => fail("accepted odd UTF16")
  }
}

///|
test "implicit UTF16 strz terminators remain aligned double byte units" {
  let frame = @reader_edges.parse_reader_edges(b"\x00A\x00B\x00\x00\x00REST")
  assert_eq(frame.implicit_strz(), "AB")
  assert_eq(frame.cursor(), 1L)
}

///|
test "nested value only records compile and return cached calculations" {
  let frame = @pure_nested_value.parse_pure_nested_value(b"")
  assert_eq(frame.header.number(), 42L)
  assert_eq(frame.header.number(), 42L)
  assert_eq(frame.header.label(), "ok")
}

///|
test "pure nested records keep input for stream queries and positioned instances" {
  let empty = @pure_stream_value.parse_pure_stream_value(b"")
  assert_true(empty.header is None)
  assert_eq(empty.peek().number(), 42L)
  assert_eq(empty.peek().stream_size(), 0L)
  let frame = @pure_stream_value.parse_pure_stream_value(b"ABC")
  assert_eq(frame.header.unwrap().stream_size(), 3L)
  assert_eq(frame.peek().stream_size(), 3L)
}

///|
test "pure repeated records share budget without unused throwing helpers" {
  let frame = @pure_repeated_value.parse_pure_repeated_value(b"")
  assert_eq(frame.headers.length(), 2)
  assert_eq(frame.headers[0].number(), 42L)
  assert_eq(frame.headers[1].number(), 42L)
  assert_eq(frame.single().number(), 42L)
  guard frame.choice() is Default(header)
  assert_eq(header.number(), 42L)
}

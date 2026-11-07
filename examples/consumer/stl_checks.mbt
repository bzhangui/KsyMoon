///|
fn stl_sample() -> Bytes {
  // Two triangles, each with a normal, three vertices, and a 16-bit attribute.
  let zero = Bytes::make(12, 0)
  let normal = b"\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x3F"
  let positive_x = b"\x00\x00\xC0\x3F\x00\x00\x00\x00\x00\x00\x00\x00"
  let negative_y = b"\x00\x00\x00\x00\x00\x00\x10\xC0\x00\x00\x00\x00"
  let mixed_xy = b"\x00\x00\x00\xBF\x00\x00\x20\x40\x00\x00\x00\x00"
  let first = normal + zero + positive_x + negative_y + b"\x34\x12"
  let second = normal + zero + mixed_xy + positive_x + b"\x78\x56"
  Bytes::make(80, 0) + b"\x02\x00\x00\x00" + first + second
}

///|
fn verify_stl_valid() -> Unit raise {
  let mesh = @stl.parse_stl(stl_sample())
  assert_eq(mesh.header.length(), 80)
  assert_eq(mesh.num_triangles, 2U)
  assert_eq(mesh.triangles.length(), 2)
  let first = mesh.triangles[0]
  assert_eq(first.normal.z, 1.0)
  assert_eq(first.vertices.length(), 3)
  assert_eq(first.vertices[1].x, 1.5)
  assert_eq(first.vertices[2].y, -2.25)
  assert_eq(first.abr, 0x1234U)
  let second = mesh.triangles[1]
  assert_eq(second.vertices[1].x, -0.5)
  assert_eq(second.vertices[1].y, 2.5)
  assert_eq(second.vertices[1].z, 0.0)
  assert_eq(second.abr, 0x5678U)
}

///|
fn verify_stl_truncated() -> Unit raise {
  let sample = stl_sample()
  let truncated = sample[:sample.length() - 1].to_owned()
  try @stl.parse_stl(truncated) catch {
    @stl.StlTruncated(field~, offset~, needed~, remaining~) => {
      assert_eq(field, "stl.triangles[1].abr")
      assert_eq(offset, 182)
      assert_eq(needed, 2L)
      assert_eq(remaining, 1)
    }
    error => raise error
  } noraise {
    _ => fail("truncated STL triangle was accepted")
  }
}

///|
fn verify_stl_repeat_limit() -> Unit raise {
  let sample = Bytes::make(80, 0) + b"\xFF\xFF\xFF\xFF"
  try @stl.parse_stl(sample) catch {
    @stl.StlRepeatLimit(field~, offset~, count~) => {
      assert_eq(field, "stl.triangles")
      assert_eq(offset, 84)
      assert_eq(count, 4294967295L)
    }
    error => raise error
  } noraise {
    _ => fail("unbounded STL triangle count was accepted")
  }
}

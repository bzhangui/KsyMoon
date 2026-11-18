///|
fn conditional_sample() -> Bytes {
  b"\x01\x02AB\x12\x34\x7F\x99"
}

///|
test "upstream nested value instances distinguish absent and present values" {
  let frame = @if_values.parse_if_values(b"\x08\x05\xFE")
  assert_eq(frame.codes[0].half_opcode().unwrap(), 4L)
  assert_true(frame.codes[1].half_opcode() is None)
  assert_eq(frame.codes[2].half_opcode().unwrap(), 127L)
}

///|
test "upstream calculated integer division uses floor semantics" {
  let frame = @expr_int_div.parse_expr_int_div(
    b"\x6D\x26\x00\x00\x93\xD9\xFF\xFF",
  )
  assert_eq(frame.div_pos_const(), 756L)
  assert_eq(frame.div_neg_const(), -757L)
  assert_eq(frame.div_pos_seq(), 756L)
  assert_eq(frame.div_neg_seq(), -757L)
}

///|
test "condition false skips scalar bytes arrays and validation" {
  let frame = @conditional.parse_conditional_layout(b"\x00\xFF\x7F")
  assert_true(frame.payload is None)
  assert_true(frame.checksum is None)
  assert_true(frame.entries is None)
  assert_eq(frame.tail, 127U)
}

///|
test "condition true parses and validates an optional field" {
  let frame = @conditional.parse_conditional_layout(conditional_sample())
  assert_eq(frame.payload.unwrap().to_owned(), b"AB")
  assert_eq(frame.checksum.unwrap(), 0x1234U)
  assert_true(frame.entries is None)
  assert_eq(frame.tail, 127U)
  try @conditional.parse_conditional_layout(b"\x01\x02AB\x12") catch {
    @conditional.ConditionalLayoutTruncated(
      field~,
      offset~,
      needed~,
      remaining~
    ) => {
      assert_eq(field, "conditional_layout.checksum")
      assert_eq(offset, 4)
      assert_eq(needed, 2L)
      assert_eq(remaining, 1)
    }
    err => raise err
  } noraise {
    _ => fail("accepted truncated conditional field")
  }
}

///|
test "conditional repeated nested structures keep per-item paths" {
  let frame = @conditional.parse_conditional_layout(
    b"\x02\x02AB\x01\x02\xFE\x7F",
  )
  let entries = frame.entries.unwrap()
  assert_eq(entries.length(), 2)
  assert_true(entries[0].extra is None)
  assert_eq(entries[1].extra.unwrap(), -2)
  assert_eq(frame.tail, 127U)
}

///|
test "instances are lazy cache successes and preserve stream position" {
  let frame = @conditional.parse_conditional_layout(conditional_sample())
  assert_eq(frame.last(), 153U)
  assert_eq(frame.cursor(), 7L)
  assert_eq(frame.following(), 153U)
  assert_eq(frame.position_after(), 8L)
  assert_eq(frame.following(), 153U)
  assert_eq(frame.position_after(), 8L)
  assert_eq(frame.derived(), 12L)
  assert_eq(frame.chained(), 13L)
  let repeated = frame.repeated()
  assert_eq(repeated[0].to_owned(), b"A")
  repeated[0] = b"Z"[:]
  assert_eq(frame.repeated()[0].to_owned(), b"Z")
}

///|
test "conditional instances skip both seek and read" {
  assert_true(@if_instances.parse_if_instances(b"").never_happens() is None)
  let frame = @conditional.parse_conditional_layout(conditional_sample())
  assert_true(frame.never() is None)
  assert_true(frame.never() is None)
  assert_eq(frame.following(), 153U)
}

///|
test "instance failures restore the stream and can be retried" {
  let frame = @conditional.parse_conditional_layout(conditional_sample())
  for _ in 0..<2 {
    try frame.bad_read() catch {
      @conditional.ConditionalLayoutTruncated(
        field~,
        offset~,
        needed~,
        remaining~
      ) => {
        assert_eq(field, "conditional_layout.bad_read")
        assert_eq(offset, 7)
        assert_eq(needed, 4L)
        assert_eq(remaining, 1)
      }
      err => raise err
    } noraise {
      _ => fail("read beyond the lazy instance")
    }
  }
  assert_eq(frame.following(), 153U)
  try frame.bad_position() catch {
    @conditional.ConditionalLayoutInvalidPosition(field~, offset~, position~) => {
      assert_eq(field, "conditional_layout.bad_position")
      assert_eq(offset, 8)
      assert_eq(position, -1L)
    }
    err => raise err
  } noraise {
    _ => fail("accepted a negative position")
  }
}

///|
test "failed lazy arrays restore the repeat budget" {
  let frame = @instance_std_array.parse_instance_std_array(
    b"\x0C\x00\x00\x00\x01\x00\x00\x00\xC0\x27\x09\x00A",
  )
  for _ in 0..<2 {
    try frame.entries() catch {
      @instance_std_array.InstanceStdArrayTruncated(
        field~,
        offset~,
        needed~,
        remaining~
      ) => {
        assert_eq(field, "instance_std_array.entries[1]")
        assert_eq(offset, 13)
        assert_eq(needed, 1L)
        assert_eq(remaining, 0)
      }
      err => raise err
    } noraise {
      _ => fail("accepted an incomplete lazy array")
    }
  }
}

///|
test "expressions short circuit and use Kaitai floor division and modulo" {
  let frame = @conditional.parse_conditional_layout(conditional_sample())
  assert_false(frame.short_circuit())
  assert_eq(frame.choice(), 9L)
  assert_eq(frame.negative_remainder(), 4L)
  assert_true(frame.boolean_dependency())
  assert_eq(frame.bits(), 258L)
}

///|
test "cyclic positioned instance reads report a typed error and release guards" {
  let frame = @conditional.parse_conditional_layout(conditional_sample())
  for _ in 0..<2 {
    try frame.loop_a() catch {
      @conditional.ConditionalLayoutInstanceCycle(field~, offset~) => {
        assert_eq(field, "conditional_layout.loop_a")
        assert_eq(offset, 7)
      }
      err => raise err
    } noraise {
      _ => fail("accepted an instance cycle")
    }
  }
  assert_eq(frame.following(), 153U)
}

///|
test "expression overflow and division by zero are typed retryable errors" {
  let frame = @conditional.parse_conditional_layout(conditional_sample())
  assert_eq(frame.minimum(), -9223372036854775808L)
  for _ in 0..<2 {
    try frame.overflow() catch {
      @conditional.ConditionalLayoutExpressionError(field~, offset~, operation~) => {
        assert_eq(field, "conditional_layout.overflow")
        assert_eq(offset, 7)
        assert_eq(operation, "+")
      }
      err => raise err
    } noraise {
      _ => fail("accepted Int64 overflow")
    }
  }
  try frame.zero_divide() catch {
    @conditional.ConditionalLayoutExpressionError(field~, offset~, operation~) => {
      assert_eq(field, "conditional_layout.zero_divide")
      assert_eq(offset, 7)
      assert_eq(operation, "/")
    }
    err => raise err
  } noraise {
    _ => fail("accepted division by zero")
  }
  try frame.division_overflow() catch {
    @conditional.ConditionalLayoutExpressionError(field~, offset~, operation~) => {
      assert_eq(field, "conditional_layout.division_overflow")
      assert_eq(offset, 7)
      assert_eq(operation, "/")
    }
    err => raise err
  } noraise {
    _ => fail("accepted signed division overflow")
  }
}

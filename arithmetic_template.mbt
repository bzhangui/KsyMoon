///|
fn emit_arithmetic(output : StringBuilder, root_type : String) -> Unit {
  let block =
    #|///|
    #|fn __ROOT__Reader::arithmetic(
    #|  self : __ROOT__Reader, operation : String, a : Int64, b : Int64, field : String,
    #|) -> Int64 raise __ROOT__ParseError {
    #|  let minimum = -9223372036854775808L
    #|  let maximum = 9223372036854775807L
    #|  let invalid = match operation {
    #|    "+" => (b > 0L && a > maximum - b) || (b < 0L && a < minimum - b)
    #|    "-" => (b < 0L && a > maximum + b) || (b > 0L && a < minimum + b)
    #|    "*" =>
    #|      if a > 0L {
    #|        if b > 0L { a > maximum / b } else { b < minimum / a }
    #|      } else if a < 0L {
    #|        if b > 0L { a < minimum / b } else { b < 0L && a < maximum / b }
    #|      } else { false }
    #|    "/" | "%" => b == 0L || (a == minimum && b == -1L)
    #|    "<<" | ">>" => b < 0L || b >= 64L
    #|    _ => true
    #|  }
    #|  guard !invalid else { raise __ROOT__ExpressionError(field~, offset=self.offset, operation~) }
    #|  match operation {
    #|    "+" => a + b
    #|    "-" => a - b
    #|    "*" => a * b
    #|    "/" => {
    #|      let quotient = a / b
    #|      if a % b != 0L && (a < 0L) != (b < 0L) { quotient - 1L } else { quotient }
    #|    }
    #|    "%" => {
    #|      let remainder = a % b
    #|      if remainder != 0L && (a < 0L) != (b < 0L) { remainder + b } else { remainder }
    #|    }
    #|    "<<" => a << b.to_int()
    #|    _ => a >> b.to_int()
    #|  }
    #|}
    #|
  write_reader_block(output, block, root_type)
}

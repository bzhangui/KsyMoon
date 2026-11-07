meta:
  id: stm32_sample_frame
  title: STM32 ADC sample frame
  endian: le
doc: |
  Example application frame for transferring raw ADC readings. The sender
  writes a sequence number, a millisecond tick, a sample count, then that many
  unsigned 16-bit readings. Fields are serialized without alignment padding.
seq:
  - id: sequence
    type: u2
  - id: tick_ms
    type: u4
  - id: sample_count
    type: u1
  - id: samples
    type: u2
    repeat: expr
    repeat-expr: sample_count

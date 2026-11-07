meta:
  id: wire_checks
  endian: le
seq:
  - id: magic
    contents: "KSY!"
  - id: marker
    contents: [0x00, "é", 255]
  - id: byte_min
    type: s1
  - id: byte_max
    type: s1
  - id: short_min
    type: s2
  - id: short_max
    type: s2be
  - id: word_min
    type: s4be
  - id: word_max
    type: s4le
  - id: version
    type: u1
    valid: 7
  - id: adc
    type: u2
    valid: {min: 0, max: 4095}
  - id: delta
    type: s1
    valid: {max: -1}
  - id: big_tick
    type: u8be

# KsyMoon

KsyMoon turns a subset of Kaitai Struct descriptions into typed MoonBit
decoders. The generated source uses only the MoonBit standard library.

## UDP quick start

Run these commands from the repository root with MoonBit and Node.js installed.

```powershell
moon run --target js cmd/ksymoon -- generate fixtures/udp_datagram.ksy --out examples/consumer/udp/udp_datagram.mbt
moon -C examples/consumer run --target js .
```

The consumer is a separate MoonBit module and imports the generated parser
from its own UDP package. It checks both a valid datagram and a truncated payload.

The original UDP fixture is from [Kaitai Struct's format repository](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/network/udp_datagram.ksy) and carries its own CC0-1.0 license.

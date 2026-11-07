# KsyMoon

KsyMoon 把 Kaitai Struct 的 `.ksy` 描述生成为带类型的 MoonBit 二进制解析器。生成的源码只依赖 MoonBit 标准库。

## 从 Mooncakes 安装

在自己的 MoonBit 模块中安装生成器。

```powershell
moon add bzhangui/ksymoon@0.2.0
```

在调用包的 `moon.pkg` 中导入 `"bzhangui/ksymoon" @ksymoon`。用 `@ksymoon.generate(source)` 将描述文本生成为 MoonBit 源码，或用 `@ksymoon.validate(source)` 单独校验描述。两个接口都会用 `SchemaError` 报告超出支持范围的描述。

`v0.2.0` 新增固定签名、有符号整数、整数标量约束、64 位无符号整数和只读 `check` 命令。示例包含 UDP、二进制 STL、STM32 采样帧和原样上游 IVF。

## 生成并运行

安装 MoonBit 与 Node.js，在仓库根目录执行以下命令。验收工具链使用 Node.js 24 和 MoonBit v0.10.19+97801ee1b，生成器的 YAML 依赖锁定为 `moonbit-community/yaml@0.0.7`。

```powershell
moon update
moon run --target js cmd/ksymoon -- check fixtures/udp_datagram.ksy
moon run --target js cmd/ksymoon -- generate fixtures/udp_datagram.ksy --out examples/consumer/udp/udp_datagram.mbt
moon run --target js cmd/ksymoon -- generate fixtures/stl.ksy --out examples/consumer/stl/stl.mbt
moon run --target js cmd/ksymoon -- generate fixtures/stm32_sample_frame.ksy --out examples/consumer/stm32/stm32_sample_frame.mbt
moon run --target js cmd/ksymoon -- generate fixtures/vp8_duck_ivf.ksy --out examples/consumer/ivf/vp8_duck_ivf.mbt
moon -C examples/consumer test --target all --deny-warn
moon -C examples/consumer run --target js .
```

`examples/consumer` 有自己的 `moon.mod`，从自身的 `udp`、`stl` 和 `stm32` 包调用生成的解析器。在自己的模块里使用时，先创建目标包和 `moon.pkg`，再把生成的文件写入该包。

`check INPUT.ksy` 只校验描述。通过时返回状态 0，输入无法读取或描述超出支持范围时返回非零状态并打印诊断。库接口提供 `validate(source)` 和 `generate(source)`。

## 复现验收

```powershell
node scripts/verify.mjs
```

脚本更新 Mooncakes 索引，验证 CLI 的退出状态、诊断和输出文件保护，核对三份上游 `.ksy` 的 SHA-256，再在 `_build` 下新建独立消费模块。五个解析器（UDP、STL、STM32、IVF 和基础特性测试）均重新生成并与仓库示例逐字节比对。脚本检查、构建、测试并运行 JS、Wasm、Wasm-GC、Native 四个目标，保留隔离目录以便查看生成物。

安装 Java 21 和 Python 后，可用 Kaitai 官方 0.11 编译器的 Python 目标生成对照解析器。脚本核对编译器 ZIP 的 SHA-256，并用 UDP 与 STL 的固定样本生成四个逐字段比较测试。 [Kaitai 0.11 发布](https://github.com/kaitai-io/kaitai_struct_compiler/releases/tag/0.11)

```powershell
python -m pip install kaitaistruct==0.11
node scripts/verify.mjs --kaitai-reference
```

GitHub Actions 在 Ubuntu 上安装固定的 MoonBit v0.10.19+97801ee1b 和 Node.js 24，核对编译器版本后运行包含 Kaitai 对照的验证。工作流支持推送、PR 和手动触发。 [工作流](.github/workflows/verify.yml)

| 样本 | 验收结果 |
| --- | --- |
| 正常 UDP | 端口 `1234 → 5678`，声明长度 11，负载 `ABC` |
| 截断 UDP | `udp_datagram.body` 从字节偏移 8 开始，需要 3 字节，剩 2 字节 |
| 非法 UDP 长度 | 报文长度字段小于 8 时返回 `UdpDatagramInvalidLength` |
| 正常二进制 STL | 两个三角面，第二个三角面的第二个顶点为 `(-0.5, 2.5, 0)`，属性为 `0x5678` |
| 截断 STL | `stl.triangles[1].abr` 从字节偏移 182 开始，需要 2 字节，剩 1 字节 |
| 异常 STL 计数 | `0xffffffff` 三角面计数触发重复项上限 |
| 正常 STM32 采样帧 | 帧序号 `0x1234`、时间戳 `1000000 ms`、采样值 `[0, 2048, 4095]` |
| 截断 STM32 采样帧 | `stm32_sample_frame.samples[2]` 从字节偏移 11 开始，需要 2 字节，剩 1 字节 |
| STM32 采样计数边界 | 接受 0 和 255 个采样值，拒绝缺少最后一个采样字节的 255 样本帧 |
| 二进制 IVF | 原样上游描述读取帧长度及两个 64 位时间戳，截断时间戳或负载时报告字段路径与字节偏移 |

报文、模型与采样帧均为测试中构造的字节样本，偏移与数组索引从 0 开始。STM32 演示采用项目自定义的无填充小端帧，依次包含帧序号 `u2`、毫秒时间戳 `u4`、采样计数 `u1` 和对应数量的 `u2` 原始 ADC 读数。 [STM32 描述](fixtures/stm32_sample_frame.ksy)

三个主场景的测试在每个目标上覆盖 208 个真前缀（UDP 11、STL 184、STM32 13），逐一核对截断类型、字段路径前缀、偏移和剩余字节。 [全前缀测试](examples/consumer/prefix_wbtest.mbt)

## 支持的描述子集

- `meta.id`、`meta.endian`、`seq` 和非递归本地 `types`。
- `u1`、`u2`、`u4`、`u8`、`s1`、`s2`、`s4`、`f4`。多字节类型采用 `meta.endian` 或类型的显式大小端后缀，`u8` 生成为 `UInt64`。
- `contents` 固定签名支持 UTF-8 字符串，以及包含字符串和字节整数的数组。`valid` 支持 32 位以内整数标量的常量、`eq`、`min` 和 `max`。
- `size` 字节字段和 `repeat: expr` 数组。长度表达式支持非负常量、先前的 `u1/u2/u4` 标量字段，以及该字段减去非负整数。
- 生成的解析器读取描述指定的前缀。UDP 校验和作为字段返回，由调用者按使用场景校验。
- 生成器遇到 `instances`、条件字段、导入等超出子集的键时，返回对应的描述路径。运行时按错误类型报告字段路径和字节偏移，包括截断、非法长度、计数超限、签名不匹配和标量越界。单次解析最多处理 1,000,000 个重复项，嵌套数组的元素计入同一总额。

## 来源与许可

KsyMoon 源码及 STM32 描述采用 MIT 许可证。UDP、STL 和 IVF 描述按 Kaitai Struct 上游提交 `30e7ad51e8c870d3a098cd618c0f4b2797efc538` 原样保存，采用各自文件内的 CC0-1.0 许可。 [UDP 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/network/udp_datagram.ksy) · [STL 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/media/stl.ksy) · [IVF 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/media/vp8_duck_ivf.ksy)

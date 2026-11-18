# KsyMoon

KsyMoon 把 Kaitai Struct 的 `.ksy` 描述生成为带类型的 MoonBit 二进制解析器。生成的源码只依赖 MoonBit 标准库。

项目以 **Kaitai Struct 0.11 的完整语言与二进制读取语义兼容**为最终目标，按标准能力矩阵和固定上游测试逐阶段验收。当前开发版为 `0.3.0-dev.1`，新增条件字段、惰性解析实例、值实例及基础表达式。完整目标、当前实现和后续阶段见[兼容计划](docs/COMPATIBILITY.zh-CN.md)。

## 从 Mooncakes 安装

在自己的 MoonBit 模块中安装生成器。

```powershell
moon add bzhangui/ksymoon@0.2.0
```

在调用包的 `moon.pkg` 中导入 `"bzhangui/ksymoon" @ksymoon`。用 `@ksymoon.generate(source)` 将描述文本生成为 MoonBit 源码，或用 `@ksymoon.validate(source)` 单独校验描述。两个接口都会用 `SchemaError` 报告超出支持范围的描述。

Mooncakes 当前已发布 `v0.2.0`，提供固定签名、有符号整数、整数标量约束、64 位无符号整数和只读 `check` 命令。新条件和实例语义通过本分支源码复现。

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

脚本更新 Mooncakes 索引，验证 CLI 的退出状态、诊断和输出文件保护，核对上游描述的 SHA-256，再在 `_build` 下新建独立消费模块。四个原有场景、基础特性、条件布局与四份上游兼容用例均重新生成并与仓库源码逐字节比对。脚本在 JS、Wasm、Wasm-GC、Native 四个目标检查、构建和测试，演示命令继续运行 UDP、STL、STM32。

安装 Java 21 和 Python 后，可用 Kaitai 官方 0.11 编译器的 Python 目标生成对照解析器。脚本核对编译器 ZIP 的 SHA-256，执行 10 个对照测试，覆盖 UDP、STL、条件缺省值、定位数组实例、条件实例、整数除法及条件布局。 [Kaitai 0.11 发布](https://github.com/kaitai-io/kaitai_struct_compiler/releases/tag/0.11)

```powershell
python -m pip install kaitaistruct==0.11
node scripts/verify.mjs --kaitai-reference
python scripts/compatibility-report.py
```

GitHub Actions 在 Ubuntu 上安装固定的 MoonBit v0.10.19+97801ee1b 和 Node.js 24，运行对照验证，并检查固定上游测试库的全部 339 份描述。已生成的源码另建独立模块检查和构建，完整结果以 CI 附件导出。描述接受和编译结果、运行语义对照分别记录。 [工作流](.github/workflows/verify.yml)

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

## 当前实现与兼容进度

- `meta.id`、`meta.endian`、`seq` 和非递归本地 `types`。
- `u1`、`u2`、`u4`、`u8`、`s1`、`s2`、`s4`、`f4`。多字节类型采用 `meta.endian` 或类型的显式大小端后缀，`u8` 生成为 `UInt64`。
- `contents` 固定签名支持 UTF-8 字符串，以及包含字符串和字节整数的数组。`valid` 支持 32 位以内整数标量的常量、`eq`、`min` 和 `max`。
- `size` 字节字段和 `repeat: expr` 数组。长度表达式支持非负常量、先前的 `u1/u2/u4` 标量字段，以及该字段减去非负整数。
- `if` 条件标量、字节字段、嵌套记录和数组，结果生成为 `Option[T]`。条件为假时跳过读取、约束及重复项预留。
- `instances` 的 `pos` 定位读取、计数数组和 `value` 计算值，均按需求值并缓存成功结果，使用生成记录的同名方法访问，如 `record.entries()`。条件实例在求值为假时跳过定位与读取。
- `if/value/pos` 的有类型整数和布尔表达式，支持括号、算术、比较、位运算、逻辑短路、条件表达式、实例依赖和 `_io.pos/_io.size`。当前数字引用为 32 位以内非可选字段，计算类型为 Int64。 [新增回归](examples/consumer/conditional_wbtest.mbt)
- 生成的解析器读取描述指定的前缀。UDP 校验和作为字段返回，由调用者按使用场景校验。
- 当前尚待实现的标准语义包括 imports、参数、枚举、switch、位域、通用子流、更多字符串与处理器等，对应 P2—P5 的明确门禁。遇到尚未实现的语法会返回描述诊断。运行时错误包含字段路径和字节偏移。单次顺序解析及实例读取共享 1,000,000 个重复项的预算，失败的实例读取会归还本次预留，嵌套数组计入同一预算。 [完整兼容终点](docs/COMPATIBILITY.zh-CN.md)

## 来源与许可

KsyMoon 源码及 STM32 描述采用 MIT 许可证。UDP、STL 和 IVF 描述按 Kaitai Struct 上游提交 `30e7ad51e8c870d3a098cd618c0f4b2797efc538` 原样保存，采用各自文件内的 CC0-1.0 许可。 [UDP 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/network/udp_datagram.ksy) · [STL 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/media/stl.ksy) · [IVF 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/media/vp8_duck_ivf.ksy)

四份新增兼容描述来自 Kaitai 官方测试库，按固定修订原样保存，采用上游 MIT 许可证。条件布局和 MoonBit 断言由项目实现，官方编译器与 Python 运行时仅用于测试对照。 [测试来源与哈希](fixtures/kaitai/manifest.json) · [上游许可证](fixtures/kaitai/LICENSE)

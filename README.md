# KsyMoon

KsyMoon 把 Kaitai Struct 的 `.ksy` 描述生成为带类型的 MoonBit 二进制解析器。生成的源码只依赖 MoonBit 标准库。

项目以 **Kaitai Struct 0.11 的完整语言与二进制读取语义兼容**为最终目标，按标准能力矩阵和固定上游测试逐阶段验收。仓库已实现条件、惰性实例、有界子流、跨流实例、EOS/Until 重复、类型分支、字符串、对象导航、整数枚举及标量参数。完整目标、当前实现和后续阶段见[兼容计划](docs/COMPATIBILITY.zh-CN.md)。

`v0.5.0` 支持多文件导入、跨模块读取、XOR、循环位移和 zlib。 [Mooncakes](https://mooncakes.io/docs/bzhangui/ksymoon@0.5.0) · [发布复验记录](docs/reports/mooncakes-0.5.0.json)

## 快速开始

使用 MoonBit v0.10.19 和 Node.js 24，从本仓库检出 `v0.5.0` 后运行：

```powershell
node examples/quickstart/run.mjs
```

脚本在新模块中执行 `moon add bzhangui/ksymoon@0.5.0`，调用安装的生成器，把原样 UDP 和跨流实例描述转换为独立 MoonBit 源码，再检查、构建、测试和运行。正常输出包含 `UDP: 1234 -> 5678, ABC` 与 `Cross-stream names: the, rainy, day it is`，两个截断样本均被拒绝。加 `--all-targets` 检查四后端，加 `--source` 从当前 Git 源码运行同一示例。

在自己的模块中，先执行 `moon add bzhangui/ksymoon@0.5.0`，在调用包的 `moon.pkg` 中导入 `"bzhangui/ksymoon" @ksymoon`。`@ksymoon.generate(source)` 返回 MoonBit 源码。`@ksymoon.validate(source)` 校验描述。把生成结果写入新包后，以输入字节调用生成的 `parse_<id>`。

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

## Native 命令行

从当前开发分支用 MoonBit v0.10.19 构建。文件读取、诊断、依赖解析和批量写入均由 MoonBit 实现。构建后的可执行文件可直接运行，运行时无需 Node.js。

```powershell
moon update
moon build --frozen --release --target native cmd/ksymoon_native
moon run --frozen --target native cmd/ksymoon_native -- check fixtures/udp_datagram.ksy --json
moon run --frozen --target native cmd/ksymoon_native -- deps fixtures/stl.ksy
moon run --frozen --target native cmd/ksymoon_native -- generate fixtures/udp_datagram.ksy --out udp.mbt
moon run --frozen --target native cmd/ksymoon_native -- batch --out-dir generated fixtures/udp_datagram.ksy fixtures/stl.ksy
```

`moon build` 输出独立二进制的路径。`check --json` 返回 `ok` 和 `diagnostics`，错误记录含 `code`、`schema_path`、`message`，并返回非零退出码。`deps` 输出入口与解析后的依赖边，包含级联导入。三个命令与 `batch` 都支持 `--root`、`-I` 和 `--import`。

`batch` 在写入前先生成全部解析器并检查重名，按描述文件名输出 `generated/<名称>/<名称>.mbt`。每个解析器拥有独立的 MoonBit 包。把 `generated` 放在自己的 MoonBit 模块下即可构建。已有 `moon.pkg` 会保留，首次生成 zlib 包时会写入所需的标准库依赖声明。运行 `python scripts/native-cli-check.py` 可复验命令与生成源文件的四后端运行。

## 多文件描述和字节处理器

`v0.5.0` 允许 CLI 自动加载 `meta.imports`。相对路径从声明所在文件的目录查找，以 `/` 开头的描述依次查找 `-I` 目录和项目根目录。目录需要位于 `--root` 内。省略 `--root` 时使用输入描述所在目录。已有的 `--import NAME FILE.ksy` 可以显式覆盖指定名称。

```powershell
moon run --target js cmd/ksymoon -- generate formats/media/wav.ksy --root formats --out wav.mbt
```

库的 `generate_project` 和 `validate_project` 接收项目根下的入口相对路径、搜索目录和读取函数。开发版还可用 `on_import` 回调接收解析后的依赖边。导入子流的 `_root` 指向该次导入模块的根，模块内的 `_parent` 指向所属对象。可终止的递归引用受 64 层读取深度约束。

`process` 支持 `xor`、`rol`、`ror` 与 `zlib`。原始字段先完成字节边界读取，再处理字节，用户类型在处理结果的独立子流中解析。XOR 支持单字节值、字节数组常量和先前读取的字节字段。zlib 解压使用 MoonBit 标准库，单块解压上限为 16 MiB。使用 zlib 的生成包需要声明以下依赖。

```moonbit
import { "moonbitlang/core/compress/zlib" @ksy_zlib }
options("allow-experimental-packages": ["moonbitlang/core/compress/zlib"])
```

库、生成代码和消费断言使用 MoonBit。CLI 的 Node 适配负责文件访问和退出状态。官方对照运行原样描述、二进制样本和 Python 测试，涵盖相对及绝对导入、条件递归、跨模块定位和处理后的子流。

```powershell
python -m pip install kaitaistruct==0.11
python scripts/module-process-reference.py --registry
```

## WAV 与 RIFF

安装 Java 21、Python、Node.js 24 与 MoonBit v0.10.19，在本仓库运行：

```powershell
python -m pip install kaitaistruct==0.11
python scripts/wav-reference.py --registry
```

脚本在空白模块从 Mooncakes 安装 `bzhangui/ksymoon@0.5.0`，再在另一个空白模块重新生成并测试 WAV、RIFF、UDP、二进制 STL、STM32 采样帧和 IVF。WAV 与 RIFF 的原样描述来自固定修订并经过 SHA-256 核对。PCM、扩展 WAV、带填充的未知块、嵌套 LIST/INFO 和截断样本与 Kaitai 0.11 官方 Python 解析器对照。四个后端均执行检查、构建及测试。源码模式先运行 `moon update`，再运行 `python scripts/wav-reference.py --all-scenarios`。

使用自己的描述时，库接口 `generate_with_imports(source, imports)` 和 `validate_with_imports(source, imports)` 接受 `Map[String, String]`，键为 `meta.imports` 中的名字，值为原样描述文本。CLI 对应参数为 `--import NAME FILE.ksy`。例如：

```powershell
moon run --target js cmd/ksymoon -- generate wav.ksy --out wav.mbt --import /common/riff riff.ksy
```

命令中的显式映射会覆盖 `/common/riff` 的自动查找结果。缺失导入、重复声明、冲突的模块 ID 和无法终止的类型递归会报告诊断。条件终止的循环导入有对应测试。加载上游 WAV/RIFF 文件的来源和许可证见下方。

## 复现验收

```powershell
node scripts/verify.mjs
```

脚本更新 Mooncakes 索引，验证 CLI 的退出状态、诊断和输出文件保护，核对上游描述的 SHA-256，再在 `_build` 下新建独立消费模块。四个原有场景、基础特性、条件布局、流控制布局与 51 份原样上游兼容描述均重新生成，并与仓库源码逐字节比对。脚本在 JS、Wasm、Wasm-GC、Native 四个目标检查、构建和测试，演示命令继续运行 UDP、STL、STM32。

安装 Java 21 和 Python 后，可用 Kaitai 官方 0.11 编译器的 Python 目标生成对照解析器。脚本核对编译器 ZIP 的 SHA-256，执行 47 个原样上游 Python 测试及 120 项比较测试。对 47 组上游样本检查了 1,612 个真前缀，部分用例同时触发惰性实例读取。四后端每个目标通过 26 项生成器测试和 185 项消费测试。 [Kaitai 0.11 发布](https://github.com/kaitai-io/kaitai_struct_compiler/releases/tag/0.11)

```powershell
python -m pip install kaitaistruct==0.11
node scripts/verify.mjs --kaitai-reference
python scripts/compatibility-report.py --runtime-report
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

- `meta.id`、`meta.endian`、`meta.encoding`、`seq` 和按作用域解析的非递归本地及多层嵌套 `types`。
- `u1/u2/u4/u8`、`s1/s2/s4/s8`、`f4/f8` 和 `b1…b64`。`u8` 为 `UInt64`，`s8` 为 `Int64`。多字节类型可使用固定或按字段选择的 `meta.endian`，也可用类型后缀指定大小端。
- `contents` 固定签名支持 UTF-8 字符串，以及包含字符串和字节整数的数组。`valid` 支持类型化等值、范围、`any-of` 和 `expr`，可校验重复元素和惰性定位实例。
- `size`、`size-eos: true`、终止符字节字段及用户类型有界子流。父流一次消费完整边界，子流从 0 计数，内部 `pos` 被限制在子流内，惰性实例保留其所属流。
- `repeat: expr/eos/until` 数组。Until 在读取后判断并保留结束元素，支持 `_`、`_.整数成员`、`_index`、当前流位置和 EOF 条件。EOS 检查流边界和无进展迭代，重复项共享预算。长度与计数表达式支持非负常量、先前的 `u1/u2/u4` 标量字段，以及该字段减去非负整数。使用跨流实例的描述也支持经过检查的整数长度与计数表达式。
- `switch-on/cases` 支持常量整数、字符串及布尔标签，生成带载荷的 MoonBit 枚举。显式 `_` 默认分支按对应类型读取，未匹配的有界分支返回原始字节，未匹配的无界分支返回 `Unknown` 并跳过读取。
- `str/strz` 支持 ASCII、UTF-8、UTF-16LE/BE，支持字段或 `meta` 默认编码，以及 `terminator/pad-right/include/consume/eos-error`。UTF-16 `strz` 隐式终止符按双字节对齐，显式 `terminator` 按字节读取，非法编码提供字段与字节位置。
- `if` 条件标量、字节字段、嵌套记录和数组，结果生成为 `Option[T]`。条件为假时跳过读取、约束及重复项预留。
- `instances` 的 `pos` 定位读取、计数数组和 `value` 计算值，均按需求值并缓存成功结果，使用生成记录的同名方法访问，如 `record.entries()`。条件实例在求值为假时跳过定位与读取。
- `instances.io` 可选择当前流、根流、父对象流、字段或实例的子流，也支持按数组索引和条件选流。`pos` 相对所选流定位，实例表达式中的 `_io` 保持为所属对象的流。无 `pos` 时推进所选流，成功结果按需缓存。 [跨流用例](examples/consumer/io_wbtest.mbt)
- `if/value/pos` 支持类型化表达式，包括算术、比较、位运算、逻辑短路、条件表达式、实例依赖及 `_io.pos/_io.size`。字节和数组支持索引、长度及选定的首尾和极值操作，字节和字符串可按字典序比较。 [兼容范围与复现](docs/COMPATIBILITY.zh-CN.md)
- 生成的解析器读取描述指定的前缀。UDP 校验和作为字段返回，由调用者按使用场景校验。
- 对象、数组和流属性也可用于无 `io` 的描述。对象或流可作为惰性值实例返回，`.as<T>` 可将对象分支转换为确定的本地记录类型，类型不匹配时报告错误。
- 支持 32 位以内整数枚举、枚举字面量、条件与分支、值实例枚举及 `to_i`。未知枚举码保留在 `UnknownCode(Int64)` 中。支持整数、布尔和字符串参数，包含根解析入口及参数化本地类型调用。
- 导入支持相对和绝对查找，以及显式覆盖；字节处理支持 XOR、循环位移和 zlib。跨类型递归可经惰性实例进入，最多支持 64 层对象嵌套。
- 当前兼容盘点和剩余能力按 Kaitai Struct 0.11 语义矩阵记录。运行时错误包含字段路径和字节偏移，重复项共享 1,000,000 项预算。 [兼容目标与范围](docs/COMPATIBILITY.zh-CN.md)

## 来源与许可

KsyMoon 源码及 STM32 描述采用 MIT 许可证。UDP、STL 和 IVF 描述按 Kaitai Struct 上游提交 `30e7ad51e8c870d3a098cd618c0f4b2797efc538` 原样保存，采用各自文件内的 CC0-1.0 许可。 [UDP 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/network/udp_datagram.ksy) · [STL 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/media/stl.ksy) · [IVF 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/media/vp8_duck_ivf.ksy)

51 份兼容描述与其中 47 组二进制和 Python 测试说明来自 Kaitai 官方测试库，按固定修订原样保存，采用上游 MIT 许可证。MoonBit 中的期望值及前缀结果由官方解析器生成，其他布局、生成器、读取模板及边界断言由项目实现。官方编译器与 Python 运行时仅用于测试对照。 [测试来源与哈希](fixtures/kaitai/manifest.json) · [上游许可证](fixtures/kaitai/LICENSE)

WAV 与 RIFF 描述从相同固定修订按需下载，分别保留上游文件声明的 BSD-3-Clause-Attribution 与 CC0-1.0。WAV 描述由 John Byrd（Gigantic Software）编写。两份描述和相应生成文件保存在本地构建目录。 [原样 WAV](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/media/wav.ksy) · [原样 RIFF](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/common/riff.ksy) · [WAV 许可](https://spdx.org/licenses/BSD-3-Clause-Attribution.html)

动态字节序对照脚本按需下载同一修订的 Exif 描述，核对 SHA-256 并保存在本地构建目录，保留其 CC0-1.0 许可。 [原样 Exif](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/image/exif.ksy)

WAV/RIFF 实现通过 [MoonBit v0.10.19 CI](https://github.com/bzhangui/KsyMoon/actions/runs/45331862218)。固定语料的 339 份描述中，160 份可生成并在四后端构建，179 份保留诊断，51 份有运行对照。WAV 与 RIFF 的官方对照和递归限制共 9 项测试在四后端通过。 [固定语料报告](docs/reports/kaitai-0.11-p4-2026-11-24.json) · [WAV/RIFF 报告](docs/reports/wav-riff-2026-11-24.json)

定位实例失败后的游标策略有一处已知差异。KsyMoon 恢复游标和本次重复项预算，便于失败后重试。官方 Python 0.11 会保留失败位置。正常结果、成功定位恢复和失败接受判定已对照，失败后的游标策略另有专门回归。更多编码、集合表达式和模块导入仍按后续矩阵推进。

2026-11-19 补充组合核验后，已修复动态负长度被误判为无界读取、UTF-16 显式终止符消费宽度，以及纯计算嵌套记录的生成与实例方法归属问题。新增 9 项边界回归和 7 项官方对照，覆盖零长度、负长度、隐式/显式终止符、只读实例、流查询、重复和同名子类型。 [边界测试](examples/consumer/reader_edges_wbtest.mbt)

发布前可执行 `python scripts/package-check.py` 检查真实本地归档。CI 用未跟踪的申报书占位文件验证 `.moonignore` 排除规则，同时确认必需源码与许可证存在，并上传内容报告；这一步只打包和检查。

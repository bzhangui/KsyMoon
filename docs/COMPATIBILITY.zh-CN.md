# Kaitai Struct 0.11 兼容目标与验收计划

## 兼容终点

KsyMoon 的目标是在 MoonBit 中实现 Kaitai Struct 0.11 的完整描述语言与二进制读取语义，生成可独立使用的类型化解析器。v1.0 的交付范围覆盖语法、表达式、类型与流语义、运行时错误、依赖解析及标准处理器。编译器和运行时的核心逻辑由 MoonBit 承担。 [语言指南](https://doc.kaitai.io/user_guide.html) · [官方编译器 0.11](https://github.com/kaitai-io/kaitai_struct_compiler/releases/tag/0.11)

2026-11-18 的初审反馈指出，v0.2.0 把条件字段和 instances 排除在交付目标之外，缺少完整兼容终点。本计划以标准能力和固定测试集作为验收依据，按阶段推进到完整目标。Mooncakes 已发布 `v0.4.0`，增加 WAV/RIFF 支持。完整标准语义继续按 v1.0 门禁验收。 [发布验收记录](reports/mooncakes-0.4.0.json)

## 固定基线

- 语义基线采用官方编译器 0.11 和 Python `kaitaistruct==0.11`。与 MoonBit 的 JS、Wasm、Wasm-GC、Native 四个目标逐字段比较正常结果、条件缺省值和惰性行为。
- 官方测试库固定在 `4108136c807f8df88df843de6571f1a7bf29c74e`，其 `formats/` 下共有 339 份描述。每次 CI 盘点全部文件，包括依赖其他文件、需要更多语义、故意验证失败等用例。 [测试库快照](https://github.com/kaitai-io/kaitai_struct_tests/tree/4108136c807f8df88df843de6571f1a7bf29c74e)
- 测试归档 SHA-256 固定为 `3a78e2ffb3938c18b5c1d2f06f3bc8567bc72e054a8e68f0ddacbfa1406937fe`。51 份直接复用的测试描述及其中 47 组二进制样本及 Python 测试说明另有逐文件哈希和原 MIT 许可证。 [输入清单](../fixtures/kaitai/manifest.json) · [许可证](../fixtures/kaitai/LICENSE)
- 已生成的解析器必须在独立模块通过四后端的检查和构建。二进制运行与参考对照另行统计，所有未完成项保留诊断。

## 已完成 P1

已实现并纳入正式复现流程的内容如下。

1. **条件字段**。`if` 在读取前求值，条件为假时返回 `None`，并跳过读取、校验和重复项预留。条件可以作用于标量、字节字段、嵌套记录和计数数组。
2. **解析实例**。支持根类型及本地类型的 `instances`，按需读取并缓存成功结果，支持 `pos`、条件实例和计数数组。带 `pos` 的读取在成功与失败时恢复原游标。无 `pos` 的读取在当前位置解析并推进游标。
3. **值实例**。`value` 可引用当前类型的非可选整数标量及其他非条件整数或布尔实例。值在首次调用时计算，成功后缓存。引用环提供描述期诊断或运行时错误，失败后释放实例求值标记。
4. **表达式基础**。支持有符号 64 位整数与布尔字面量、字段或实例引用、括号、算术、比较、逻辑短路、位运算、条件表达式，以及 `_io.pos` / `_io.size`。整数除法与取模遵循 Kaitai 的 floor 规则。溢出、除零和非法移位提供可诊断错误。
5. **兼容回归**。四份原样上游描述覆盖条件实例、条件值实例、定位数组实例和负数整除。自定义布局另外覆盖条件数组、惰性读取、缓存、游标、重试、资源预算、短路、溢出和实例环。

当前数值字段引用覆盖 32 位以内整数。支持跨流实例的描述可使用受类型检查的整数长度和计数表达式，以及选择流所需的对象路径。P3 已将本轮验证的对象与流导航扩展到普通描述。

## 本轮 P2 实现与证据

开发版 `0.3.0-dev.4` 的跨流实现为 [19718d2](https://github.com/bzhangui/KsyMoon/commit/19718d283efd782ccd24fd753c83b353b0c95d09)，已通过固定 MoonBit v0.10.19+97801ee1b 的四后端 CI。 [同提交 CI](https://github.com/bzhangui/KsyMoon/actions/runs/45185761258) · [完整 339 份报告](reports/kaitai-0.11-p2-io-2026-11-23.json)

| 能力 | 已实现语义与运行证据 |
| --- | --- |
| 有界子流 | 用户类型的 `size` / `size-eos` / 终止符产生独立流，父流消费边界，子流位置从 0 开始，实例保留原子流。验证相对定位、成功游标恢复、重复失败重试、子流越界和截断。 |
| 重复 | 支持 `expr/eos/until`。EOS 在当前流结束，Until 读取后判断并保留终止元素，支持 `_`、`_.整数成员`、`_index` 与流状态。零字节 Until 可以按索引正常终止，EOS 无进展提供诊断，所有子流共享重复项预算。 |
| 类型分支 | 整数、字符串和布尔标签，分支为已支持的数值或本地用户类型，输出带载荷枚举。验证默认分支、无界未知分支不读取、有界未知分支保留原始字节及零长度边界。嵌套 `types` 按作用域解析。 |
| 字符串与字节选项 | `str/strz` 的 ASCII、UTF-8、UTF-16LE/BE，字段或 `meta` 默认编码，`size-eos`、`terminator`、`pad-right`、`include`、`consume`、`eos-error`，UTF-16 `strz` 隐式终止符按双字节对齐，显式 `terminator` 按字节处理，严格校验解码。与官方对齐同字节填充和终止符时的 `include` 行为。 |
| 跨流实例 | 可选择自身、根、父对象、已读字段、惰性实例或数组成员的流，支持条件选流与父对象读取期间访问实例。`pos` 相对目标流，表达式中的 `_io` 仍是所属对象的流，`size-eos` 按目标流计算。验证缓存、成功定位恢复、无定位推进、截断重试和重复预算。 |
| 输入原样性 | 39 份上游 `.ksy` 及其中 35 组二进制和 Python 测试保持原字节。输入、样本、断言和官方编译器 ZIP 均校验 SHA-256。 |

跨流补齐了 P2 中的选流能力。新增 `instance_io_user`、`instance_io_user_earlier`、`nav_parent2` 和 `nav_parent3` 四份原样上游用例，覆盖共享字符串子流、解析期间动态选流、跨根流分支和定位数组。四后端各通过 **22 项生成器测试和 158 项消费测试**，其中有 **94 项官方对照**。39 份上游描述已有运行对照，其中 35 份执行原样上游 Python 测试。1,095 个上游真前缀中，1,030 个拒绝、65 个接受。新跨流用例的前缀判定还会访问相应的惰性实例。UDP、STL、STM32 和 IVF 持续通过。 [对照断言](../examples/consumer/stream_reference_wbtest.mbt)

### 2026-11-19 补充组合核验

常规复现最初通过 19 + 121 项测试，随后新增的独立组合用例发现了三类缺陷，已加入修复和回归。

| 组合 | 修复前 | 修复及核验 |
| --- | --- | --- |
| `size: n - 1` 配合终止符或填充，且 `n == 0` | `-1` 可能与无界读取标记混用，接受错误数据或给出错误诊断 | 使用独立的有界/终止符读取模式，负长度返回 `InvalidLength`。核验负、零、正常长度与条件跳过。 |
| UTF-16 显式 `terminator` | 读取时错误地按双字节消费，丢掉后续一个字节 | 显式终止符为单字节，只有 `strz` 隐式终止符随编码扩展。与官方比较字符串及后续原始字节，并验证 `include` 导致的编码错误。 |
| 只含计算实例的本地类型、流查询、重复及与根同名的子类型 | 输出可能含无用的读取/抛错代码，或把子类型实例方法归到根类型，严格编译失败 | 按实际读取和表达式传播效果，保留必要输入与定位能力，并明确区分根记录和子记录。生成代码在四后端独立构建和运行。 |

新增 **9 项回归 + 7 项官方对照**。原样上游输入、948 个前缀和全部 339 份盘点保持不变。 [回归断言](../examples/consumer/reader_edges_wbtest.mbt) · [官方对照生成](../scripts/kaitai-reference.py)

**已知边界。** 定位实例读取失败后，KsyMoon 恢复游标与本次预算，官方 Python 0.11 保留失败位置。现有对照覆盖正常结果、成功定位的恢复和截断判定，失败状态另有本地回归。当前还受 1,000,000 项重复预算、32 位数值字段引用和类型推导范围限制。P3 已覆盖 `io_local_var.ksy` 的对象转换。跨流与处理器混用仍依赖 P4。

## 2026-11-23 P3 类型与表达式进展

开发版 `0.3.0-dev.5` 实现提交为 [95dfd8a](https://github.com/bzhangui/KsyMoon/commit/95dfd8ad1fec962fd8f293fa28131b53f63e50df)。四后端各通过 **24 项生成器测试和 177 项消费测试**，其中 112 项为官方对照，43 项原样上游 Python 测试通过。1,429 个上游真前缀的判定一致，其中 1,115 个拒绝、314 个接受。 [实现 CI](https://github.com/bzhangui/KsyMoon/actions/runs/45191577558) · [完整报告](reports/kaitai-0.11-p3-2026-11-23.json)

| 能力 | 本轮验证 |
| --- | --- |
| 普通描述导航与对象转换 | 原样 `io_local_var` 验证定位实例后的顺序读取。`expr_io_ternary` 验证两种对象与流选择、流位置、流大小和 EOF。自定义回归覆盖嵌套目标类型、错误分支和无匹配分支。 |
| 整数枚举 | 原样 `enum_if`、`enum_of_value_inst`、`enum_to_i` 核验整数枚举、条件分支、值实例与数值转换。未知枚举码保留为 `UnknownCode(Int64)`。 |
| 标量参数 | 原样 `params_call`、`params_def`、`params_call_extra_parens` 核验本地类型传参、根入口参数、表达式实参和动态长度。参数个数、类型和整数范围有诊断。 |

本轮覆盖 32 位以内整数枚举，以及有符号整数、32 位以内无符号整数、布尔和字符串参数。枚举或复合值参数、完整数值提升、集合操作和受限递归继续按 P3 门禁验收。

## 后续阶段及完成条件

| 阶段 | 标准能力与工程交付 | 进入下一阶段的门禁 |
| --- | --- | --- |
| P2 流与控制结构 | `size` 有界子流、`size-eos`、`repeat: eos/until`、`switch-on/cases`、`instances.io`、字符串、终止符、填充及完整字节读取选项 | 对应上游描述与二进制样本原样运行，验证子流相对位置、EOF、空分支及截断 |
| P3 类型和表达式 | `enums`、`params`、嵌套类型、受限递归、`_root/_parent/_index`、数组和对象属性、类型转换、字符串与集合操作、完整数值类型及类型提升 | 固定测试库的 `expr_*`、`params_*`、`enum_*` 等相关用例与官方结果一致，混合条件和流场景一起回归 |
| P4 模块与处理器 | 外部 `imports` 的显式描述映射及 CLI 受限路径解析、动态字节序、位域、`process` 标准处理器、编码表、外部类型和自定义处理器接入机制、标准验证表达式及元数据 | 依赖图、循环、路径约束、编码与处理错误有测试，固定测试库的对应用例通过，处理器协议有可运行适配示例 |
| P5 标准验收与 1.0 | 对照完整语言指南核对能力矩阵，执行全部固定上游描述及其适用二进制和断言，补真实格式及独立消费项目 | 下述 v1.0 门禁全部通过后发布 |

各阶段按前序门禁完成后推进。升级上游版本时单独变更固定修订和测试基线，记录新增能力及回归结果。

## 2026-11-24 验收发布与 WAV/RIFF

`v0.3.0` 的 Git 标签和 Mooncakes ZIP 对应同一源码。发布后从 Mooncakes 在全新生成模块安装，再建立独立项目，通过四后端的 UDP 和跨流实例正常与截断检查。 [发布记录](reports/mooncakes-0.3.0.json)

开发版取得 WAV/RIFF 的端到端对照。原样 WAV 通过 `/common/riff` 导入原样 RIFF。测试覆盖 PCM、扩展 WAV 声道位图、未知块的奇数长度填充、RIFF 嵌套 LIST、字节索引、编码转换和条件字符串。4 个完整输入和 246 个真前缀与官方 0.11 的结果一致。 [复现脚本](../scripts/wav-reference.py) · [实现 CI](https://github.com/bzhangui/KsyMoon/actions/runs/45331862218) · [WAV/RIFF 报告](reports/wav-riff-2026-11-24.json)

现有导入由调用方显式提供描述；单个图最多 16 个导入。涉及跨模块根/父对象的描述等待后续支持。位整数支持 1 到 32 位，大小位序只在字节边界切换。允许通过惰性实例出现的类型环，顺序读取中的类型环给出诊断，运行中对象深度最多 64 层。跨文件导入、位字段更宽类型、表达式和处理器继续按矩阵推进。

### v0.4.0 发布复验

发布提交 `e04895a` 通过 MoonBit v0.10.19+97801ee1b 的四后端 CI。归档的 340 个文件与发布前检查及 Mooncakes 安装后的内容一致，归档 SHA-256 与注册表一致。全新模块安装后，六个解析器重新生成，源码哈希与 CI 一致。JS、Wasm、Wasm-GC、Native 各通过 25 项测试，其中 WAV 和 RIFF 保持与 Kaitai 0.11 的 4 个完整输入、246 个真前缀和递归限制检查。固定语料盘点结果仍为 160 份生成构建、179 份诊断、51 份有运行对照。 [源码标签](https://github.com/bzhangui/KsyMoon/tree/v0.4.0) · [发布版 CI](https://github.com/bzhangui/KsyMoon/actions/runs/45344575642) · [发布复验证据](reports/mooncakes-0.4.0.json)

## v0.5.0 开发版的模块与处理器

`0.5.0-dev.1` 自动读取同项目内的相对、搜索根绝对和级联导入，保持显式映射接口。导入记录各自维护模块根、模块内父对象及子流，跨模块的惰性定位与条件递归纳入回归。兼容盘点按上游目录结构备齐依赖，再对同一批 339 份原样描述逐份生成、检查和构建。

字节处理支持 `xor`、`rol`、`ror` 和 zlib。处理后子流使用独立读取边界，zlib 使用 MoonBit 标准库，并限制单块解压输出至 16 MiB。任意自定义处理器、动态字节序完整语义及其余类型和表达式覆盖继续按能力矩阵推进。

固定上游的五个导入用例及十个处理器用例由 Kaitai 0.11 生成 Python 参考解析器。补充的 MoonBit 消费测试检查模块本地 `_root`、`_parent`、`instances.io` 的共享子流、递归深度和 zlib 校验和。 [复现脚本](../scripts/module-process-reference.py)

固定语料已通过 **188 份生成并在四后端构建**，较 v0.4.0 增加 28 份，151 份保留诊断。新增模块和处理器测试每个后端通过 34 项，并与官方对照 893 个真前缀。 [实现 CI](https://github.com/bzhangui/KsyMoon/actions/runs/45350536553) · [开发版报告](reports/kaitai-0.11-modules-process-2026-11-24.json)

## v0.6.0 开发版的动态字节序和宽数值

`meta.endian` 可根据字段选择大小端，子类型和定位实例继承读取上下文，显式带后缀的类型使用其指定字节序。增加 `s8`、`f8`、33–64 位位域及实数实例计算。原样上游 Exif 描述生成后比较大小端数据的目录偏移、标签及截断结果。 [对照脚本](../scripts/numeric-endian-reference.py)

## v0.7.0 开发版的表达式与值校验

字节和数组表达式可执行索引、长度、首尾和最小最大值操作。字节与字符串按字典序比较。`valid` 增加类型化等值、范围、`any-of` 和 `expr`，验证可定位到重复元素或惰性实例。新增对照包括官方预期的验证失败，检查错误类别和读取位置。 [对照脚本](../scripts/expression-validation-reference.py)

## v0.9.0 开发版的参数与枚举

参数增加布尔位、整数与字符串数组、流、对象引用及枚举。定位实例和复合参数可共享原对象、数组与流。调用方通过生成的对象引用访问对应的记录类型。枚举支持跨模块和多层类型作用域，以及能表示为 `Int64` 的位域和有符号 64 位字段。`python scripts/type-parameter-reference.py` 生成并构建 30 份原样上游描述，其中 24 份有对应的官方 Python 测试与 MoonBit 运行对照。

## v0.9.0 开发版的图像与尺寸语义

固定尺寸表达式计算字段、子流和嵌套记录的宽度。新增 4 份原样尺寸用例，补充根对象参数的上下文检查，以及 `valid: in-enum`、字符串切片和单字节解码的运行对照。PNG 与 ICC、Exif 的链接描述可包含最多 256 个类型定义，运行时递归深度与既有资源预算仍分别检查。`python scripts/image-reference.py` 验证原样 GIF、BMP、PNG 的正常字段、已知截断差异和惰性配置文件读取。

## v0.10.0 开发版的 ZIP 与上游运行覆盖

生成器支持 Kaitai 上下文表达式中的两个字符串相加。原样 ZIP 通过 `/common/dos_datetime` 导入 DOS 日期描述，用条件表达式及 `to_s` 生成带前导零的日期与时间。两个上游文件均为 CC0-1.0，测试按固定提交下载并核对 SHA-256。 [原样 ZIP](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/archive/zip.ksy) · [原样 DOS 日期](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/common/dos_datetime.ksy)

ZIP 测试比较 Stored 和 Deflate 条目的原始数据、UTF-8 文件名、CRC 字段、目录偏移、按需查找本地文件头和 DOS 时间。空归档、全部真前缀、错误签名及越界的本地头偏移均与官方解析器对照。当前验证范围是 ZIP 结构解析及压缩数据读取。 [ZIP 对照](../scripts/zip-reference.py)

固定语料新纳入 45 份原样 `.ksy`，执行原样二进制样本和 Python 测试，再由独立 MoonBit 消费模块逐字段复跑 170 项断言。覆盖位域、枚举、终止与填充、嵌套、定位和重复。CI 单独上传 `extended-runtime-report.json` 和 `zip-reference-report.json`，保留输入哈希与四后端结果。 [语料对照](../scripts/corpus-runtime-reference.py)

## v0.11.0 的表达式、动态长度与格式对照

字符串拼接支持字面量、字段和实例引用。整数比较保留 `UInt64` 的完整范围，并按数值比较有符号和无符号操作数。有界读取的 `size` 和 `repeat-expr` 可以使用 `UInt64`，超出 `Int64` 范围时返回字段与偏移诊断，转换后仍检查剩余字节和重复项预算。`repeat-expr` 可以在读取前触发惰性实例求值。 [表达式与校验对照](../scripts/expression-validation-reference.py)

MIDI 从原样 Standard MIDI 和 VLQ 描述生成，验证轨道、事件、变长长度及截断。JPEG 从原样 JPEG 和 Exif 描述生成，验证段结构、两种字节序的 Exif 目录和定位读取。四份描述按固定提交下载并核对 SHA-256，保留上游文件的 CC0-1.0 许可。 [MIDI 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/media/standard_midi_file.ksy) · [VLQ 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/common/vlq_base128_be.ksy) · [JPEG 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/image/jpeg.ksy) · [Exif 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/image/exif.ksy)

新增 35 份原样上游语料运行对照及 182 条字段断言，独立语料套件在每个后端执行 80 份官方用例和 352 条字段断言。CI 上传语料和格式报告，并继续验证全部 339 份固定语料的生成与构建状态。 [语料复现](../scripts/corpus-runtime-reference.py) · [MIDI 与 JPEG 复现](../scripts/midi-jpeg-reference.py)

## v0.12.0 开发方向

以 `v0.11.0` 的 278 份四后端构建和 202 份具名运行对照为基线，优先修复读取上下文与结构描述。61 份首个诊断中，14 份涉及读取时机或对象上下文，9 份涉及空布局或匿名字段。其余诊断按表达式与编码、调试、外部扩展、枚举与分支以及缺失依赖分别保留。 [固定语料](https://github.com/kaitai-io/kaitai_struct_tests/tree/4108136c807f8df88df843de6571f1a7bf29c74e)

首批处理流位置参与长度计算、算术重复计数，以及序列条件和终止条件触发的惰性实例。使用 `expr_io_pos`、`repeat_n_strz_double`、`instance_in_repeat_until`、`instance_in_sized` 和 `valid_fail_inst` 验证有界读流、首次求值时机、游标恢复和预期失败。 [复现脚本](../scripts/reader-context-reference.py)

后续补齐空结构、匿名字段、显式父对象与递归根引用。空结构仍须遵守外层有界读取，递归用例须验证前进、深度限制和截断。调试元数据单独验证显式读取与位置记录，绝对导入用例单独固定依赖来源。 [重复与流语义](https://doc.kaitai.io/user_guide.html#_streams_and_substreams)

## v1.0 门禁

- 语言指南中的全部描述、表达式和流语义都有明确实现与测试入口。标准未知键或类型不能静默忽略。
- 固定测试库的 339 份描述全部有结果，合法描述必须生成并编译，预期错误必须与上游判定一致。依赖描述和目标扩展有可核验的适配记录。
- 从官方测试说明和断言建立逐用例运行映射，比较所有可观测字段、可选值、数组、计算实例、缓存和流位置。意图为读取失败的样本必须被正确拒绝。
- 四个 MoonBit 后端通过相同的检查、构建及语义测试。原有 UDP、STL、STM32、IVF 与上游新场景持续回归。
- 公开兼容报告同时列出描述总数、生成与编译状态、运行对照状态、失败诊断及工具链版本。当前的语法接受率只能说明描述覆盖进度。
- 从 Mooncakes 发布候选包创建空缓存项目，重新生成真实格式解析器并运行跨后端验证。API、文档、来源许可、打包内容及公开提交与发布包一致。

## 复现与报告

```powershell
python -m pip install kaitaistruct==0.11
node scripts/verify.mjs --kaitai-reference
python scripts/native-cli-check.py
python scripts/module-process-reference.py
python scripts/numeric-endian-reference.py
python scripts/expression-validation-reference.py
python scripts/type-parameter-reference.py
python scripts/corpus-runtime-reference.py
python scripts/reader-context-reference.py
python scripts/compatibility-report.py --runtime-report
python scripts/wav-reference.py --all-scenarios
python scripts/image-reference.py
python scripts/zip-reference.py
python scripts/midi-jpeg-reference.py
```

第一条复现脚本重新生成解析器，在独立模块构建、测试并与官方目标对照。兼容盘点脚本检查全部 339 份描述，报告保存为 `_build/compatibility-report.json`，CI 将其作为 `kaitai-compatibility-inventory` 附件上传。

`generated` 表示描述已接受、源码已输出并通过独立四后端检查和构建。报告中的 `runtime_oracle_schemas` 单列已执行官方语义对照的上游描述。v0.4.0 的固定盘点为 **160 份生成、179 份保留诊断**，全部 339 份都保留结果。51 份固定上游描述已有运行对照，其他生成条目的运行对照继续按 P3—P5 建立。`--runtime-report` 要求前一复现步骤已成功，报告中的运行记录必须与当前提交及工作区状态一致。

`v0.9.0` 在同一固定语料中有 **270 份生成并构建、69 份保留诊断**，比 `v0.8.0` 候选基线多 39 份。CI 继续盘点开发版的全部 339 份描述。数值、校验、模块、参数和图像的运行对照分别输出报告，条目可能与基础对照重叠。Native CLI 的报告单独记录运行平台、依赖解析与批量生成后的四后端验证。

[v0.4.0 固定语料报告](reports/kaitai-0.11-p4-2026-11-24.json)保留全部 339 行。WAV 与 RIFF 是额外的格式库用例，单独计入 [WAV/RIFF 报告](reports/wav-riff-2026-11-24.json)。

## 发布内容核验

`python scripts/package-check.py` 检查归档内容、本地文件排除规则、必需源码及许可证。CI 上传 `_build/package-content-report.json`。从标签 `v0.9.0` 运行 `python scripts/wav-reference.py --registry` 和 `python scripts/image-reference.py --registry`，从 Mooncakes 在空白模块安装，再用独立模块重跑九个场景。`node examples/quickstart/run.mjs --all-targets` 运行 UDP 和跨流实例的快速示例。 [v0.9.0 发布验收记录](reports/mooncakes-0.9.0.json)

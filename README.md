# KsyMoon

KsyMoon 把 Kaitai Struct 的 `.ksy` 描述生成为带类型的 MoonBit 二进制解析器。生成的源码只依赖 MoonBit 标准库。

## 生成并运行

安装 MoonBit 与 Node.js，在仓库根目录执行以下命令。本阶段使用 Windows 上的 `moonc v0.10.14` 和 Node.js 24 验证，生成器的 YAML 依赖锁定为 `moonbit-community/yaml@0.0.7`。

```powershell
moon run --target js cmd/ksymoon -- generate fixtures/udp_datagram.ksy --out examples/consumer/udp/udp_datagram.mbt
moon run --target js cmd/ksymoon -- generate fixtures/stl.ksy --out examples/consumer/stl/stl.mbt
moon -C examples/consumer test --target all --deny-warn
moon -C examples/consumer run --target js .
```

`examples/consumer` 有自己的 `moon.mod`，从自身的 `udp` 和 `stl` 包调用 `parse_udp_datagram(Bytes)` 和 `parse_stl(Bytes)`。在自己的模块里使用时，先创建目标包和 `moon.pkg`，再把生成的文件写入该包。

## 复现验收

```powershell
node scripts/verify.mjs
```

脚本核对两份上游 `.ksy` 的 SHA-256，在 `_build` 下新建独立消费模块，再生成解析器并逐字节比对仓库中的示例源码。脚本检查、构建、测试并运行 JS、Wasm、Wasm-GC、Native 四个目标，保留隔离目录以便查看生成物。

| 样本 | 验收结果 |
| --- | --- |
| 正常 UDP | 端口 `1234 → 5678`，声明长度 11，负载 `ABC` |
| 截断 UDP | `udp_datagram.body` 从字节偏移 8 开始，需要 3 字节，剩 2 字节 |
| 非法 UDP 长度 | 报文长度字段小于 8 时返回 `UdpDatagramInvalidLength` |
| 正常二进制 STL | 两个三角面，第二个三角面的第二个顶点为 `(-0.5, 2.5, 0)`，属性为 `0x5678` |
| 截断 STL | `stl.triangles[1].abr` 从字节偏移 182 开始，需要 2 字节，剩 1 字节 |
| 异常 STL 计数 | `0xffffffff` 三角面计数触发重复项上限 |

报文和模型数据均为测试中构造的字节样本，偏移与数组索引从 0 开始。

## 支持的描述子集

- `meta.id`、`meta.endian`、`seq` 和非递归本地 `types`。
- `u1`、`u2`、`u4`、`f4`。多字节类型采用 `meta.endian` 或类型的显式大小端后缀。
- `size` 字节字段和 `repeat: expr` 数组。长度表达式支持非负常量、先前的无符号标量字段，以及该字段减去非负整数。
- 生成的解析器读取描述指定的前缀。UDP 校验和作为字段返回，由调用者按使用场景校验。
- 生成器遇到 `instances`、条件字段、导入等超出子集的键时，返回对应的描述路径。运行时报告字段路径、字节偏移及截断、非法长度或计数超限。单次解析最多处理 1,000,000 个重复项，嵌套数组的元素计入同一总额。

## 来源与许可

KsyMoon 源码采用 MIT 许可证。两份格式描述按 Kaitai Struct 上游提交 `30e7ad51e8c870d3a098cd618c0f4b2797efc538` 原样保存，采用各自文件内的 CC0-1.0 许可。 [UDP 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/network/udp_datagram.ksy) · [STL 原件](https://github.com/kaitai-io/kaitai_struct_formats/blob/30e7ad51e8c870d3a098cd618c0f4b2797efc538/media/stl.ksy)

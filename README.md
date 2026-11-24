# FPGA 体感交互与环境光自适应显示系统

基于 **Digilent Nexys A7-100T**、Verilog HDL 和 Vivado 的三人课程设计。目标是采集 Pmod GYRO 与 Pmod ALS 数据，通过姿态控制 VGA 小球，并按环境光调节画面亮度；后续扩展重力滚球、迷宫和计时计分。

仓库：[sixi3254/FPGA-Course-Design](https://github.com/sixi3254/FPGA-Course-Design)。远程维护 `main` 和 `develop`，成员各自克隆、使用 Tcl 创建本地工程。

**当前是开发框架。** 顶层接口、复位、时钟使能、输入同步消抖、公共常量、共享地图和引脚约束已建立；三个子系统保留明确的占位输出。SPI 驱动、传感器处理、VGA 时序/绘图、姿态/运动/游戏逻辑及 Testbench 由成员后续开发。当前 SPI 不发起事务，VGA 不产生视频。

## 1. 仓库内容与分工

```text
FPGA_Motion_System/
├── rtl/
│   ├── top.v                 # C：板级顶层与子系统连接
│   ├── common/               # C：复位、使能、输入同步消抖
│   ├── include/              # 全组共用：常量和地图，C 主维护
│   ├── sensor/               # A：传感器、SPI、滤波与亮度映射
│   ├── video/                # B：VGA、帧锁存、渲染与 RGB 调光
│   └── motion/               # C：姿态、运动、碰撞与游戏
├── sim/
│   ├── sensor/               # A：待实现的单元/子系统 TB
│   ├── video/                # B：待实现的单元/子系统 TB
│   ├── motion/               # C：待实现的单元/子系统 TB
│   ├── models/               # A：待实现的传感器仿真模型
│   └── tb_system_top.v       # 全组：待实现的系统 TB
├── constraints/
│   ├── board_common.xdc      # 时钟、复位、拨码、按钮、配置电压
│   ├── sensor.xdc            # GYRO / ALS 管脚
│   ├── video.xdc             # VGA 管脚
│   ├── timing.xdc            # 时序约定与待补充的外部接口时序
│   └── async_controls.tcl    # 异步控制输入的定向同步例外
├── scripts/
│   ├── config.tcl            # 器件、目录、默认 TB 和构建参数
│   ├── create_project.tcl    # 创建本机 Vivado 工程
│   ├── sync_sources.tcl      # 同步源码、约束和仿真集合
│   ├── run_sim.tcl           # 仿真辅助命令
│   └── build.tcl             # 综合、实现、报告和比特流
├── tools/                    # 后续软件参考模型/帧查看工具占位
├── .gitattributes
├── .gitignore
└── README.md
```

| 成员 | 主要范围 | 独立验证输入 | 对外交付 |
| --- | --- | --- | --- |
| A | `rtl/sensor/`、`sim/sensor/`、`sim/models/` | 模拟 SPI 从设备 | 校准滤波后的三轴数据、状态和亮度增益 |
| B | `rtl/video/`、`sim/video/` | 模拟坐标、姿态、状态与增益 | VGA 输出和帧同步 |
| C | `rtl/motion/`、`rtl/common/`、`sim/motion/`、顶层与脚本 | 模拟有效陀螺仪样本 | 姿态、坐标、游戏状态与系统集成 |

公共端口、常量、地图、时钟与复位修改需要受影响成员评审。传感器约束由 A/C 核对，显示约束由 B/C 核对。Vivado 的 Hierarchy 表示实例关系；成员文件归属以磁盘目录为准。

Git 只上传本 README、RTL、公共头文件、XDC/Tcl 约束、必要的构建脚本、团队 TB/模型占位和工具占位。其他 Markdown、`docs/`、本地验证文件 `local_tests/`、本地初始化辅助脚本及 `vivado/`、`output/`、缓存、日志和波形均不上传。后续成员正式编写的 `sim/` 测试应随源码提交。

## 2. 统一硬件与接口

| 项目 | 约定 |
| --- | --- |
| 开发板 / 器件 | Nexys A7-100T / `xc7a100tcsg324-1` |
| 工具 | **Vivado 2025.2**，三人统一版本，安装 Artix-7 器件支持 |
| 语言 | RTL 使用 Verilog-2001，仿真时间单位为 `` `timescale 1ns/1ps `` |
| 时钟 / 复位 | 100 MHz 单时钟域，内部 `clk` / 高有效 `rst` |
| 像素与采样 | `pix_ce` 每四拍；`tick_100hz` / `tick_20hz` 为单拍调度使能 |
| VGA | 640×480，RGB444，像素更新率 25 MHz，约 59.52 Hz |
| 传感器 | Pmod GYRO（L3G4200D）和 Pmod ALS（ADC081S021），SPI 目标 2 MHz |
| 姿态与速度 | signed Q16.16；速度单位为 pixel/tick |
| 小球 | 半径 15，普通初始圆心 `(320,240)`，游戏起点 `(70,70)` |

子系统的完整端口定义以 [sensor_top.v](rtl/sensor/sensor_top.v)、[motion_top.v](rtl/motion/motion_top.v) 和 [video_top.v](rtl/video/video_top.v) 为准；连接见 [top.v](rtl/top.v)。任何公共端口、位宽、单位和有效时序的变化必须由受影响成员一起处理。

| 通路 | 信号 | 合同 |
| --- | --- | --- |
| A → C | `gyro_x/y/z` | signed 18 位，校准滤波后的原始 LSB；不是角度或 Q16.16 |
| A → C | `gyro_valid`、`gyro_ready` | ready 高且 valid 的上升沿消费一个样本；缺样不重复积分 |
| A → 顶层/B | `gyro_fault`、`light_ready`、`light_level` | 异常/就绪状态和 8 位滤波光照 |
| A → 顶层 → B | `brightness_gain` → `display_gain` | 5 位，16 表示原始亮度；自动亮度关闭或光照未就绪时选 16 |
| C → B | `ball_x/y` | unsigned 10 位圆心，左上角原点，X 向右、Y 向下 |
| C → B | `angle_x/y`、`velocity_x/y` | signed 32 位 Q16.16 |
| C → B | `game_state`、`score`、`time_left` | 分别为 3 / 16 / 7 位 |
| B → 顶层 | `frame_tick` | 一拍帧事件，后续用于锁存场景参数 |

发送端将数据和 valid 一起寄存；接收端在 valid 有效的时钟上升沿读取。每个有效样本最多触发一次姿态/运动更新；X/Y 同时提交。B 在帧边界锁存坐标和状态，后续渲染流水线须同步延迟 HS/VS 和有效区信号。

公共定义见 [project_defs.vh](rtl/include/project_defs.vh) 和 [maze_map.vh](rtl/include/maze_map.vh)。小球圆心范围 X=15～624、Y=15～464。运动模式 00/01/10/11 分别为角速度、姿态位置、倾角速度、重力；游戏状态编码见公共头文件。B/C 使用同一地图，矩形采用左闭右开区间。

板外 `rst_n` 经 `reset_sync` 异步置位、两拍同步释放。按钮/开关先两级同步，再经整组约 10 ms 稳定判定；按钮长按仅产生一次请求。

| 板载资源 | 功能 / 管脚 |
| --- | --- |
| 时钟、CPU_RESETN | E3、C12 |
| SW0/SW1 | `mode[1:0]`，J15/L16 |
| SW2 | 游戏使能，且只有 mode=11 时生效，M13 |
| SW3 | 自动亮度开关，R15 |
| 中/上/右/下按钮 | 归零/校准/开始暂停/游戏复位，N17/M18/M17/P18 |
| GYRO CS/MOSI/MISO/SCLK | JA1/2/3/4，C17/D18/E18/G17 |
| ALS CS/MISO/SCLK | JB1/3/4，D14/G16/H14 |

接线假定 GYRO Rev. A J1 直插 JA，ALS Rev. A J1 接 JB 的 1～6 排，使用 3.3 V。不同模块或转接方式需核对实物后修改约束。25 MHz 像素方案需验证显示器兼容性。SPI 外部 I/O 延时在驱动实现后按器件时序补充。

## 3. 首次克隆和创建工程

在 PowerShell 中执行：

```powershell
git clone https://github.com/sixi3254/FPGA-Course-Design.git FPGA_Motion_System
cd FPGA_Motion_System
git switch develop
git pull --ff-only origin develop
```

每人使用自己的本地克隆。打开 Vivado 2025.2，在没有其他工程打开时，于 Tcl Console 执行；路径替换为自己的克隆位置：

```tcl
cd {D:/FPGA_Course_Design/FPGA_Motion_System}
source scripts/create_project.tcl
```

也可在仓库根目录用 PowerShell 批处理创建；安装位置按本机修改：

```powershell
$vivado = 'D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
& $vivado -mode batch -source scripts/create_project.tcl
if ($LASTEXITCODE -ne 0) { throw 'Vivado 工程创建失败，请检查日志' }
```

工程生成在 `vivado/FPGA_Motion_System.xpr`。以后直接打开该文件；已有工程时不要重复运行创建脚本。RTL 和 TB 直接在仓库目录编辑，不复制进 Vivado 生成目录。

克隆后无需初始化目录。`config.tcl` 通过脚本位置推导根目录，不依赖开发者个人路径。频率/分辨率说明参数不会自动修改 RTL 或 XDC，改硬件配置时必须同步维护。

## 4. 拉取和同步源码

先保存并提交自己的修改，在功能分支同步集成分支：

```powershell
git status
git fetch origin
git merge origin/develop
```

更新本地集成分支可执行 `git switch develop`、`git pull --ff-only origin develop`。在打开本仓库工程的 Vivado Tcl Console 中执行：

```tcl
source scripts/sync_sources.tcl
```

新增、删除、移动源码后必须同步。脚本递归扫描 `rtl/`、各仿真目录及 `constraints/` 下的 `.xdc` / `.tcl`；会移除扫描清单外的工程引用，但不删除磁盘文件。不要仅在 GUI 中加入仓库外源文件。

未来添加 `.xci`、`.bd`、`.mem`、`.coe` 等资产时，同时扩展脚本、指定路径并验证干净克隆能重建。普通 RTL 修改不必重新创建工程；器件或创建策略变化时，关闭工程后重新生成本机 `vivado/`。

## 5. 仿真和完整构建

**仓库内的 Testbench 当前为待开发占位。** 创建工程会建立四个仿真集合，但不会启动测试；占位顶层尚未实现时，脚本提示 TODO，并拒绝用设计顶层 `top` 冒充测试。

| 仿真集合 | 子系统 TB 模块名 | 负责人 |
| --- | --- | --- |
| `sim_sensor` | `tb_sensor_top` | A |
| `sim_video` | `tb_video_top` | B |
| `sim_motion` | `tb_motion_top` | C |
| `sim_system` | `tb_system_top` | 全组 |

编写对应 TB 后执行：

```tcl
source scripts/sync_sources.tcl
source scripts/run_sim.tcl
# 选择一项运行，第 2 个参数是 module 名称，不是文件名。
run_tb sensor tb_sensor_top all
run_tb video tb_video_top all
run_tb motion tb_motion_top all
run_tb system tb_system_top all
```

`run_tb` 会关闭前一仿真会话。`all` 要求 TB 有明确结束条件、PASS/FAIL 和有限超时；也可以指定 `100us` 等时长，但运行到指定时间不能单独证明通过。A 用传感器模型，B 用模拟坐标/增益，C 用模拟有效样本，分别验证后再联调。

综合、实现和比特流生成：

```tcl
source scripts/build.tcl
```

或关闭同一工程的 GUI，在项目根目录执行：

```powershell
$vivado = 'D:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
& $vivado -mode batch -source scripts/build.tcl
if ($LASTEXITCODE -ne 0) { throw '构建失败，请检查 Vivado 日志' }
```

脚本要求工程已创建，会同步源码并重新运行综合/实现，输出 `output/FPGA_Motion_System.bit`、`utilization.rpt`、`timing_summary.rpt` 和 `drc.rpt`。同名输出会替换；构建失败时不要使用旧 `.bit`。

当前框架此前已在 Vivado 2025.2 跑通综合、布局布线和比特流，最终 DRC 为 0 项。占位常量使功能逻辑被优化，WNS/TNS 为 NA；后续真实逻辑需重新验证资源、时序、未约束路径和 DRC，并完成上板验证。

## 6. 三人 Git 协作

采用 `main ← develop ← feature/*`。当前两条基础分支保存同一份开发框架；后续 `develop` 用于集成，`main` 接收验收后的里程碑版本。

| 分支 | 用途 |
| --- | --- |
| `main` | 全组验收的里程碑，C 协调合并 |
| `develop` | 联合开发与集成 |
| `feature/sensor-*` | A 的具体传感器任务 |
| `feature/video-*` | B 的具体显示任务 |
| `feature/motion-*` | C 的具体控制任务 |

开始任务，以 A 的 SPI 为例：

```powershell
git switch develop
git pull --ff-only origin develop
git switch -c feature/sensor-spi
```

完成模块、相应 TB 和验证后，检查并提交本次修改：

```powershell
git status
git diff
git add rtl/sensor/spi_master.v sim/sensor/tb_spi_master.v
git diff --cached --check
git diff --cached
git commit -m "feat(sensor): 实现 SPI 主机及自动检查测试"
git push -u origin feature/sensor-spi
```

第一次提交前，在各自克隆中配置自己的 `git config user.name` 和 `git config user.email`。提交信息示例：`feat(video): 实现 VGA 时序`、`fix(motion): 修复负数截断`、`test(sensor): 增加超时用例`、`docs: 更新 README 接口说明`。

在 GitHub 发起 **功能分支 → develop** 的 Pull Request，说明行为、接口影响、工具版本和实际验证结果，至少由一位相关成员评审。公共接口变更需要所有受影响成员确认。合并后，其他成员 `fetch + merge origin/develop`，再同步 Vivado 源文件。

冲突处理：先 `git status`，编辑冲突文件并移除冲突标记，核对接口、重新验证后 `git add <已解决文件>`、`git commit`、`git push`。需要退出本次合并时用 `git merge --abort`。共享分支使用 merge 同步，避免强推覆盖同伴工作。

阶段验收后从 `develop` 向 `main` 发 PR，再打版本标签。建议在 GitHub 配置分支保护和成员权限。合并完成后的下一个任务重新从最新 `develop` 建分支。

## 7. 合并前检查与开发顺序

- 端口名、位宽、signed、单位和 valid 时序与其他成员一致。
- 新文件能通过 Tcl 加入，相关 TB 有明确检查结果。
- 提交清单只有源码、必要输入资产、团队测试和本 README；无生成工程、缓存、报告、本地测试或其他 Markdown。
- 新增板外端口时同步更新 XDC，公共参数/地图修改通知受影响成员。
- 在 PR 中记录测试方法与限制，不能用占位框架构建通过代替真实功能验证。

优先完成 A 的 SPI/采样、B 的 VGA 彩条、C 的模拟样本姿态位置控制；再按 A+C、C+B、A+B 进行联调，最后实现重力、迷宫和计分。

官方参考：[Nexys A7-100T Master XDC](https://github.com/Digilent/digilent-xdc/blob/master/Nexys-A7-100T-Master.xdc)、[Pmod GYRO 手册](https://digilent.com/reference/_media/reference/pmod/pmodgyro/pmodgyro_rm.pdf)、[Pmod ALS 手册](https://digilent.com/reference/_media/reference/pmod/pmodals/pmodals_rm.pdf)。

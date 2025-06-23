# mmt_sync_single.v 电路示意图 (Mermaid)

本文档包含 `mmt_sync_single.v` 模块在不同宏控制下的行为的 Mermaid 图描述。
您可以将这些代码块复制到支持 Mermaid 的 Markdown 编辑器或在线工具中查看可视化图表。
这些图以 `Depth=2`（即两级主同步触发器）为例进行说明。

## 1. 正常操作 (未定义 `INJECT_X` 或 `INJECT_DELAY`)

```mermaid
%% 1. 正常操作 (未定义 INJECT_X 或 INJECT_DELAY)
graph TD;
    subgraph mmt_sync_single_normal ["Normal Operation (Depth=2 Example)"]
        direction LR;
        
        IN[in] --> DFF1_IN_Normal{"dff_con[0] (from in)"};
        
        subgraph SyncStage1_Normal ["Sync Stage 1"]
            direction LR;
            CLK1_N[clk] --> DFF1_N[mmt_dff_1];
            RSTN1_N[rstn] --> DFF1_N;
            DFF1_IN_Normal --> DFF1_N;
        end
        DFF1_N --> DFF1_OUT_Normal{"dff_con[1]"};
        
        subgraph SyncStage2_Normal ["Sync Stage 2"]
            direction LR;
            CLK2_N[clk] --> DFF2_N[mmt_dff_2];
            RSTN2_N[rstn] --> DFF2_N;
            DFF1_OUT_Normal --> DFF2_N;
        end
        DFF2_N --> DFF2_OUT_Normal{"dff_con[2] (out)"};
        
        style IN fill:#lightgreen,stroke:#333,stroke-width:2px
        style DFF2_OUT_Normal fill:#lightblue,stroke:#333,stroke-width:2px
        style DFF1_N fill:#orange,stroke:#333,stroke-width:2px
        style DFF2_N fill:#orange,stroke:#333,stroke-width:2px
    end
```
**描述**:
*   输入信号 `in` 直接连接到同步链的第一个D触发器 (`mmt_dff_1`) 的输入 `dff_con[0]`。
*   信号通过两级 `mmt_dff` 触发器进行同步。
*   最终输出 `out` 来自第二级触发器的输出 `dff_con[2]`。

## 2. 定义 `INJECT_DELAY` (注入一级延迟)

```mermaid
%% 2. 定义 INJECT_DELAY (注入一级延迟)
graph TD;
    subgraph mmt_sync_single_delay ["INJECT_DELAY Defined (Depth=2 Example)"]
        direction LR;

        IN_D[in] --> FaultDFF["Fault_Delay_FF (fault_delay_reg_sync1)"];
        CLK_F[clk] --> FaultDFF;
        RSTN_F[rstn] --> FaultDFF;

        FaultDFF --> DFF1_IN_Delay{"dff_con[0] (from fault_delay_reg_sync1)"};
        
        subgraph SyncStage1_Delay ["Sync Stage 1"]
            direction LR;
            CLK1_D[clk] --> DFF1_D[mmt_dff_1];
            RSTN1_D[rstn] --> DFF1_D;
            DFF1_IN_Delay --> DFF1_D;
        end
        DFF1_D --> DFF1_OUT_Delay{"dff_con[1]"};
        
        subgraph SyncStage2_Delay ["Sync Stage 2"]
            direction LR;
            CLK2_D[clk] --> DFF2_D[mmt_dff_2];
            RSTN2_D[rstn] --> DFF2_D;
            DFF1_OUT_Delay --> DFF2_D;
        end
        DFF2_D --> DFF2_OUT_Delay{"dff_con[2] (out)"};
        
        style IN_D fill:#lightgreen,stroke:#333,stroke-width:2px
        style DFF2_OUT_Delay fill:#lightblue,stroke:#333,stroke-width:2px
        style FaultDFF fill:#ffcccc,stroke:#333,stroke-width:2px
        style DFF1_D fill:#orange,stroke:#333,stroke-width:2px
        style DFF2_D fill:#orange,stroke:#333,stroke-width:2px
    end
```
**描述**:
*   输入信号 `in` 首先进入一个额外的触发器 `fault_delay_reg_sync1`。
*   `fault_delay_reg_sync1` 的输出 (`dff_con0_base_source`) 作为 `dff_con[0]` 连接到同步链的第一个D触发器。
*   这有效地在主同步路径之前增加了一级延迟。

## 3. 定义 `INJECT_X` (注入 'X', `INJECT_DELAY` 未定义)

```mermaid
%% 3. 定义 INJECT_X (注入 'X', INJECT_DELAY 未定义)
graph TD;
    subgraph mmt_sync_single_x ["INJECT_X Defined, INJECT_DELAY Not Defined (Depth=2 Example)"]
        direction LR;
        
        IN_X[in] --> MUX_X_IN1{"dff_con0_base_source (from in)"};
        X_VAL((1'bx)) --> MUX_X_IN2{"X_Source"};
        FLAG_X[is_first_cycle_after_reset_flag] --> MUX_X{MUX_dff_con0};
        
        MUX_X_IN1 --> MUX_X;
        MUX_X_IN2 --> MUX_X;
        
        MUX_X --> DFF1_IN_X{"dff_con[0]"};
        
        subgraph SyncStage1_X ["Sync Stage 1"]
            direction LR;
            CLK1_X[clk] --> DFF1_X[mmt_dff_1];
            RSTN1_X[rstn] --> DFF1_X;
            DFF1_IN_X --> DFF1_X;
        end
        DFF1_X --> DFF1_OUT_X{"dff_con[1]"};
        
        subgraph SyncStage2_X ["Sync Stage 2"]
            direction LR;
            CLK2_X[clk] --> DFF2_X[mmt_dff_2];
            RSTN2_X[rstn] --> DFF2_X;
            DFF1_OUT_X --> DFF2_X;
        end
        DFF2_X --> DFF2_OUT_X{"dff_con[2] (out)"};

        style IN_X fill:#lightgreen,stroke:#333,stroke-width:2px
        style X_VAL fill:#ff9999,stroke:#333,stroke-width:2px
        style FLAG_X fill:#yellow,stroke:#333,stroke-width:1px
        style MUX_X fill:#cyan,stroke:#333,stroke-width:2px
        style DFF2_OUT_X fill:#lightblue,stroke:#333,stroke-width:2px
        style DFF1_X fill:#orange,stroke:#333,stroke-width:2px
        style DFF2_X fill:#orange,stroke:#333,stroke-width:2px
    end
```
**描述**:
*   `dff_con[0]` 的值由一个概念上的多路选择器 (MUX) 决定，该选择器由 `is_first_cycle_after_reset_flag` 控制。
*   当 `is_first_cycle_after_reset_flag` 为真（即解复位后的第一个有效时钟周期）且 `rstn` 为高时，`dff_con[0]` 被强制为 `1'bx`。
*   在其他情况下，`dff_con[0]` 的值来自 `dff_con0_base_source`，这里因为 `INJECT_DELAY` 未定义，所以 `dff_con0_base_source` 直接是 `in`。
*   这个 `1'bx` 会被同步链的第一级触发器捕获。

## 4. 定义 `INJECT_X` 和 `INJECT_DELAY` (同时注入延迟和 'X')

```mermaid
%% 4. 定义 INJECT_X 和 INJECT_DELAY (同时注入延迟和 'X')
graph TD;
    subgraph mmt_sync_single_delay_x ["INJECT_X & INJECT_DELAY Defined (Depth=2 Example)"]
        direction LR;

        IN_DX[in] --> FaultDFF_DX["Fault_Delay_FF (fault_delay_reg_sync1)"];
        CLK_FDX[clk] --> FaultDFF_DX;
        RSTN_FDX[rstn] --> FaultDFF_DX;

        FaultDFF_DX --> MUX_DX_IN1{"dff_con0_base_source (from fault_delay_reg_sync1)"};
        X_VAL_DX((1'bx)) --> MUX_DX_IN2{"X_Source"};
        FLAG_DX[is_first_cycle_after_reset_flag] --> MUX_DX{MUX_dff_con0};
        
        MUX_DX_IN1 --> MUX_DX;
        MUX_DX_IN2 --> MUX_DX;
        
        MUX_DX --> DFF1_IN_DX{"dff_con[0]"};
        
        subgraph SyncStage1_DX ["Sync Stage 1"]
            direction LR;
            CLK1_DX[clk] --> DFF1_DX[mmt_dff_1];
            RSTN1_DX[rstn] --> DFF1_DX;
            DFF1_IN_DX --> DFF1_DX;
        end
        DFF1_DX --> DFF1_OUT_DX{"dff_con[1]"};
        
        subgraph SyncStage2_DX ["Sync Stage 2"]
            direction LR;
            CLK2_DX[clk] --> DFF2_DX[mmt_dff_2];
            RSTN2_DX[rstn] --> DFF2_DX;
            DFF1_OUT_DX --> DFF2_DX;
        end
        DFF2_DX --> DFF2_OUT_DX{"dff_con[2] (out)"};

        style IN_DX fill:#lightgreen,stroke:#333,stroke-width:2px
        style FaultDFF_DX fill:#ffcccc,stroke:#333,stroke-width:2px
        style X_VAL_DX fill:#ff9999,stroke:#333,stroke-width:2px
        style FLAG_DX fill:#yellow,stroke:#333,stroke-width:1px
        style MUX_DX fill:#cyan,stroke:#333,stroke-width:2px
        style DFF2_OUT_DX fill:#lightblue,stroke:#333,stroke-width:2px
        style DFF1_DX fill:#orange,stroke:#333,stroke-width:2px
        style DFF2_DX fill:#orange,stroke:#333,stroke-width:2px
    end
```
**描述**:
*   输入信号 `in` 首先进入 `fault_delay_reg_sync1`。
*   `fault_delay_reg_sync1` 的输出作为 `dff_con0_base_source`。
*   `dff_con[0]` 的值由一个概念上的多路选择器 (MUX) 决定，该选择器由 `is_first_cycle_after_reset_flag` 控制。
*   当 `is_first_cycle_after_reset_flag` 为真且 `rstn` 为高时，`dff_con[0]` 被强制为 `1'bx`。
*   在其他情况下，`dff_con[0]` 的值来自 `dff_con0_base_source` (即 `fault_delay_reg_sync1` 的输出)。
*   这个 `1'bx` (如果被选中) 会被同步链的第一级触发器捕获。

## 5. 定义 `INJECT_RANDOM` (注入随机0/1, `INJECT_DELAY` 未定义)

```mermaid
%% 5. 定义 INJECT_RANDOM (注入随机0/1, INJECT_DELAY 未定义)
graph TD;
    subgraph mmt_sync_single_random ["INJECT_RANDOM Defined, INJECT_DELAY Not Defined (Depth=2 Example)"]
        direction LR;
        
        IN_R[in] --> MUX_R_IN1{"dff_con0_base_source (from in)"};
        RAND_SRC["$urandom_range(0,1)"] --> RANDOM_VAL((random_val));
        RANDOM_VAL --> MUX_R_IN2{"Random_Source (0 or 1)"};
        FLAG_R[is_first_cycle_after_reset_flag] --> MUX_R{MUX_dff_con0};
        
        MUX_R_IN1 --> MUX_R;
        MUX_R_IN2 --> MUX_R;
        
        MUX_R --> DFF1_IN_R{"dff_con[0]"};
        
        subgraph SyncStage1_R ["Sync Stage 1"]
            direction LR;
            CLK1_R[clk] --> DFF1_R[mmt_dff_1];
            RSTN1_R[rstn] --> DFF1_R;
            DFF1_IN_R --> DFF1_R;
        end
        DFF1_R --> DFF1_OUT_R{"dff_con[1]"};
        
        subgraph SyncStage2_R ["Sync Stage 2"]
            direction LR;
            CLK2_R[clk] --> DFF2_R[mmt_dff_2];
            RSTN2_R[rstn] --> DFF2_R;
            DFF1_OUT_R --> DFF2_R;
        end
        DFF2_R --> DFF2_OUT_R{"dff_con[2] (out)"};

        style IN_R fill:#lightgreen,stroke:#333,stroke-width:2px
        style RAND_SRC fill:#f9f,stroke:#333,stroke-width:2px 
        style RANDOM_VAL fill:#f9f,stroke:#333,stroke-width:2px
        style FLAG_R fill:#yellow,stroke:#333,stroke-width:1px
        style MUX_R fill:#cyan,stroke:#333,stroke-width:2px
        style DFF2_OUT_R fill:#lightblue,stroke:#333,stroke-width:2px
        style DFF1_R fill:#orange,stroke:#333,stroke-width:2px
        style DFF2_R fill:#orange,stroke:#333,stroke-width:2px
    end
```
**描述**:
*   `dff_con[0]` 的值由一个概念上的多路选择器 (MUX) 决定，该选择器由 `is_first_cycle_after_reset_flag` 控制。
*   当 `is_first_cycle_after_reset_flag` 为真（即解复位后的第一个有效时钟周期）且 `rstn` 为高时，`dff_con[0]` 被强制为一个随机的0或1 (来自 `$urandom_range(0,1)` 生成的 `random_val`)。
*   在其他情况下，`dff_con[0]` 的值来自 `dff_con0_base_source`，这里因为 `INJECT_DELAY` 未定义，所以 `dff_con0_base_source` 直接是 `in`。
*   这个随机值会被同步链的第一级触发器捕获。

## 6. 定义 `INJECT_RANDOM` 和 `INJECT_DELAY` (同时注入延迟和随机0/1)

```mermaid
%% 6. 定义 INJECT_RANDOM 和 INJECT_DELAY (同时注入延迟和随机0/1)
graph TD;
    subgraph mmt_sync_single_delay_random ["INJECT_RANDOM & INJECT_DELAY Defined (Depth=2 Example)"]
        direction LR;

        IN_DR[in] --> FaultDFF_DR["Fault_Delay_FF (fault_delay_reg_sync1)"];
        CLK_FDR[clk] --> FaultDFF_DR;
        RSTN_FDR[rstn] --> FaultDFF_DR;

        FaultDFF_DR --> MUX_DR_IN1{"dff_con0_base_source (from fault_delay_reg_sync1)"};
        RAND_SRC_DR["$urandom_range(0,1)"] --> RANDOM_VAL_DR((random_val));
        RANDOM_VAL_DR --> MUX_DR_IN2{"Random_Source (0 or 1)"};
        FLAG_DR[is_first_cycle_after_reset_flag] --> MUX_DR{MUX_dff_con0};
        
        MUX_DR_IN1 --> MUX_DR;
        MUX_DR_IN2 --> MUX_DR;
        
        MUX_DR --> DFF1_IN_DR{"dff_con[0]"};
        
        subgraph SyncStage1_DR ["Sync Stage 1"]
            direction LR;
            CLK1_DR[clk] --> DFF1_DR[mmt_dff_1];
            RSTN1_DR[rstn] --> DFF1_DR;
            DFF1_IN_DR --> DFF1_DR;
        end
        DFF1_DR --> DFF1_OUT_DR{"dff_con[1]"};
        
        subgraph SyncStage2_DR ["Sync Stage 2"]
            direction LR;
            CLK2_DR[clk] --> DFF2_DR[mmt_dff_2];
            RSTN2_DR[rstn] --> DFF2_DR;
            DFF1_OUT_DR --> DFF2_DR;
        end
        DFF2_DR --> DFF2_OUT_DR{"dff_con[2] (out)"};

        style IN_DR fill:#lightgreen,stroke:#333,stroke-width:2px
        style FaultDFF_DR fill:#ffcccc,stroke:#333,stroke-width:2px
        style RAND_SRC_DR fill:#f9f,stroke:#333,stroke-width:2px
        style RANDOM_VAL_DR fill:#f9f,stroke:#333,stroke-width:2px
        style FLAG_DR fill:#yellow,stroke:#333,stroke-width:1px
        style MUX_DR fill:#cyan,stroke:#333,stroke-width:2px
        style DFF2_OUT_DR fill:#lightblue,stroke:#333,stroke-width:2px
        style DFF1_DR fill:#orange,stroke:#333,stroke-width:2px
        style DFF2_DR fill:#orange,stroke:#333,stroke-width:2px
    end
```
**描述**:
*   输入信号 `in` 首先进入 `fault_delay_reg_sync1`。
*   `fault_delay_reg_sync1` 的输出作为 `dff_con0_base_source`。
*   `dff_con[0]` 的值由一个概念上的多路选择器 (MUX) 决定，该选择器由 `is_first_cycle_after_reset_flag` 控制。
*   当 `is_first_cycle_after_reset_flag` 为真且 `rstn` 为高时，`dff_con[0]` 被强制为一个随机的0或1 (来自 `$urandom_range(0,1)` 生成的 `random_val`)。
*   在其他情况下，`dff_con[0]` 的值来自 `dff_con0_base_source` (即 `fault_delay_reg_sync1` 的输出)。
*   这个随机值 (如果被选中) 会被同步链的第一级触发器捕获。

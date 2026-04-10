# Cancel 按钮修复说明

## 问题描述

前端点击 Cancel 按钮时，WebUI 的 SSE 流会停止，但后端的 hermes-agent 进程（特别是正在执行的工具调用）会继续运行。

## 根本原因

WebUI 层的 `cancel_event` 只影响 SSE 事件流的发送，但没有调用 AIAgent 的 `interrupt()` 方法，导致：
- Agent 的 `_interrupt_requested` 标志未被设置
- 全局工具中断信号 `_interrupt_event` 未被触发
- 正在执行的工具调用无法收到中断信号

## 解决方案

在 WebUI 层和 Hermes-Agent 层之间建立取消信号桥接：

### 修改文件

1. **api/config.py** (+1 行)
   - 添加 `AGENT_INSTANCES` 字典存储 agent 实例引用

2. **api/streaming.py** (+22 行, -1 行)
   - 导入 `AGENT_INSTANCES`
   - 创建 agent 后存储到字典
   - `cancel_stream()` 中调用 `agent.interrupt()`
   - finally 块中清理 agent 引用

### 信号传播流程（修复后）

```
用户点击 Cancel 按钮
    ↓
前端: cancelStream()
    ↓
GET /api/chat/cancel?stream_id=xxx
    ↓
后端: cancel_stream(stream_id)
    ├─ 设置 cancel_event (停止 SSE 流)
    └─ 调用 agent.interrupt()
        ├─ 设置 agent._interrupt_requested = True
        ├─ 调用 _set_interrupt(True) 设置全局信号
        └─ 传播到子 agent（如果有）
    ↓
Agent 主循环检查 _interrupt_requested
    ├─ 在 API 调用前/中检查
    └─ 抛出 InterruptedError
    ↓
工具执行检查 is_interrupted()
    └─ 终止正在执行的操作
    ↓
前端显示 "*Task cancelled.*"
```

## 测试建议

### 手动测试场景

1. **长时间运行的终端命令**
   - 让 agent 执行 `sleep 60` 或类似命令
   - 点击 Cancel 按钮
   - 验证：命令立即终止，不再继续运行

2. **工具调用过程中取消**
   - 启动任何需要工具调用的任务
   - 在工具执行期间点击 Cancel
   - 验证：工具调用被中断

3. **LLM 生成过程中取消**
   - 启动一个长响应的对话
   - 在生成过程中点击 Cancel
   - 验证：生成立即停止

### 验证要点

- UI 显示"Task cancelled"
- 后台进程确实停止（可通过系统监控工具验证）
- 没有遗留的僵尸进程
- 取消后可以立即开始新任务

## 技术细节

### 线程安全
- 所有对 `AGENT_INSTANCES` 的访问都在 `STREAMS_LOCK` 保护下
- `agent.interrupt()` 内部使用 `threading.Event`，线程安全

### 错误处理
- `agent.interrupt()` 调用被 try-except 包裹
- 即使中断失败，也不会阻止 SSE 流的取消

### 内存管理
- Agent 实例在 finally 块中被清理
- 避免内存泄漏

## 兼容性

- 保持向后兼容，不影响现有功能
- 只添加新的中断调用，不修改原有取消逻辑
- 如果 agent 实例不存在或已完成，优雅降级

## 回滚方案

如果出现问题，可以简单地回滚这两个文件的修改：
```bash
git checkout api/config.py api/streaming.py
```

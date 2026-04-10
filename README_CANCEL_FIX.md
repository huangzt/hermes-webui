# Cancel 按钮修复 - 快速参考

## 🎯 问题
点击 Cancel 按钮后，UI 显示已取消，但后台 agent 和工具调用仍在运行。

## ✅ 解决方案
在 WebUI 层和 Hermes-Agent 层之间建立中断信号桥接。

## 📦 使用修复版本

### 方法 1：使用快速启动脚本
```bash
./start-with-fix.sh
```

### 方法 2：手动切换
```bash
git checkout fix/cancel-interrupt-agent
./start.sh
```

## 🧪 测试修复

1. 启动服务器（使用上述任一方法）
2. 在 WebUI 中发送消息，让 agent 执行长时间任务：
   ```
   请执行命令：sleep 60
   ```
3. 在任务执行期间点击 **Cancel** 按钮
4. 验证：
   - ✅ UI 立即显示 "Task cancelled"
   - ✅ 后台进程确实停止（不再有 sleep 进程）
   - ✅ 可以立即开始新任务

## 🔄 更新上游代码

当作者发布新版本时：

```bash
# 1. 切换到 master 并更新
git checkout master
git pull origin master

# 2. 合并更新到修复分支
git checkout fix/cancel-interrupt-agent
git merge master

# 3. 如果有冲突，解决后提交
git add .
git commit -m "merge: update from upstream"
```

## 📂 相关文件

- `CANCEL_FIX.md` - 详细技术说明
- `LOCAL_BRANCHES.md` - 分支管理指南
- `start-with-fix.sh` - 快速启动脚本

## 🔍 技术细节

### 修改的核心代码

**api/config.py**
```python
AGENT_INSTANCES: dict = {}  # 存储 agent 实例
```

**api/streaming.py**
```python
# 创建 agent 后存储
with STREAMS_LOCK:
    AGENT_INSTANCES[stream_id] = agent

# cancel_stream() 中调用中断
agent = AGENT_INSTANCES.get(stream_id)
if agent:
    agent.interrupt("Cancelled by user")

# 清理时移除引用
AGENT_INSTANCES.pop(stream_id, None)
```

### 信号流程

```
Cancel 按钮
  ↓
cancel_stream()
  ├─ 设置 cancel_event (停止 SSE)
  └─ 调用 agent.interrupt()
      ├─ 设置 _interrupt_requested
      ├─ 触发 _interrupt_event
      └─ 传播到工具层
  ↓
工具检查 is_interrupted()
  ↓
终止执行
```

## 💡 优势

- ✅ 修改量小（仅 27 行代码）
- ✅ 线程安全
- ✅ 向后兼容
- ✅ 优雅降级
- ✅ 独立分支，不影响主线

## 🆘 故障排除

### 问题：切换分支失败
```bash
# 如果有未提交的修改
git stash
git checkout fix/cancel-interrupt-agent
git stash pop
```

### 问题：合并冲突
```bash
# 查看冲突文件
git status

# 编辑冲突文件，解决冲突标记
# 然后：
git add <冲突文件>
git commit -m "resolve merge conflicts"
```

### 问题：想回到原始版本
```bash
git checkout master
./start.sh
```

## 📞 联系

如果遇到问题或有改进建议，请查看：
- GitHub Issues: https://github.com/nesquena/hermes-webui/issues
- 本地文档: `CANCEL_FIX.md`, `LOCAL_BRANCHES.md`

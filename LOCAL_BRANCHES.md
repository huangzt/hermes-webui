# 本地分支管理说明

## 当前本地修改分支

### fix/cancel-interrupt-agent
**用途**: 修复 Cancel 按钮无法中止 agent 工具调用的问题

**提交**: ef92965

**修改文件**:
- api/config.py
- api/streaming.py
- CHANGELOG.md
- CANCEL_FIX.md

**如何使用**:
```bash
# 切换到修复分支
git checkout fix/cancel-interrupt-agent

# 切换回主分支
git checkout master

# 查看分支差异
git diff master..fix/cancel-interrupt-agent
```

**更新策略**:
当上游作者更新代码时：

```bash
# 1. 切换到 master 分支
git checkout master

# 2. 拉取上游更新
git pull origin master

# 3. 切换到修复分支
git checkout fix/cancel-interrupt-agent

# 4. 将 master 的更新合并到修复分支
git merge master

# 5. 如果有冲突，解决冲突后提交
git add .
git commit -m "merge: update from upstream master"
```

**测试修复**:
```bash
# 确保在修复分支上
git checkout fix/cancel-interrupt-agent

# 启动服务器
./start.sh

# 测试场景：
# 1. 让 agent 执行长时间命令（如 sleep 60）
# 2. 点击 Cancel 按钮
# 3. 验证后台进程确实停止
```

---

### feat/complete-i18n-support
**用途**: 完善前端汉化支持

**提交**: 5e7eca0

---

## 分支管理最佳实践

1. **保持 master 分支干净**: master 分支始终跟踪上游，不做本地修改
2. **功能分支独立**: 每个功能或修复使用独立分支
3. **定期同步**: 定期从 master 合并更新到功能分支
4. **备份重要分支**: 可以推送到自己的远程仓库作为备份

## 备份到远程仓库（可选）

如果你有自己的 GitHub/GitLab 仓库：

```bash
# 添加自己的远程仓库
git remote add my-fork https://github.com/your-username/hermes-webui.git

# 推送分支到自己的仓库
git push my-fork fix/cancel-interrupt-agent
git push my-fork feat/complete-i18n-support

# 查看所有远程仓库
git remote -v
```

## 快速切换命令

```bash
# 切换到修复分支并启动服务
git checkout fix/cancel-interrupt-agent && ./start.sh

# 切换到 master 并更新
git checkout master && git pull

# 查看当前分支
git branch
```

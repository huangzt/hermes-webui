#!/bin/bash
# 快速切换到修复分支并启动服务的脚本

echo "🔄 切换到 fix/cancel-interrupt-agent 分支..."
git checkout fix/cancel-interrupt-agent

if [ $? -eq 0 ]; then
    echo "✅ 已切换到修复分支"
    echo ""
    echo "📝 当前分支包含的修复:"
    echo "   - Cancel 按钮现在可以正确中止 agent 工具调用"
    echo ""
    echo "🚀 启动服务器..."
    ./start.sh
else
    echo "❌ 切换分支失败"
    exit 1
fi

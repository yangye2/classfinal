#!/usr/bin/env bash
# ClassFinal 发布脚本
set -euo pipefail

# 从 pom.xml 读取当前版本
CURRENT_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)
RELEASE_VERSION="${1:-}"
NEXT_VERSION="${2:-}"

function Show_Usage() {
    cat << EOF
用法: $0 <release-version> <next-snapshot-version>

示例:
  $0 2.0.0 2.0.1-SNAPSHOT

发布步骤:
  1. 将所有版本从 ${CURRENT_VERSION} 改为 release-version
  2. 提交并打 tag
  3. 推送 tag 触发 GitHub Actions 发布
  4. 将版本更新为 next-snapshot-version

EOF
    exit 1
}

function Build_Docker_Images() {
    local version="$1"
    
    echo ">>> 构建 Docker 镜像: version=$version"
    
    # 构建 ClassFinal 主镜像
    echo "  构建 classfinal:$version ..."
    docker build -t "ghcr.io/yangye2/classfinal/classfinal:$version" \
                 -t "ghcr.io/yangye2/classfinal/classfinal:latest" \
                 -f Dockerfile . || {
        echo "❌ ClassFinal 镜像构建失败"
        return 1
    }
    echo "  ✓ classfinal:$version 构建成功"
    
    # 构建 ClassFinal Web 镜像
    echo "  构建 classfinal-web:$version ..."
    docker build -t "ghcr.io/yangye2/classfinal/classfinal-web:$version" \
                 -t "ghcr.io/yangye2/classfinal/classfinal-web:latest" \
                 -f classfinal-web/Dockerfile \
                 --build-arg VERSION="$version" \
                 . || {
        echo "❌ ClassFinal Web 镜像构建失败"
        return 1
    }
    echo "  ✓ classfinal-web:$version 构建成功"
    
    # 询问是否推送
    echo ""
    read -p "是否推送镜像到 GHCR? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "推送镜像..."
        docker push "ghcr.io/yangye2/classfinal/classfinal:$version"
        docker push "ghcr.io/yangye2/classfinal/classfinal:latest"
        docker push "ghcr.io/yangye2/classfinal/classfinal-web:$version"
        docker push "ghcr.io/yangye2/classfinal/classfinal-web:latest"
        echo "✓ 镜像已推送"
    fi
}

function Update_Version() {
    local old_version="$1"
    local new_version="$2"
    
    echo ">>> 更新版本: $old_version -> $new_version"
    
    # 使用 Maven versions 插件自动更新所有版本
    mvn versions:set -DnewVersion="$new_version" -DgenerateBackupPoms=false -B -q
    
    # 更新 docker-compose.yml 中的镜像版本
    local docker_old="${old_version%-SNAPSHOT}"
    local docker_new="${new_version%-SNAPSHOT}"
    find . -name "docker-compose.yml" -type f | while read -r compose; do
        sed -i "s|ghcr.io/yangye2/classfinal/classfinal:${docker_old}|ghcr.io/yangye2/classfinal/classfinal:${docker_new}|g" "$compose"
        sed -i "s|ghcr.io/yangye2/classfinal/classfinal-web:${old_version}|ghcr.io/yangye2/classfinal/classfinal-web:${new_version}|g" "$compose"
    done
    
    # 更新 integration-test 中引用的 classfinal-maven-plugin 版本
    find integration-test -name "pom.xml" -type f | while read -r pom; do
        if grep -q "classfinal-maven-plugin" "$pom"; then
            sed -i "/<artifactId>classfinal-maven-plugin<\/artifactId>/,/<\/plugin>/ s|<version>${old_version}</version>|<version>${new_version}</version>|" "$pom"
            echo "  ✓ 更新 $pom"
        fi
    done
    
    echo "✓ 版本更新完成"
}

function Main() {
    if [[ -z "$RELEASE_VERSION" ]] || [[ -z "$NEXT_VERSION" ]]; then
        Show_Usage
    fi
    
    # 验证 release version 不包含 SNAPSHOT
    if [[ "$RELEASE_VERSION" == *"SNAPSHOT"* ]]; then
        echo "错误: Release 版本不能包含 SNAPSHOT: $RELEASE_VERSION"
        exit 1
    fi
    
    # 验证 next version 包含 SNAPSHOT
    if [[ "$NEXT_VERSION" != *"SNAPSHOT"* ]]; then
        echo "错误: 下一个开发版本必须是 SNAPSHOT: $NEXT_VERSION"
        exit 1
    fi
    
    echo "=== ClassFinal 发布流程 ==="
    echo ""
    echo "版本变更："
    echo "  当前版本:     $CURRENT_VERSION"
    echo "  ↓"
    echo "  发布版本:     $RELEASE_VERSION  (将推送到 Maven Central)"
    echo "  ↓"
    echo "  下个开发版本: $NEXT_VERSION"
    echo ""
    echo "操作步骤："
    echo "  1. 更新所有版本号为 $RELEASE_VERSION"
    echo "  2. 提交并创建 tag v$RELEASE_VERSION"
    echo "  3. 推送 tag (触发 GitHub Actions 发布)"
    echo "  4. 更新所有版本号为 $NEXT_VERSION (不提交)"
    echo ""
    read -p "确认以上信息无误? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消"
        exit 0
    fi
    
    # Step 1: 更新到 release 版本
    echo ""
    echo "Step 1: 更新到 release 版本"
    Update_Version "$CURRENT_VERSION" "$RELEASE_VERSION"
    
    # Step 2: 提交 release 版本
    echo ""
    echo "Step 2: 提交 release 版本"
    git add .
    git commit -m "chore: release version $RELEASE_VERSION"
    echo "✓ 已提交"
    
    # Step 3: 打 tag
    echo ""
    echo "Step 3: 创建 tag"
    git tag -a "v$RELEASE_VERSION" -m "Release version $RELEASE_VERSION"
    echo "✓ Tag v$RELEASE_VERSION 已创建"
    
    # Step 4: 推送 tag
    echo ""
    echo "Step 4: 推送 tag (触发发布)"
    git push origin "v$RELEASE_VERSION"
    echo "✓ Tag 已推送"
    echo ""
    echo "🚀 GitHub Actions 正在发布..."
    echo "   查看进度: https://github.com/yangye2/classfinal/actions"
    echo ""
    
    # 可选: 本地构建 Docker 镜像
    read -p "是否在本地构建 Docker 镜像? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "构建 Docker 镜像..."
        Build_Docker_Images "$RELEASE_VERSION"
    fi
    
    # Step 5: 更新到下一个开发版本（不提交）
    echo ""
    echo "Step 5: 更新到下一个开发版本"
    Update_Version "$RELEASE_VERSION" "$NEXT_VERSION"
    
    echo ""
    echo "=== 发布流程完成 ==="
    echo ""
    echo "✅ Release 版本 $RELEASE_VERSION 已推送并触发 CI"
    echo "✅ 开发版本已更新为 $NEXT_VERSION (未提交)"
    echo ""
    echo "后续步骤:"
    echo "  1. 查看 GitHub Actions 发布进度"
    echo "     https://github.com/yangye2/classfinal/actions"
    echo ""
    echo "  2. 确认发布成功后，提交并推送开发版本:"
    echo "     git add . && git commit -m 'chore: prepare for next development iteration $NEXT_VERSION' && git push"
    echo ""
    echo "  3. 如果发布失败，可以回退修改:"
    echo "     git checkout ."
    echo ""
    echo "  4. Maven Central 发布成功后 15-30 分钟可搜索到"
    echo "     https://search.maven.org/search?q=g:io.github.ygqygq2"
}

Main "$@"

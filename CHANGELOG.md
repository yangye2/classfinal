**Changelog**

# 2.0.3

## 修复 🐛

### Spring Boot 3.2+ 嵌套 jar 路径解析（严重）
- 🐛 修复 `JarUtils.getRootPath()` 不识别 `jar:nested:` URL 前缀的问题。
  Spring Boot 3.2+ 的类来源形如 `jar:nested:/path/app.jar/!BOOT-INF/classes!/`，
  截取后得到非法路径，导致 agent 找不到 jar、`doDecrypt` 返回 null，
  类转换器静默放行——**应用实际跑在被清空方法体的空壳类上**（getter 返回 null、
  boolean 返回 false），只在遇到非法桩类时才报错，非常难排查。
- ✅ 增加 `nested:` 前缀处理后，解密恢复正常，可正常启动 Spring Boot 3.5 应用。

### 重打包丢失 jar 条目顺序
- 🐛 修复 `JarUtils.unJar()` 覆盖条目顺序记录的问题：
  `addClassFinalAgent()` 会用同一个 `targetDir` 释放 agent 自身的类，
  把主 jar 的条目顺序记录覆盖成 agent jar 的顺序，
  导致主 jar 的 `BOOT-INF/lib/*` 查不到记录、退化为字母序重排。
  后果是依赖加载优先级改变：若某个依赖内嵌了重复类（例如监管 SDK 里内嵌旧版 hutool），
  会抢先加载导致 `NoSuchMethodError`。
- ✅ 改为 `putIfAbsent`，保留原 jar 的条目顺序。

### 清空方法体产生非法字节码
- 🐛 修复 `ClassUtils.clearMethodBodyDirect()` 对 `long` / `float` / `double`
  返回值也生成 `{ return 0; }` 的问题（编译成 `ireturn`，与返回类型不符），
  导致 `VerifyError: Bad return type`。
- ✅ 按返回类型分别生成 `0L` / `0F` / `0D`，桩类字节码合法。

## 技术改进 📝

- `JarUtils.getRootPath()` 兼容 Spring Boot 3.2+ 的嵌套 jar URL 格式
- `JarUtils.unJar()` 条目顺序记录改为不覆盖
- `ClassUtils.clearMethodBodyDirect()` 按返回类型生成对应的 return 字面量

# 2.0.2

## 修复 🐛

### Lambda 表达式兼容性
- 🐛 修复加密包含 Lambda 表达式的类时出现 `VerifyError: Expecting a stack map frame` 错误
- ✅ 自动检测并跳过包含 Lambda 的类（避免 Javassist StackMapTable 重建问题）
- ✅ 在大型 Spring Boot 项目（如 Halo 2.22.8）上验证通过

### 方法体清空优化
- ✅ 智能识别安全类型（DTO/VO/Entity/Model/Bean/Info/Data/Param/Request/Response/Constant）
- ✅ 选择性清空安全类的方法体，减少源码泄露风险
- ✅ 保留枚举类、业务逻辑类完整性，确保应用正常运行

## 技术改进 📝

- 新增 `ByteCodeAnalyzer` 工具类：通过常量池分析检测 Lambda 表达式
- 优化 `clearClassMethod` 策略：基于类名模式匹配的白名单机制
- 增强错误处理：避免因字节码操作导致的运行时错误

# 2.0.1

## 新功能 ✨

### 配置文件支持 ✅
- ✅ YAML 配置文件加载 (`--config classfinal.yml`)
- ✅ 配置文件模板生成 (`--init-config`)
- ✅ 环境变量占位符 `${VAR_NAME}`
- ✅ 完整的配置验证

### 密码管理增强 ✅
- ✅ 从文件读取密码 (`--password-file`)
- ✅ 读取后自动删除密码文件
- ✅ 密码强度检查和警告
- ✅ 密码验证（最小长度 6 位）
- ✅ 环境变量密码读取

### 加密验证工具 ✅
- ✅ JAR 加密状态检测 (`--verify`)
- ✅ 加密统计信息（类数、加密率）
- ✅ 加密包列表展示
- ✅ 密码保护和机器绑定检测

### 命令行改进 ✅
- ✅ 支持 `--long-option` 格式
- ✅ `--password` 参数（同 `-pwd`）
- ✅ 新增 `--verify`、`--config`、`--init-config`、`--log-level` 等参数
- ✅ 日志级别控制（DEBUG|INFO|WARN|ERROR）
- ✅ 加密进度条显示优化

## 改进 🎯

### 用户体验
- ✅ 加密过程中显示实时进度条
- ✅ 日志级别控制，可灵活调整输出详度
- ✅ 友好的错误提示信息
- ✅ 密码强度提示和建议

# 2.0.0

## 新功能

- Docker 容器化支持（多阶段构建、环境变量配置）
- 环境变量非交互式配置（Main.java）
- 动态版本管理（MANIFEST.MF / 环境变量 / "dev"）
- 集成测试环境（Docker Compose）

## 重构

- GroupId 更改为 `io.github.ygqygq2`
- 镜像仓库迁移到 GitHub Container Registry
- 文档重组到 `docs/` 目录
- 统一容器路径为 `/app/app.jar`

## 修复

- Docker 构建缓存问题
- JavaAgent 密码读取逻辑
- 环境变量传递问题

## 文档

- 新增架构设计文档
- 新增 Docker 使用指南
- 新增开发指南
- 新增集成测试文档

# 1.2.1

**发布日期**: 2020-05-18  
**原作者**: roseboy

## 功能

- JAR/WAR 包加密
- JavaAgent 运行时解密
- Spring 框架兼容
- Maven 插件支持
- 无密码模式
- 机器码绑定
- Web 管理控制台

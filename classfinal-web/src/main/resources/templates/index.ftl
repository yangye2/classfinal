<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ClassFinal Web - Java Class 加密工具</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'PingFang SC', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        .container { max-width: 800px; margin: 0 auto; }
        .header { text-align: center; color: white; margin-bottom: 30px; }
        .header h1 { font-size: 36px; margin-bottom: 10px; }
        .header p { font-size: 16px; opacity: 0.9; }
        .card {
            background: white;
            border-radius: 12px;
            padding: 30px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.1);
        }
        .step { display: none; }
        .step.active { display: block; animation: fadeIn 0.3s; }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .step-title {
            font-size: 24px;
            color: #333;
            margin-bottom: 20px;
            padding-bottom: 15px;
            border-bottom: 2px solid #667eea;
        }
        .form-group { margin-bottom: 20px; }
        .form-group label {
            display: block;
            font-weight: 600;
            color: #555;
            margin-bottom: 8px;
        }
        .form-group input[type="text"],
        .form-group input[type="password"] {
            width: 100%;
            padding: 12px;
            border: 2px solid #e0e0e0;
            border-radius: 6px;
            font-size: 14px;
            transition: border-color 0.3s;
        }
        .form-group input:focus {
            outline: none;
            border-color: #667eea;
        }
        .upload-area {
            border: 2px dashed #667eea;
            border-radius: 8px;
            padding: 40px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
        }
        .upload-area:hover { background: #f8f9ff; border-color: #5568d3; }
        .upload-area.dragover { background: #f0f2ff; border-color: #4a5bc4; }
        .upload-icon { font-size: 48px; color: #667eea; margin-bottom: 10px; }
        .upload-text { color: #666; font-size: 14px; }
        .file-info {
            display: none;
            background: #f0f2ff;
            padding: 15px;
            border-radius: 6px;
            margin-top: 15px;
        }
        .file-info.show { display: block; }
        .checkbox-group {
            display: flex;
            align-items: center;
            margin-bottom: 15px;
        }
        .checkbox-group input[type="checkbox"] {
            margin-right: 8px;
            width: 18px;
            height: 18px;
        }
        .checkbox-group label { margin: 0; font-weight: normal; }
        .btn {
            padding: 12px 30px;
            border: none;
            border-radius: 6px;
            font-size: 16px;
            cursor: pointer;
            transition: all 0.3s;
            margin-right: 10px;
        }
        .btn-primary { background: #667eea; color: white; }
        .btn-primary:hover:not(:disabled) {
            background: #5568d3;
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(102,126,234,0.4);
        }
        .btn-secondary { background: #e0e0e0; color: #666; }
        .btn-secondary:hover { background: #d0d0d0; }
        .btn:disabled { opacity: 0.5; cursor: not-allowed; }
        .btn-group {
            margin-top: 30px;
            display: flex;
            justify-content: space-between;
        }
        .alert {
            padding: 12px 16px;
            border-radius: 6px;
            margin-bottom: 20px;
        }
        .alert-error { background: #fee; color: #c33; border: 1px solid #fcc; }
        .alert-success { background: #efe; color: #3c3; border: 1px solid #cfc; }
        .confirm-item {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid #f0f0f0;
        }
        .confirm-item:last-child { border-bottom: none; }
        .confirm-label { font-weight: 600; color: #666; }
        .confirm-value { color: #333; }
        .success-icon {
            font-size: 72px;
            color: #4caf50;
            text-align: center;
            margin-bottom: 20px;
        }
        .success-message {
            text-align: center;
            color: #666;
            margin-bottom: 30px;
        }
        .help-text { font-size: 13px; color: #999; margin-top: 5px; }
        .loading { display: none; text-align: center; padding: 20px; }
        .loading.show { display: block; }
        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
            margin: 0 auto 15px;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        input[type="file"] { display: none; }
        .footer {
            text-align: center;
            color: white;
            margin-top: 30px;
            opacity: 0.8;
        }
        .footer a { color: white; text-decoration: none; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🔒 ClassFinal Web</h1>
            <p>Java Class 文件加密工具 v2.0.2</p>
        </div>

        <div class="card">
            <!-- 步骤1: 上传文件 -->
            <div class="step active" id="step1">
                <h2 class="step-title">步骤 1: 上传 JAR/WAR 文件</h2>
                
                <div class="upload-area" id="uploadArea">
                    <div class="upload-icon">📦</div>
                    <div class="upload-text">
                        <p><strong>点击选择文件</strong> 或拖拽文件到此处</p>
                        <p class="help-text">支持 .jar 和 .war 文件</p>
                    </div>
                </div>
                <input type="file" id="fileInput" accept=".jar,.war">
                
                <div class="file-info" id="fileInfo">
                    <div><strong>文件名:</strong> <span id="fileName"></span></div>
                    <div><strong>大小:</strong> <span id="fileSize"></span></div>
                </div>

                <div class="btn-group">
                    <div></div>
                    <button class="btn btn-primary" id="nextToStep2" disabled>下一步</button>
                </div>
            </div>

            <!-- 步骤2: 配置加密参数 -->
            <div class="step" id="step2">
                <h2 class="step-title">步骤 2: 配置加密参数</h2>
                
                <div id="errorMsg"></div>
                
                <div class="form-group">
                    <label for="packages">要加密的包名 <span style="color: red;">*</span></label>
                    <input type="text" id="packages" placeholder="例如: com.example 或 com.example,org.myapp 或 * (加密所有)">
                    <div class="help-text">多个包名用逗号分隔，支持通配符: * (匹配任意) 或 ? (匹配单个字符)</div>
                </div>

                <div class="checkbox-group">
                    <input type="checkbox" id="nopwd">
                    <label for="nopwd">无密码模式（不推荐）</label>
                </div>

                <div class="form-group" id="passwordGroup">
                    <label for="password">加密密码 <span style="color: red;">*</span></label>
                    <input type="password" id="password" placeholder="请输入加密密码">
                    <div class="help-text">运行加密后的程序时需要提供此密码</div>
                </div>

                <div class="form-group">
                    <label for="exclude">排除的类（可选）</label>
                    <input type="text" id="exclude" placeholder="例如: com.example.Test,org.myapp.Debug">
                    <div class="help-text">多个类名用逗号分隔</div>
                </div>

                <div class="checkbox-group">
                    <input type="checkbox" id="libjars">
                    <label for="libjars">同时加密 lib 目录下的 jar 包</label>
                </div>

                <div class="btn-group">
                    <button class="btn btn-secondary" id="backToStep1">上一步</button>
                    <button class="btn btn-primary" id="nextToStep3">下一步</button>
                </div>
            </div>

            <!-- 步骤3: 确认信息 -->
            <div class="step" id="step3">
                <h2 class="step-title">步骤 3: 确认加密配置</h2>
                
                <div class="confirm-item">
                    <span class="confirm-label">文件名:</span>
                    <span class="confirm-value" id="confirmFilename"></span>
                </div>
                <div class="confirm-item">
                    <span class="confirm-label">加密包名:</span>
                    <span class="confirm-value" id="confirmPackages"></span>
                </div>
                <div class="confirm-item">
                    <span class="confirm-label">加密模式:</span>
                    <span class="confirm-value" id="confirmMode"></span>
                </div>
                <div class="confirm-item">
                    <span class="confirm-label">排除类:</span>
                    <span class="confirm-value" id="confirmExclude"></span>
                </div>
                <div class="confirm-item">
                    <span class="confirm-label">加密 lib:</span>
                    <span class="confirm-value" id="confirmLibjars"></span>
                </div>

                <div class="loading" id="loading">
                    <div class="spinner"></div>
                    <p>正在加密，请稍候...</p>
                </div>

                <div class="btn-group">
                    <button class="btn btn-secondary" id="backToStep2">上一步</button>
                    <button class="btn btn-primary" id="startEncrypt">开始加密</button>
                </div>
            </div>

            <!-- 步骤4: 完成 -->
            <div class="step" id="step4">
                <h2 class="step-title">加密完成</h2>
                
                <div class="success-icon">✓</div>
                <div class="success-message">
                    <p style="font-size: 18px; margin-bottom: 10px;">加密成功！</p>
                    <p>文件: <strong id="encryptedFilename"></strong></p>
                    <p>大小: <strong id="encryptedSize"></strong></p>
                </div>

                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px; margin-bottom: 20px;">
                    <p style="margin-bottom: 10px;"><strong>运行加密后的程序:</strong></p>
                    <code style="display: block; background: #fff; padding: 10px; border-radius: 4px; overflow-x: auto;">
java -javaagent:your-app-encrypted.jar='-pwd yourpassword' -jar your-app-encrypted.jar
                    </code>
                </div>

                <div class="btn-group">
                    <button class="btn btn-secondary" id="restart">重新加密</button>
                    <button class="btn btn-primary" id="downloadBtn">下载加密文件</button>
                </div>
            </div>
        </div>

        <div class="footer">
            <p>ClassFinal 2.0.2 | <a href="https://github.com/yangye2/classfinal" target="_blank">GitHub</a></p>
        </div>
    </div>

    <script src="/js/app.js"></script>
</body>
</html>

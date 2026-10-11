# 家爱相册 · 家庭相册及老人金婚分享平台

> 移动端 APP（Flutter）+ 后端服务（FastAPI）完整项目

<p align="center"><img src="assets/images/app_icon.png" width="96"></p>

## 功能概览

| 模块 | 功能 |
|---|---|
| 账号 | 手机号注册/登录（JWT）、个人资料、**长辈模式**（大字体大按钮） |
| 家庭圈 | 创建家庭圈 / 6 位邀请码加入、成员管理（创建者可移除） |
| 家庭相册 | 分类相册（节日/生日/旅行/日常/金婚）、照片上传（设备选图 / 链接）、点赞、评论、删除 |
| 金婚纪念 | 两位老人信息、携手天数、庆典倒计时、**爱情时光轴**、他们的故事 |
| 祝福墙 | 文字祝福、快捷祝福语、语音祝福（预留）、点赞 |
| 分享 | 相册 / 纪念专区 / 单张照片生成 30 天有效的 H5 分享链接（微信可直接打开） |
| 首页 | 家人头像栏、金婚横幅、今日回忆、最近相册、最新动态 |

## 目录结构

```
flutter_app/
├── lib/                      # Flutter 前端
│   ├── main.dart             # 入口 / 路由守卫（登录 → 家庭圈 → 主界面）
│   ├── theme/app_theme.dart  # Material 3 珊瑚暖色主题 + 长辈模式
│   ├── models/models.dart    # 数据模型
│   ├── services/             # api_service.dart (REST) / file_picker_service.dart
│   ├── providers/            # app_provider.dart (全局状态, Provider)
│   ├── widgets/common.dart   # 公共组件（头像、图片、状态页、分享弹窗）
│   └── screens/              # 登录 / 家庭圈设置 / 首页 / 相册 / 相册详情 / 上传
│                             # 照片详情 / 金婚纪念 / 祝福墙 / 家人圈 / 我的 / 底部导航
├── backend/                  # FastAPI 后端
│   ├── app/main.py           # 应用入口（CORS、静态上传目录、路由注册、自动建表+种子数据）
│   ├── app/models.py         # SQLAlchemy ORM
│   ├── app/schemas.py        # Pydantic 模型
│   ├── app/auth.py           # JWT + PBKDF2 密码
│   ├── app/routers/          # auth / family / album / anniversary / share / home
│   ├── app/seed.py           # 示例数据（王家大院 · 金婚纪念）
│   ├── requirements.txt / run.sh / Dockerfile / README.md
├── android/                  # 包名 com.jiaaixiangce.family，已配置权限与图标
├── web/                      # Web 端配置
└── serve_web.py              # Web 预览静态服务器
```

## 快速开始

### 1. 启动后端
```bash
cd backend
bash run.sh 8000          # 首次自动安装依赖、建表、写入示例数据
# 接口文档 http://localhost:8000/docs
```

### 2. 运行前端

```bash
flutter pub get

# Web 预览（后端在本机 8000）
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000

# Android 模拟器（10.0.2.2 指向宿主机）
flutter run -d emulator --dart-define=API_BASE_URL=http://10.0.2.2:8000

# 真机 / 生产：指向部署后的后端地址
flutter build apk --release --dart-define=API_BASE_URL=https://your-api.example.com
```

> 不传 `API_BASE_URL` 时默认 `http://localhost:8000`。

### 3. 体验账号（密码均 `123456`）

| 手机号 | 昵称 | 身份 |
|---|---|---|
| 13800000001 | 王建国 | 爷爷（家庭圈创建者，长辈模式） |
| 13800000002 | 李秀兰 | 奶奶（长辈模式） |
| 13800000003 | 王海 | 爸爸 |
| 13800000005 | 王小雨 | 孙女 |

新注册用户可用邀请码 **888888** 加入「王家大院」。

## 技术栈

- **前端**：Flutter 3.35 · Material 3 · Provider · http · shared_preferences · image_picker · intl
- **后端**：Python FastAPI · SQLAlchemy · SQLite · PyJWT · Uvicorn
- **部署**：后端提供 Dockerfile；前端支持 Android APK / Web 静态托管

## 生产注意事项

- 设置环境变量 `JWT_SECRET` 替换默认密钥
- 将 `DATABASE_URL` 指向 PostgreSQL/MySQL，`uploads/` 目录可替换为对象存储
- `android:usesCleartextTraffic="true"` 仅用于本地 HTTP 调试，生产请使用 HTTPS 并移除

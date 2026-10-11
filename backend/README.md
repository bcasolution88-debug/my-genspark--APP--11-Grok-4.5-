# 家爱相册 后端 (FastAPI)

## 启动
```bash
bash run.sh 8000
```
接口文档：http://localhost:8000/docs

## 测试账号（密码均为 123456）
| 手机号 | 昵称 | 身份 |
|---|---|---|
| 13800000001 | 王建国 | 爷爷（家庭圈创建者） |
| 13800000002 | 李秀兰 | 奶奶 |
| 13800000003 | 王海 | 爸爸 |
| 13800000004 | 张敏 | 妈妈 |
| 13800000005 | 王小雨 | 孙女 |
| 13800000006 | 王浩 | 孙子 |

家庭圈邀请码：`888888`

## 主要接口
- `POST /api/auth/register` `POST /api/auth/login` `GET/PUT /api/auth/me`
- `GET /api/home` 首页聚合
- `GET /api/family/mine` `POST /api/family/create` `POST /api/family/join` `GET /api/family/members`
- `GET/POST /api/albums` `GET /api/albums/{id}/photos` `POST /api/albums/{id}/photos`
- `POST /api/upload` 文件上传
- `GET /api/photos/recent` `POST /api/photos/{id}/like` `POST /api/photos/{id}/comments`
- `GET/POST /api/anniversary` `POST /api/anniversary/timeline` `GET/POST /api/anniversary/blessings`
- `POST /api/share` 生成分享链接 → `GET /s/{code}` H5 分享页

## Docker
```bash
docker build -t family-album-api . && docker run -p 8000:8000 family-album-api
```

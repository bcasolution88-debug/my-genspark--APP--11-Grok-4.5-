"""分享链接路由（公开访问，无需登录）"""
import secrets
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

from ..database import get_db
from .. import models, schemas
from ..auth import get_current_user, require_family
from ..serializers import album_out, photo_out, anniversary_out

router = APIRouter(tags=["分享"])


@router.post("/api/share", response_model=schemas.ShareOut)
def create_share(req: schemas.ShareCreate, request: Request, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    # 验证目标归属
    if req.target_type == "album":
        ok = db.query(models.Album).filter(models.Album.id == req.target_id, models.Album.family_id == family.id).first()
    elif req.target_type == "anniversary":
        ok = family.anniversary and family.anniversary.id == req.target_id
    elif req.target_type == "photo":
        p = db.query(models.Photo).filter(models.Photo.id == req.target_id).first()
        ok = p and p.album.family_id == family.id
    else:
        raise HTTPException(status_code=400, detail="不支持的分享类型")
    if not ok:
        raise HTTPException(status_code=404, detail="分享目标不存在")

    link = models.ShareLink(
        code=secrets.token_urlsafe(8),
        target_type=req.target_type,
        target_id=req.target_id,
        created_by=user.id,
        expires_at=datetime.utcnow() + timedelta(days=req.expires_days or 30),
    )
    db.add(link)
    db.commit()
    db.refresh(link)
    base = str(request.base_url).rstrip("/")
    return schemas.ShareOut(
        code=link.code, url=f"{base}/s/{link.code}", target_type=link.target_type,
        target_id=link.target_id, expires_at=link.expires_at, view_count=link.view_count,
    )


def _get_link(code: str, db: Session) -> models.ShareLink:
    link = db.query(models.ShareLink).filter(models.ShareLink.code == code).first()
    if not link:
        raise HTTPException(status_code=404, detail="分享链接不存在")
    if link.expires_at and link.expires_at < datetime.utcnow():
        raise HTTPException(status_code=410, detail="分享链接已过期")
    link.view_count = (link.view_count or 0) + 1
    db.commit()
    return link


@router.get("/api/share/{code}")
def get_share_data(code: str, db: Session = Depends(get_db)):
    link = _get_link(code, db)
    if link.target_type == "album":
        album = db.query(models.Album).filter(models.Album.id == link.target_id).first()
        if not album:
            raise HTTPException(status_code=404, detail="相册已删除")
        return {"type": "album", "album": album_out(album, db), "photos": [photo_out(p, db, False) for p in album.photos]}
    if link.target_type == "anniversary":
        an = db.query(models.Anniversary).filter(models.Anniversary.id == link.target_id).first()
        if not an:
            raise HTTPException(status_code=404, detail="纪念专区已删除")
        return {"type": "anniversary", "anniversary": anniversary_out(an)}
    photo = db.query(models.Photo).filter(models.Photo.id == link.target_id).first()
    if not photo:
        raise HTTPException(status_code=404, detail="照片已删除")
    return {"type": "photo", "photo": photo_out(photo, db)}


@router.get("/s/{code}", response_class=HTMLResponse)
def share_page(code: str, db: Session = Depends(get_db)):
    """简易 H5 分享页（微信/浏览器可直接打开）"""
    data = get_share_data(code, db)
    if data["type"] == "album":
        a = data["album"]
        imgs = "".join(f'<img src="{p.url}" alt="">' for p in data["photos"])
        title, sub = a.title, f"{a.photo_count} 张照片 · {a.category}"
    elif data["type"] == "anniversary":
        an = data["anniversary"]
        imgs = f'<img src="{an.cover_url}" alt="">' if an.cover_url else ""
        imgs += "".join(f'<div class="bless"><b>{b.nickname}</b>：{b.content or "[语音祝福]"}</div>' for b in an.blessings[:20])
        title, sub = f"{an.husband_name} ❤ {an.wife_name} · {an.title}", f"携手 {an.years_together} 年 · {an.days_together} 天"
    else:
        p = data["photo"]
        imgs = f'<img src="{p.url}" alt="">'
        title, sub = p.caption or "家庭照片", f"来自 {p.uploader_name}"
    return f"""<!doctype html><html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>{title} - 家爱相册</title>
<style>body{{margin:0;font-family:-apple-system,sans-serif;background:#FFF8F3;color:#333}}
header{{background:#E85D4C;color:#fff;padding:20px 16px}}h1{{margin:0;font-size:22px}}p{{margin:6px 0 0;opacity:.9}}
main{{padding:12px;display:grid;grid-template-columns:1fr 1fr;gap:8px}}img{{width:100%;border-radius:12px;display:block}}
.bless{{grid-column:1/-1;background:#fff;border-radius:12px;padding:12px;font-size:16px;box-shadow:0 2px 8px rgba(0,0,0,.06)}}
footer{{text-align:center;color:#999;padding:24px;font-size:13px}}</style></head>
<body><header><h1>{title}</h1><p>{sub}</p></header><main>{imgs}</main>
<footer>由「家爱相册」生成 · 记录家的温暖</footer></body></html>"""

"""相册与照片路由"""
import os
import uuid
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Request
from sqlalchemy.orm import Session

from ..database import get_db, UPLOAD_DIR
from .. import models, schemas
from ..auth import get_current_user, require_family
from ..serializers import album_out, photo_out, comment_out

router = APIRouter(prefix="/api", tags=["相册"])

ALLOWED_EXT = {".jpg", ".jpeg", ".png", ".gif", ".webp", ".mp4", ".mov", ".m4a", ".mp3", ".aac", ".wav"}


def _album_in_family(album_id: str, family: models.Family, db: Session) -> models.Album:
    album = db.query(models.Album).filter(models.Album.id == album_id, models.Album.family_id == family.id).first()
    if not album:
        raise HTTPException(status_code=404, detail="相册不存在")
    return album


# ---------- 文件上传 ----------
@router.post("/upload")
async def upload_file(request: Request, file: UploadFile = File(...), user: models.User = Depends(get_current_user)):
    ext = os.path.splitext(file.filename or "")[1].lower()
    if ext not in ALLOWED_EXT:
        raise HTTPException(status_code=400, detail="不支持的文件类型")
    name = f"{uuid.uuid4().hex}{ext}"
    path = os.path.join(UPLOAD_DIR, name)
    content = await file.read()
    if len(content) > 50 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="文件不能超过 50MB")
    with open(path, "wb") as f:
        f.write(content)
    base = str(request.base_url).rstrip("/")
    return {"url": f"{base}/uploads/{name}", "filename": name, "size": len(content)}


# ---------- 相册 ----------
@router.get("/albums", response_model=list[schemas.AlbumOut])
def list_albums(category: Optional[str] = None, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    q = db.query(models.Album).filter(models.Album.family_id == family.id)
    if category and category != "全部":
        q = q.filter(models.Album.category == category)
    albums = q.order_by(models.Album.created_at.desc()).all()
    return [album_out(a, db) for a in albums]


@router.post("/albums", response_model=schemas.AlbumOut)
def create_album(req: schemas.AlbumCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    album = models.Album(family_id=family.id, created_by=user.id, **req.model_dump())
    db.add(album)
    db.commit()
    db.refresh(album)
    return album_out(album, db)


@router.get("/albums/{album_id}", response_model=schemas.AlbumOut)
def get_album(album_id: str, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    return album_out(_album_in_family(album_id, family, db), db)


@router.put("/albums/{album_id}", response_model=schemas.AlbumOut)
def update_album(album_id: str, req: schemas.AlbumCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    album = _album_in_family(album_id, family, db)
    for k, v in req.model_dump(exclude_unset=True).items():
        setattr(album, k, v)
    db.commit()
    db.refresh(album)
    return album_out(album, db)


@router.delete("/albums/{album_id}")
def delete_album(album_id: str, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    album = _album_in_family(album_id, family, db)
    if album.created_by != user.id and family.owner_id != user.id:
        raise HTTPException(status_code=403, detail="无权删除该相册")
    db.delete(album)
    db.commit()
    return {"ok": True}


# ---------- 照片 ----------
@router.get("/albums/{album_id}/photos", response_model=list[schemas.PhotoOut])
def list_photos(album_id: str, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    album = _album_in_family(album_id, family, db)
    return [photo_out(p, db, with_comments=False) for p in album.photos]


@router.post("/albums/{album_id}/photos", response_model=schemas.PhotoOut)
def add_photo(album_id: str, req: schemas.PhotoCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    album = _album_in_family(album_id, family, db)
    photo = models.Photo(album_id=album.id, uploaded_by=user.id, **req.model_dump())
    db.add(photo)
    if not album.cover_url:
        album.cover_url = req.url
    db.commit()
    db.refresh(photo)
    return photo_out(photo, db)


@router.get("/photos/recent", response_model=list[schemas.PhotoOut])
def recent_photos(limit: int = 12, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    album_ids = [a.id for a in family.albums]
    if not album_ids:
        return []
    photos = (
        db.query(models.Photo)
        .filter(models.Photo.album_id.in_(album_ids))
        .order_by(models.Photo.created_at.desc())
        .limit(limit)
        .all()
    )
    return [photo_out(p, db, with_comments=False) for p in photos]


@router.get("/photos/{photo_id}", response_model=schemas.PhotoOut)
def get_photo(photo_id: str, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    photo = db.query(models.Photo).filter(models.Photo.id == photo_id).first()
    if not photo or photo.album.family_id != family.id:
        raise HTTPException(status_code=404, detail="照片不存在")
    return photo_out(photo, db)


@router.post("/photos/{photo_id}/like", response_model=schemas.PhotoOut)
def like_photo(photo_id: str, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    photo = db.query(models.Photo).filter(models.Photo.id == photo_id).first()
    if not photo or photo.album.family_id != family.id:
        raise HTTPException(status_code=404, detail="照片不存在")
    photo.likes = (photo.likes or 0) + 1
    db.commit()
    db.refresh(photo)
    return photo_out(photo, db)


@router.post("/photos/{photo_id}/comments", response_model=schemas.CommentOut)
def add_comment(photo_id: str, req: schemas.CommentCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    photo = db.query(models.Photo).filter(models.Photo.id == photo_id).first()
    if not photo or photo.album.family_id != family.id:
        raise HTTPException(status_code=404, detail="照片不存在")
    c = models.Comment(photo_id=photo.id, user_id=user.id, content=req.content)
    db.add(c)
    db.commit()
    db.refresh(c)
    return comment_out(c, db)


@router.delete("/photos/{photo_id}")
def delete_photo(photo_id: str, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    photo = db.query(models.Photo).filter(models.Photo.id == photo_id).first()
    if not photo or photo.album.family_id != family.id:
        raise HTTPException(status_code=404, detail="照片不存在")
    if photo.uploaded_by != user.id and family.owner_id != user.id:
        raise HTTPException(status_code=403, detail="无权删除该照片")
    db.delete(photo)
    db.commit()
    return {"ok": True}

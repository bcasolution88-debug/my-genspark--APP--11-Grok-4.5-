"""首页聚合接口"""
import random
from datetime import date
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from .. import models, schemas
from ..auth import get_current_user, get_user_family
from ..serializers import user_out, family_out, member_out, anniversary_out, album_out, photo_out

router = APIRouter(prefix="/api/home", tags=["首页"])


@router.get("", response_model=schemas.HomeSummary)
def home(user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = get_user_family(user, db)
    if not family:
        return schemas.HomeSummary(user=user_out(user))

    album_ids = [a.id for a in family.albums]
    recent_albums = (
        db.query(models.Album).filter(models.Album.family_id == family.id)
        .order_by(models.Album.created_at.desc()).limit(6).all()
    )
    recent_photos = []
    memory = None
    if album_ids:
        recent_photos = (
            db.query(models.Photo).filter(models.Photo.album_id.in_(album_ids))
            .order_by(models.Photo.created_at.desc()).limit(9).all()
        )
        all_photos = db.query(models.Photo).filter(models.Photo.album_id.in_(album_ids)).all()
        if all_photos:
            # 每天固定一张"今日回忆"
            rng = random.Random(date.today().toordinal())
            memory = rng.choice(all_photos)

    return schemas.HomeSummary(
        user=user_out(user),
        family=family_out(family, db),
        members=[member_out(m) for m in family.members],
        anniversary=anniversary_out(family.anniversary, include_lists=False) if family.anniversary else None,
        recent_albums=[album_out(a, db) for a in recent_albums],
        recent_photos=[photo_out(p, db, False) for p in recent_photos],
        memory_of_day=photo_out(memory, db, False) if memory else None,
    )

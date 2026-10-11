"""金婚纪念专区路由：时光轴 + 祝福墙"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from .. import models, schemas
from ..auth import get_current_user, require_family
from ..serializers import anniversary_out, blessing_out

router = APIRouter(prefix="/api/anniversary", tags=["金婚纪念"])


def _require_anniv(family: models.Family) -> models.Anniversary:
    if not family.anniversary:
        raise HTTPException(status_code=404, detail="还未创建金婚纪念专区")
    return family.anniversary


@router.get("", response_model=schemas.AnniversaryOut)
def get_anniversary(user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    return anniversary_out(_require_anniv(family))


@router.post("", response_model=schemas.AnniversaryOut)
def create_or_update(req: schemas.AnniversaryCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    an = family.anniversary
    if an:
        for k, v in req.model_dump(exclude_unset=True).items():
            setattr(an, k, v)
    else:
        an = models.Anniversary(family_id=family.id, **req.model_dump())
        db.add(an)
    db.commit()
    db.refresh(an)
    return anniversary_out(an)


# ---------- 时光轴 ----------
@router.post("/timeline", response_model=schemas.TimelineOut)
def add_timeline(req: schemas.TimelineCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    an = _require_anniv(family)
    ev = models.TimelineEvent(anniversary_id=an.id, **req.model_dump())
    db.add(ev)
    db.commit()
    db.refresh(ev)
    return schemas.TimelineOut.model_validate(ev)


@router.delete("/timeline/{event_id}")
def delete_timeline(event_id: str, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    an = _require_anniv(family)
    ev = db.query(models.TimelineEvent).filter(models.TimelineEvent.id == event_id, models.TimelineEvent.anniversary_id == an.id).first()
    if not ev:
        raise HTTPException(status_code=404, detail="事件不存在")
    db.delete(ev)
    db.commit()
    return {"ok": True}


# ---------- 祝福墙 ----------
@router.get("/blessings", response_model=list[schemas.BlessingOut])
def list_blessings(user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    an = _require_anniv(family)
    return [blessing_out(b) for b in an.blessings]


@router.post("/blessings", response_model=schemas.BlessingOut)
def add_blessing(req: schemas.BlessingCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    an = _require_anniv(family)
    if not req.content and not req.audio_url:
        raise HTTPException(status_code=400, detail="祝福内容不能为空")
    b = models.Blessing(
        anniversary_id=an.id,
        user_id=user.id,
        content=req.content,
        audio_url=req.audio_url,
        audio_duration=req.audio_duration or 0,
        blessing_type="voice" if req.audio_url else "text",
    )
    db.add(b)
    db.commit()
    db.refresh(b)
    return blessing_out(b)


@router.post("/blessings/{blessing_id}/like", response_model=schemas.BlessingOut)
def like_blessing(blessing_id: str, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    an = _require_anniv(family)
    b = db.query(models.Blessing).filter(models.Blessing.id == blessing_id, models.Blessing.anniversary_id == an.id).first()
    if not b:
        raise HTTPException(status_code=404, detail="祝福不存在")
    b.likes = (b.likes or 0) + 1
    db.commit()
    db.refresh(b)
    return blessing_out(b)


@router.delete("/blessings/{blessing_id}")
def delete_blessing(blessing_id: str, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    an = _require_anniv(family)
    b = db.query(models.Blessing).filter(models.Blessing.id == blessing_id, models.Blessing.anniversary_id == an.id).first()
    if not b:
        raise HTTPException(status_code=404, detail="祝福不存在")
    if b.user_id != user.id and family.owner_id != user.id:
        raise HTTPException(status_code=403, detail="无权删除")
    db.delete(b)
    db.commit()
    return {"ok": True}

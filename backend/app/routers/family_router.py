"""家庭圈路由"""
import random
import string
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from .. import models, schemas
from ..auth import get_current_user, get_user_family, require_family
from ..serializers import family_out, member_out

router = APIRouter(prefix="/api/family", tags=["家庭圈"])


def gen_invite_code(db: Session) -> str:
    while True:
        code = "".join(random.choices(string.digits, k=6))
        if not db.query(models.Family).filter(models.Family.invite_code == code).first():
            return code


@router.get("/mine", response_model=schemas.FamilyOut)
def my_family(user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    return family_out(require_family(user, db), db)


@router.post("/create", response_model=schemas.FamilyOut)
def create_family(req: schemas.FamilyCreate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if get_user_family(user, db):
        raise HTTPException(status_code=400, detail="您已加入家庭圈")
    family = models.Family(
        name=req.name,
        motto=req.motto,
        invite_code=gen_invite_code(db),
        owner_id=user.id,
        cover_url="https://images.unsplash.com/photo-1511895426328-dc8714191300?w=800",
    )
    db.add(family)
    db.flush()
    db.add(models.FamilyMember(family_id=family.id, user_id=user.id, role="owner"))
    db.commit()
    db.refresh(family)
    return family_out(family, db)


@router.post("/join", response_model=schemas.FamilyOut)
def join_family(req: schemas.FamilyJoin, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    if get_user_family(user, db):
        raise HTTPException(status_code=400, detail="您已加入家庭圈")
    family = db.query(models.Family).filter(models.Family.invite_code == req.invite_code.strip()).first()
    if not family:
        raise HTTPException(status_code=404, detail="邀请码无效")
    db.add(models.FamilyMember(family_id=family.id, user_id=user.id, role="member"))
    db.commit()
    db.refresh(family)
    return family_out(family, db)


@router.get("/members", response_model=list[schemas.MemberOut])
def members(user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    return [member_out(m) for m in family.members]


@router.delete("/members/{member_id}")
def remove_member(member_id: str, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    if family.owner_id != user.id:
        raise HTTPException(status_code=403, detail="只有家庭圈创建者可以移除成员")
    m = db.query(models.FamilyMember).filter(models.FamilyMember.id == member_id, models.FamilyMember.family_id == family.id).first()
    if not m:
        raise HTTPException(status_code=404, detail="成员不存在")
    if m.user_id == family.owner_id:
        raise HTTPException(status_code=400, detail="不能移除创建者")
    db.delete(m)
    db.commit()
    return {"ok": True}


@router.post("/leave")
def leave_family(user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    family = require_family(user, db)
    if family.owner_id == user.id:
        raise HTTPException(status_code=400, detail="创建者不能退出家庭圈")
    db.query(models.FamilyMember).filter(models.FamilyMember.family_id == family.id, models.FamilyMember.user_id == user.id).delete()
    db.commit()
    return {"ok": True}

"""认证与用户路由"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..database import get_db
from .. import models, schemas
from ..auth import hash_password, verify_password, create_access_token, get_current_user
from ..serializers import user_out

router = APIRouter(prefix="/api/auth", tags=["认证"])


@router.post("/register", response_model=schemas.TokenResponse)
def register(req: schemas.RegisterRequest, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.phone == req.phone).first():
        raise HTTPException(status_code=400, detail="该手机号已注册")
    user = models.User(
        phone=req.phone,
        password_hash=hash_password(req.password),
        nickname=req.nickname,
        role_name=req.role_name or "家人",
        avatar_url=f"https://api.dicebear.com/9.x/avataaars/png?seed={req.phone}&size=128",
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return schemas.TokenResponse(access_token=create_access_token(user.id), user=user_out(user))


@router.post("/login", response_model=schemas.TokenResponse)
def login(req: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.phone == req.phone).first()
    if not user or not verify_password(req.password, user.password_hash):
        raise HTTPException(status_code=401, detail="手机号或密码错误")
    return schemas.TokenResponse(access_token=create_access_token(user.id), user=user_out(user))


@router.get("/me", response_model=schemas.UserOut)
def me(user: models.User = Depends(get_current_user)):
    return user_out(user)


@router.put("/me", response_model=schemas.UserOut)
def update_me(req: schemas.UserUpdate, user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    for field, value in req.model_dump(exclude_unset=True).items():
        setattr(user, field, value)
    db.commit()
    db.refresh(user)
    return user_out(user)

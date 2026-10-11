"""Pydantic 请求/响应模型"""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


# ---------- Auth ----------
class RegisterRequest(BaseModel):
    phone: str = Field(..., min_length=6, max_length=20)
    password: str = Field(..., min_length=6)
    nickname: str = Field(..., min_length=1, max_length=20)
    role_name: Optional[str] = "家人"


class LoginRequest(BaseModel):
    phone: str
    password: str


class UserOut(BaseModel):
    id: str
    phone: str
    nickname: str
    avatar_url: Optional[str] = None
    role_name: Optional[str] = None
    elder_mode: bool = False
    created_at: datetime

    class Config:
        from_attributes = True


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class UserUpdate(BaseModel):
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
    role_name: Optional[str] = None
    elder_mode: Optional[bool] = None


# ---------- Family ----------
class FamilyCreate(BaseModel):
    name: str
    motto: Optional[str] = None


class FamilyJoin(BaseModel):
    invite_code: str


class MemberOut(BaseModel):
    id: str
    user_id: str
    nickname: str
    avatar_url: Optional[str] = None
    role_name: Optional[str] = None
    role: str
    joined_at: datetime


class FamilyOut(BaseModel):
    id: str
    name: str
    invite_code: str
    motto: Optional[str] = None
    cover_url: Optional[str] = None
    owner_id: str
    member_count: int
    album_count: int
    photo_count: int
    created_at: datetime


# ---------- Album / Photo ----------
class AlbumCreate(BaseModel):
    title: str
    description: Optional[str] = None
    category: Optional[str] = "日常"
    cover_url: Optional[str] = None
    event_date: Optional[datetime] = None


class AlbumOut(BaseModel):
    id: str
    family_id: str
    title: str
    description: Optional[str] = None
    cover_url: Optional[str] = None
    category: str
    event_date: Optional[datetime] = None
    created_by: str
    creator_name: Optional[str] = None
    photo_count: int
    created_at: datetime


class PhotoCreate(BaseModel):
    url: str
    thumbnail_url: Optional[str] = None
    caption: Optional[str] = None
    media_type: Optional[str] = "image"
    taken_at: Optional[datetime] = None


class CommentOut(BaseModel):
    id: str
    user_id: str
    nickname: str
    avatar_url: Optional[str] = None
    content: str
    created_at: datetime


class CommentCreate(BaseModel):
    content: str


class PhotoOut(BaseModel):
    id: str
    album_id: str
    url: str
    thumbnail_url: Optional[str] = None
    caption: Optional[str] = None
    media_type: str
    taken_at: Optional[datetime] = None
    uploaded_by: str
    uploader_name: Optional[str] = None
    likes: int
    comments: List[CommentOut] = []
    created_at: datetime


# ---------- Anniversary ----------
class AnniversaryCreate(BaseModel):
    title: Optional[str] = "金婚纪念"
    husband_name: str
    wife_name: str
    wedding_date: datetime
    celebration_date: Optional[datetime] = None
    story: Optional[str] = None
    cover_url: Optional[str] = None


class TimelineCreate(BaseModel):
    event_date: datetime
    title: str
    description: Optional[str] = None
    image_url: Optional[str] = None


class TimelineOut(BaseModel):
    id: str
    event_date: datetime
    title: str
    description: Optional[str] = None
    image_url: Optional[str] = None

    class Config:
        from_attributes = True


class BlessingCreate(BaseModel):
    content: Optional[str] = None
    audio_url: Optional[str] = None
    audio_duration: Optional[int] = 0
    blessing_type: Optional[str] = "text"


class BlessingOut(BaseModel):
    id: str
    user_id: str
    nickname: str
    avatar_url: Optional[str] = None
    role_name: Optional[str] = None
    content: Optional[str] = None
    audio_url: Optional[str] = None
    audio_duration: int
    blessing_type: str
    likes: int
    created_at: datetime


class AnniversaryOut(BaseModel):
    id: str
    family_id: str
    title: str
    husband_name: str
    wife_name: str
    wedding_date: datetime
    celebration_date: Optional[datetime] = None
    story: Optional[str] = None
    cover_url: Optional[str] = None
    years_together: int
    days_together: int
    days_until_celebration: Optional[int] = None
    blessing_count: int
    timeline: List[TimelineOut] = []
    blessings: List[BlessingOut] = []


# ---------- Share ----------
class ShareCreate(BaseModel):
    target_type: str  # album / anniversary / photo
    target_id: str
    expires_days: Optional[int] = 30


class ShareOut(BaseModel):
    code: str
    url: str
    target_type: str
    target_id: str
    expires_at: Optional[datetime] = None
    view_count: int


# ---------- Home ----------
class HomeSummary(BaseModel):
    user: UserOut
    family: Optional[FamilyOut] = None
    members: List[MemberOut] = []
    anniversary: Optional[AnniversaryOut] = None
    recent_albums: List[AlbumOut] = []
    recent_photos: List[PhotoOut] = []
    memory_of_day: Optional[PhotoOut] = None

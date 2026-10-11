"""ORM 数据模型"""
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from .database import Base


def gen_id() -> str:
    return uuid.uuid4().hex[:16]


class User(Base):
    __tablename__ = "users"
    id = Column(String, primary_key=True, default=gen_id)
    phone = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    nickname = Column(String, nullable=False)
    avatar_url = Column(String, nullable=True)
    role_name = Column(String, default="家人")  # 爷爷/奶奶/爸爸/妈妈...
    elder_mode = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    memberships = relationship("FamilyMember", back_populates="user", cascade="all, delete-orphan")


class Family(Base):
    __tablename__ = "families"
    id = Column(String, primary_key=True, default=gen_id)
    name = Column(String, nullable=False)
    invite_code = Column(String, unique=True, index=True, nullable=False)
    motto = Column(String, nullable=True)
    cover_url = Column(String, nullable=True)
    owner_id = Column(String, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    members = relationship("FamilyMember", back_populates="family", cascade="all, delete-orphan")
    albums = relationship("Album", back_populates="family", cascade="all, delete-orphan")
    anniversary = relationship("Anniversary", back_populates="family", uselist=False, cascade="all, delete-orphan")


class FamilyMember(Base):
    __tablename__ = "family_members"
    id = Column(String, primary_key=True, default=gen_id)
    family_id = Column(String, ForeignKey("families.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    role = Column(String, default="member")  # owner / admin / member
    joined_at = Column(DateTime, default=datetime.utcnow)

    family = relationship("Family", back_populates="members")
    user = relationship("User", back_populates="memberships")


class Album(Base):
    __tablename__ = "albums"
    id = Column(String, primary_key=True, default=gen_id)
    family_id = Column(String, ForeignKey("families.id"), nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    cover_url = Column(String, nullable=True)
    category = Column(String, default="日常")  # 节日/旅行/生日/日常/金婚
    event_date = Column(DateTime, nullable=True)
    created_by = Column(String, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    family = relationship("Family", back_populates="albums")
    photos = relationship("Photo", back_populates="album", cascade="all, delete-orphan", order_by="Photo.created_at.desc()")


class Photo(Base):
    __tablename__ = "photos"
    id = Column(String, primary_key=True, default=gen_id)
    album_id = Column(String, ForeignKey("albums.id"), nullable=False)
    url = Column(String, nullable=False)
    thumbnail_url = Column(String, nullable=True)
    caption = Column(String, nullable=True)
    media_type = Column(String, default="image")  # image / video
    taken_at = Column(DateTime, nullable=True)
    uploaded_by = Column(String, ForeignKey("users.id"), nullable=False)
    likes = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    album = relationship("Album", back_populates="photos")
    comments = relationship("Comment", back_populates="photo", cascade="all, delete-orphan")


class Comment(Base):
    __tablename__ = "comments"
    id = Column(String, primary_key=True, default=gen_id)
    photo_id = Column(String, ForeignKey("photos.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    photo = relationship("Photo", back_populates="comments")


class Anniversary(Base):
    """金婚纪念专区（每个家庭一个）"""
    __tablename__ = "anniversaries"
    id = Column(String, primary_key=True, default=gen_id)
    family_id = Column(String, ForeignKey("families.id"), nullable=False, unique=True)
    title = Column(String, default="金婚纪念")
    husband_name = Column(String, nullable=False)
    wife_name = Column(String, nullable=False)
    wedding_date = Column(DateTime, nullable=False)
    celebration_date = Column(DateTime, nullable=True)
    story = Column(Text, nullable=True)
    cover_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    family = relationship("Family", back_populates="anniversary")
    timeline = relationship("TimelineEvent", back_populates="anniversary", cascade="all, delete-orphan", order_by="TimelineEvent.event_date")
    blessings = relationship("Blessing", back_populates="anniversary", cascade="all, delete-orphan", order_by="Blessing.created_at.desc()")


class TimelineEvent(Base):
    __tablename__ = "timeline_events"
    id = Column(String, primary_key=True, default=gen_id)
    anniversary_id = Column(String, ForeignKey("anniversaries.id"), nullable=False)
    event_date = Column(DateTime, nullable=False)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    anniversary = relationship("Anniversary", back_populates="timeline")


class Blessing(Base):
    """祝福墙留言（文字/语音）"""
    __tablename__ = "blessings"
    id = Column(String, primary_key=True, default=gen_id)
    anniversary_id = Column(String, ForeignKey("anniversaries.id"), nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=True)
    audio_url = Column(String, nullable=True)
    audio_duration = Column(Integer, default=0)
    blessing_type = Column(String, default="text")  # text / voice
    likes = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    anniversary = relationship("Anniversary", back_populates="blessings")
    user = relationship("User")


class ShareLink(Base):
    __tablename__ = "share_links"
    id = Column(String, primary_key=True, default=gen_id)
    code = Column(String, unique=True, index=True, nullable=False)
    target_type = Column(String, nullable=False)  # album / anniversary / photo
    target_id = Column(String, nullable=False)
    created_by = Column(String, ForeignKey("users.id"), nullable=False)
    expires_at = Column(DateTime, nullable=True)
    view_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

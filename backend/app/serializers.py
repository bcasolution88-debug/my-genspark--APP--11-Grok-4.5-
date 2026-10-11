"""ORM -> 响应模型转换"""
from datetime import datetime
from sqlalchemy.orm import Session
from . import models, schemas


def user_out(u: models.User) -> schemas.UserOut:
    return schemas.UserOut.model_validate(u)


def member_out(m: models.FamilyMember) -> schemas.MemberOut:
    return schemas.MemberOut(
        id=m.id,
        user_id=m.user_id,
        nickname=m.user.nickname,
        avatar_url=m.user.avatar_url,
        role_name=m.user.role_name,
        role=m.role,
        joined_at=m.joined_at,
    )


def family_out(f: models.Family, db: Session) -> schemas.FamilyOut:
    album_ids = [a.id for a in f.albums]
    photo_count = 0
    if album_ids:
        photo_count = db.query(models.Photo).filter(models.Photo.album_id.in_(album_ids)).count()
    return schemas.FamilyOut(
        id=f.id,
        name=f.name,
        invite_code=f.invite_code,
        motto=f.motto,
        cover_url=f.cover_url,
        owner_id=f.owner_id,
        member_count=len(f.members),
        album_count=len(f.albums),
        photo_count=photo_count,
        created_at=f.created_at,
    )


def album_out(a: models.Album, db: Session) -> schemas.AlbumOut:
    creator = db.query(models.User).filter(models.User.id == a.created_by).first()
    photo_count = db.query(models.Photo).filter(models.Photo.album_id == a.id).count()
    cover = a.cover_url
    if not cover and photo_count:
        first = db.query(models.Photo).filter(models.Photo.album_id == a.id).order_by(models.Photo.created_at.desc()).first()
        cover = first.url if first else None
    return schemas.AlbumOut(
        id=a.id,
        family_id=a.family_id,
        title=a.title,
        description=a.description,
        cover_url=cover,
        category=a.category,
        event_date=a.event_date,
        created_by=a.created_by,
        creator_name=creator.nickname if creator else None,
        photo_count=photo_count,
        created_at=a.created_at,
    )


def comment_out(c: models.Comment, db: Session) -> schemas.CommentOut:
    u = db.query(models.User).filter(models.User.id == c.user_id).first()
    return schemas.CommentOut(
        id=c.id,
        user_id=c.user_id,
        nickname=u.nickname if u else "家人",
        avatar_url=u.avatar_url if u else None,
        content=c.content,
        created_at=c.created_at,
    )


def photo_out(p: models.Photo, db: Session, with_comments: bool = True) -> schemas.PhotoOut:
    u = db.query(models.User).filter(models.User.id == p.uploaded_by).first()
    return schemas.PhotoOut(
        id=p.id,
        album_id=p.album_id,
        url=p.url,
        thumbnail_url=p.thumbnail_url or p.url,
        caption=p.caption,
        media_type=p.media_type,
        taken_at=p.taken_at,
        uploaded_by=p.uploaded_by,
        uploader_name=u.nickname if u else None,
        likes=p.likes or 0,
        comments=[comment_out(c, db) for c in p.comments] if with_comments else [],
        created_at=p.created_at,
    )


def blessing_out(b: models.Blessing) -> schemas.BlessingOut:
    return schemas.BlessingOut(
        id=b.id,
        user_id=b.user_id,
        nickname=b.user.nickname if b.user else "家人",
        avatar_url=b.user.avatar_url if b.user else None,
        role_name=b.user.role_name if b.user else None,
        content=b.content,
        audio_url=b.audio_url,
        audio_duration=b.audio_duration or 0,
        blessing_type=b.blessing_type,
        likes=b.likes or 0,
        created_at=b.created_at,
    )


def anniversary_out(an: models.Anniversary, include_lists: bool = True) -> schemas.AnniversaryOut:
    now = datetime.utcnow()
    days = (now - an.wedding_date).days
    years = now.year - an.wedding_date.year
    if (now.month, now.day) < (an.wedding_date.month, an.wedding_date.day):
        years -= 1
    until = None
    if an.celebration_date:
        until = (an.celebration_date.date() - now.date()).days
    return schemas.AnniversaryOut(
        id=an.id,
        family_id=an.family_id,
        title=an.title,
        husband_name=an.husband_name,
        wife_name=an.wife_name,
        wedding_date=an.wedding_date,
        celebration_date=an.celebration_date,
        story=an.story,
        cover_url=an.cover_url,
        years_together=max(years, 0),
        days_together=max(days, 0),
        days_until_celebration=until,
        blessing_count=len(an.blessings),
        timeline=[schemas.TimelineOut.model_validate(t) for t in an.timeline] if include_lists else [],
        blessings=[blessing_out(b) for b in an.blessings] if include_lists else [],
    )

"""示例种子数据：王家 · 金婚纪念"""
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from . import models
from .auth import hash_password

AVATAR = "https://api.dicebear.com/9.x/avataaars/png?seed={}&size=128"
U = "https://images.unsplash.com/{}?w=900&q=80"

USERS = [
    # phone, password, nickname, role_name, role
    ("13800000001", "123456", "王建国", "爷爷", "owner"),
    ("13800000002", "123456", "李秀兰", "奶奶", "admin"),
    ("13800000003", "123456", "王海", "爸爸", "admin"),
    ("13800000004", "123456", "张敏", "妈妈", "member"),
    ("13800000005", "123456", "王小雨", "孙女", "member"),
    ("13800000006", "123456", "王浩", "孙子", "member"),
]

ALBUMS = [
    ("春节团圆", "节日", "2025年春节，全家十口人齐聚老宅，热热闹闹过大年。", -260, [
        ("photo-1582653291997-079a1c04e5a1", "年夜饭开席啦，奶奶包的饺子最香"),
        ("photo-1548094891-c4ba474efd16", "贴春联，爷爷写的字越来越有劲"),
        ("photo-1611516491426-03025e6043c8", "小雨和浩浩放烟花"),
        ("photo-1543157145-f78c636d023d", "全家福！"),
    ]),
    ("奶奶七十大寿", "生日", "奶奶七十岁生日宴，三代同堂为她庆生。", -120, [
        ("photo-1464349095431-e9a21285b5f3", "七十岁生日蛋糕"),
        ("photo-1530103862676-de8c9debad1d", "奶奶吹蜡烛许愿"),
        ("photo-1513151233558-d860c5398176", "寿宴现场"),
    ]),
    ("桂林山水之旅", "旅行", "带爸妈去桂林，漓江泛舟，阳朔骑行。", -75, [
        ("photo-1537531383496-f4749b8032cf", "漓江山水甲天下"),
        ("photo-1528127269322-539801943592", "阳朔西街夜景"),
        ("photo-1537996194471-e657df975ab4", "爸妈在象鼻山前合影"),
        ("photo-1500530855697-b586d89ba3ee", "清晨的桂林"),
    ]),
    ("周末家庭日", "日常", "每个周末，一家人聚在一起吃饭、散步、聊天。", -10, [
        ("photo-1511895426328-dc8714191300", "阳台上的午后茶"),
        ("photo-1609220136736-443140cffec6", "公园散步"),
        ("photo-1476703993599-0035a21b17a9", "小雨的钢琴课"),
    ]),
    ("金婚纪念筹备", "金婚", "为爷爷奶奶金婚五十周年庆典做准备。", -3, [
        ("photo-1519741497674-611481863552", "金婚纪念照试拍"),
        ("photo-1465495976277-4387d4b0b4c6", "庆典场地布置"),
        ("photo-1522673607200-164d1b6ce486", "爷爷奶奶的老照片翻拍"),
    ]),
]

TIMELINE = [
    ("1975-10-01", "喜结连理", "在县城的小礼堂举办了简单而温馨的婚礼，亲友们见证了这一刻。", "photo-1522673607200-164d1b6ce486"),
    ("1977-06-15", "大儿子出生", "王海出生，家里添了新成员，日子虽苦却充满希望。", None),
    ("1985-03-20", "搬进新家", "两人努力多年，终于在城里买了第一套房子。", "photo-1560448204-e02f11c3d0e2"),
    ("1995-10-01", "银婚纪念", "结婚二十周年，孩子们第一次为父母举办纪念聚会。", None),
    ("2005-08-12", "第一个孙辈出生", "孙女小雨出生，爷爷奶奶升级，笑得合不拢嘴。", "photo-1476703993599-0035a21b17a9"),
    ("2015-10-01", "红宝石婚", "四十周年，全家一起去北京旅行，在天安门前合影。", "photo-1508804185872-d7badad00f7d"),
    ("2025-10-01", "金婚五十年", "携手走过半个世纪，爱情历久弥新。", "photo-1519741497674-611481863552"),
]

BLESSINGS = [
    ("13800000003", "爸妈，五十年风雨同舟，你们是我们最好的榜样。祝你们金婚快乐，健康长寿！", "text", None, 0),
    ("13800000004", "爸爸妈妈，感谢你们这么多年对我们小家的照顾，愿你们永远幸福安康！", "text", None, 0),
    ("13800000005", "爷爷奶奶金婚快乐！你们的爱情故事是我听过最美的童话。", "text", None, 0),
    ("13800000006", "爷爷奶奶，祝你们白头偕老，永远开心！等我长大了带你们环游世界！", "text", None, 0),
    ("13800000005", None, "voice", "https://www.soundhelix.com/examples/audio/SoundHelix-Song-1.mp3", 18),
    ("13800000002", "老头子，这五十年辛苦你了。往后余生，还请多多关照。", "text", None, 0),
]


def seed(db: Session) -> None:
    if db.query(models.User).count() > 0:
        return

    users = {}
    for phone, pwd, nick, role_name, _ in USERS:
        u = models.User(phone=phone, password_hash=hash_password(pwd), nickname=nick,
                        role_name=role_name, avatar_url=AVATAR.format(phone),
                        elder_mode=role_name in ("爷爷", "奶奶"))
        db.add(u)
        users[phone] = u
    db.flush()

    owner = users["13800000001"]
    family = models.Family(name="王家大院", invite_code="888888", motto="家和万事兴",
                           owner_id=owner.id, cover_url=U.format("photo-1543157145-f78c636d023d"))
    db.add(family)
    db.flush()

    for phone, _, _, _, role in USERS:
        db.add(models.FamilyMember(family_id=family.id, user_id=users[phone].id, role=role,
                                   joined_at=datetime.utcnow() - timedelta(days=300)))

    uploaders = ["13800000003", "13800000004", "13800000005", "13800000006"]
    for i, (title, cat, desc, days_ago, photos) in enumerate(ALBUMS):
        created = datetime.utcnow() + timedelta(days=days_ago)
        album = models.Album(family_id=family.id, title=title, category=cat, description=desc,
                             event_date=created, created_by=users[uploaders[i % 4]].id,
                             created_at=created, cover_url=U.format(photos[0][0]))
        db.add(album)
        db.flush()
        for j, (pid, caption) in enumerate(photos):
            p = models.Photo(album_id=album.id, url=U.format(pid), thumbnail_url=U.format(pid).replace("w=900", "w=400"),
                             caption=caption, uploaded_by=users[uploaders[(i + j) % 4]].id,
                             taken_at=created, created_at=created + timedelta(minutes=j * 7), likes=(i * 3 + j * 2) % 9)
            db.add(p)
            db.flush()
            if j == 0:
                db.add(models.Comment(photo_id=p.id, user_id=users["13800000002"].id, content="拍得真好，看着就开心！"))
                db.add(models.Comment(photo_id=p.id, user_id=users["13800000005"].id, content="哈哈这张我最喜欢"))

    an = models.Anniversary(
        family_id=family.id, title="金婚纪念", husband_name="王建国", wife_name="李秀兰",
        wedding_date=datetime(1975, 10, 1), celebration_date=datetime.utcnow() + timedelta(days=12),
        story="1975年的秋天，在同一个纺织厂工作的建国和秀兰走到了一起。五十年来，他们一起经历了下岗再就业、抚养子女、搬家换城，无论风雨，始终牵着彼此的手。如今子孙满堂，他们最大的幸福，就是每个周末一家人围坐在一起吃饭。",
        cover_url=U.format("photo-1519741497674-611481863552"),
    )
    db.add(an)
    db.flush()

    for d, title, desc, pid in TIMELINE:
        db.add(models.TimelineEvent(anniversary_id=an.id, event_date=datetime.strptime(d, "%Y-%m-%d"),
                                    title=title, description=desc, image_url=U.format(pid) if pid else None))

    for k, (phone, content, btype, audio, dur) in enumerate(BLESSINGS):
        db.add(models.Blessing(anniversary_id=an.id, user_id=users[phone].id, content=content,
                               blessing_type=btype, audio_url=audio, audio_duration=dur,
                               likes=(7 - k) * 2, created_at=datetime.utcnow() - timedelta(hours=k * 5 + 1)))

    db.commit()

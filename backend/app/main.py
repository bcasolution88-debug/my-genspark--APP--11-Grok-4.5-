"""家爱相册 后端服务 - FastAPI"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from .database import engine, Base, SessionLocal, UPLOAD_DIR
from .seed import seed
from .routers import auth_router, family_router, album_router, anniversary_router, share_router, home_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed(db)
    finally:
        db.close()
    yield


app = FastAPI(
    title="家爱相册 API",
    description="家庭相册及老人金婚分享平台 - 后端服务",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")

app.include_router(auth_router.router)
app.include_router(family_router.router)
app.include_router(album_router.router)
app.include_router(anniversary_router.router)
app.include_router(share_router.router)
app.include_router(home_router.router)


@app.get("/", tags=["系统"])
def root():
    return {"name": "家爱相册 API", "version": "1.0.0", "docs": "/docs", "status": "ok"}


@app.get("/health", tags=["系统"])
def health():
    return {"status": "ok"}

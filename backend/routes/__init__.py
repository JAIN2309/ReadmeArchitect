from fastapi import APIRouter
from .readme_routes import router as readme_router
from .history_routes import router as history_router
from .pr_routes import router as pr_router

router = APIRouter()

router.include_router(readme_router)
router.include_router(history_router)
router.include_router(pr_router)

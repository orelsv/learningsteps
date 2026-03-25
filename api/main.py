from fastapi import FastAPI
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
from routers.journal_router import router as journal_router
import logging

load_dotenv()

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="LearningSteps API",
    description="A simple learning journal API for tracking daily work, struggles, and intentions"
)

app.include_router(journal_router)

@app.get("/health")
async def health_check():
    logger.info("Health check called")
    return JSONResponse({"status": "healthy"})

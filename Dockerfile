FROM python:3.11-slim
WORKDIR /app
COPY api/requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir "jaraco.context>=6.1.0" "wheel>=0.46.2"
COPY api/ .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]

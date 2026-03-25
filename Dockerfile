# Базовий образ — Python 3.11, slim = без зайвого сміття, менший розмір
FROM python:3.11-slim

# Робоча директорія всередині контейнера
WORKDIR /app

# Копіюємо ТІЛЬКИ requirements спочатку — окремий шар
# Якщо код зміниться але requirements ні — Docker не перевстановлює бібліотеки
COPY api/requirements.txt .

# Встановлюємо залежності
# --no-cache-dir — не зберігати кеш pip, зменшує розмір образу
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь код API
COPY api/ .

# Документуємо порт (не відкриває сам — це робить docker run або K8s)
EXPOSE 8000

# Запускаємо uvicorn
# --host 0.0.0.0 — слухати на всіх інтерфейсах (не тільки localhost!)
# БЕЗ --reload в production — це для розробки
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
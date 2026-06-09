FROM python:3.12-slim

WORKDIR /app

# Install uv for fast dependency resolution
RUN pip install uv --quiet

# Copy dependency manifest first (layer cache)
COPY pyproject.toml .

# Install dependencies
RUN uv pip install --system --no-cache -e .

# Copy source
COPY . .

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

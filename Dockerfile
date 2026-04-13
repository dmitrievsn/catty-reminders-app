FROM python:3.12-slim

WORKDIR /app

ARG DEPLOY_REF=NA
ENV DEPLOY_REF=${DEPLOY_REF}

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8181

CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8181"]

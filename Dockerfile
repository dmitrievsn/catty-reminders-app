FROM python:3.12-slim

WORKDIR /app

ARG DEPLOY_REF=NA
ENV DEPLOY_REF=${DEPLOY_REF}

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8181

CMD ["/entrypoint.sh"]

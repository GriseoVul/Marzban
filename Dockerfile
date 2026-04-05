ARG PYTHON_VERSION=3.12

FROM python:$PYTHON_VERSION-slim AS build

ENV PYTHONUNBUFFERED=1

WORKDIR /code

# installing utilities, xray
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential curl unzip gcc python3-dev libpq-dev \
    && curl -L https://github.com/Gozargah/Marzban-scripts/raw/master/install_latest_xray.sh | bash \
    && rm -rf /var/lib/apt/lists/*

# create virual env
RUN python -m venv /venv
ENV PATH="/venv/bin:$PATH"

# requirements and setuptools
COPY requirements.txt .
RUN pip install --upgrade pip setuptools \
    && pip install --no-cache-dir --upgrade -r requirements.txt

FROM python:$PYTHON_VERSION-slim AS runtime
WORKDIR /code

# runtime deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq5 \
    && rm -rf /var/lib/apt/lists/*

# copying environment from build 
COPY --from=build /venv /venv
ENV PATH="/venv/bin:$PATH"

# moving xray binaries and files
COPY --from=build /usr/local/bin/xray /usr/local/bin/xray
COPY --from=build /usr/local/share/xray /usr/local/share/xray
COPY . /code

# create user
RUN useradd -m appuser && chown -R appuser:appuser /code /venv
USER appuser

# RUN ./marzban-cli.py completion install --shell bash

CMD ["bash", "-c", "alembic upgrade head; python main.py"]

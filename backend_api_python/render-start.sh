#!/bin/sh
# Render startup script to run migration, workers, and API in a single container

echo "============================================"
# 1. Run database migrations
echo "Running database migrations..."
QD_PROCESS_ROLE=migration python -m app.commands.migrate

# 2. Export the port Render expects us to listen on
if [ -n "$PORT" ]; then
  echo "Setting PYTHON_API_PORT to $PORT"
  export PYTHON_API_PORT=$PORT
fi

# 3. Start the Celery background worker
echo "Starting Celery worker..."
celery -A app.celery_app:celery_app worker --loglevel=info &

# 4. Start the Trading background worker
echo "Starting Trading worker..."
python -m app.commands.trading_worker &

# 5. Start the Flask API server using Gunicorn in the foreground
echo "Starting Gunicorn API server..."
exec gunicorn -c gunicorn_config.py run:app

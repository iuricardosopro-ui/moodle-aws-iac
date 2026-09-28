#!/bin/sh
set -e

# Wait for the database to accept connections before Apache starts serving
# requests — avoids the classic "container is Running but Moodle 500s" ECS
# startup race, without needing an external wait-for-it dependency.
echo "Waiting for database at ${MOODLE_DATABASE_HOST}..."
for i in $(seq 1 30); do
  if php -r "
    \$c = @mysqli_connect(getenv('MOODLE_DATABASE_HOST'), getenv('MOODLE_DATABASE_USER'), getenv('MOODLE_DATABASE_PASSWORD'));
    exit(\$c ? 0 : 1);
  "; then
    echo "Database is reachable."
    break
  fi
  echo "  attempt $i/30 failed, retrying in 5s..."
  sleep 5
done

exec "$@"

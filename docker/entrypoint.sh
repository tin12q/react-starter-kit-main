#!/bin/sh

set -e

echo "Starting Laravel application..."

# Wait for database to be ready (if using external DB)
if [ "$DB_CONNECTION" != "sqlite" ]; then
    echo "Waiting for database connection..."
    until php artisan migrate:status 2>/dev/null; do
        echo "Database is unavailable - sleeping"
        sleep 2
    done
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cp .env.example .env
    echo "Generating application key..."
    php artisan key:generate --force --no-interaction
else
    # Check if APP_KEY is set properly
    if ! grep -q "^APP_KEY=base64:" .env; then
        echo "Application key not found, generating..."
        php artisan key:generate --force --no-interaction
    fi
fi

# Create SQLite database if it doesn't exist
if [ "$DB_CONNECTION" = "sqlite" ]; then
    if [ ! -f database/database.sqlite ]; then
        echo "Creating SQLite database..."
        touch database/database.sqlite
        chown www-data:www-data database/database.sqlite
    fi
fi

# Run migrations
echo "Running database migrations..."
php artisan migrate --force --no-interaction || echo "Migration failed or already up to date"

# Clear and cache configurations
echo "Optimizing application..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Create storage link
php artisan storage:link || echo "Storage link already exists"

# Set proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

echo "Application is ready!"

# Execute the main command
exec "$@"

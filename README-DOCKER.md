# Docker Setup Guide

Hướng dẫn chạy ứng dụng Laravel + React với Docker.

## Yêu cầu

- Docker Desktop (hoặc Docker Engine + Docker Compose)
- Git

## Cấu trúc Docker

Dự án bao gồm 2 môi trường:

1. **Production** (`Dockerfile`, `docker-compose.yml`): Sử dụng Nginx + PHP-FPM + Supervisor
2. **Development** (`Dockerfile.dev`, `docker-compose.dev.yml`): Sử dụng PHP built-in server + Vite HMR

## Chạy môi trường Production

### Bước 1: Build và khởi động containers

```bash
docker-compose up -d --build
```

### Bước 2: Truy cập ứng dụng

Mở trình duyệt và truy cập: `http://localhost:8000`

### Các lệnh hữu ích

```bash
# Xem logs
docker-compose logs -f app

# Chạy Artisan commands
docker-compose exec app php artisan migrate
docker-compose exec app php artisan cache:clear

# Truy cập container shell
docker-compose exec app sh

# Dừng containers
docker-compose down

# Dừng và xóa volumes
docker-compose down -v
```

## Chạy môi trường Development

### Bước 1: Build và khởi động containers

```bash
docker-compose -f docker-compose.dev.yml up -d --build
```

### Bước 2: Truy cập ứng dụng

- Laravel: `http://localhost:8000`
- Vite HMR: `http://localhost:5173`

### Lưu ý cho Development

- Code thay đổi sẽ tự động reload (hot reload)
- Vite dev server chạy trên port 5173
- PHP artisan serve chạy trên port 8000

### Các lệnh hữu ích cho Development

```bash
# Xem logs
docker-compose -f docker-compose.dev.yml logs -f app

# Cài đặt package mới
docker-compose -f docker-compose.dev.yml exec app composer require package/name
docker-compose -f docker-compose.dev.yml exec app npm install package-name

# Chạy tests
docker-compose -f docker-compose.dev.yml exec app php artisan test

# Dừng containers
docker-compose -f docker-compose.dev.yml down
```

## Services

### App Container
- **Port**: 8000 (production), 8000 + 5173 (development)
- **Chứa**: Laravel application, PHP, Nginx (prod only)

### Redis Container
- **Port**: 6379
- **Dùng cho**: Cache, Queue, Session (optional)

### MySQL Container (Optional)
- **Port**: 3306
- **Credentials**: 
  - Database: `laravel`
  - Username: `laravel`
  - Password: `secret`

Để sử dụng MySQL thay vì SQLite, uncomment phần MySQL trong `docker-compose.yml` và cập nhật `.env`:

```env
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=laravel
DB_USERNAME=laravel
DB_PASSWORD=secret
```

## Cấu hình Environment

File `.env` sẽ được tự động tạo từ `.env.example` khi container khởi động lần đầu.

### Production Environment
```env
APP_ENV=production
APP_DEBUG=false
APP_URL=http://localhost:8000
DB_CONNECTION=sqlite
```

### Development Environment
```env
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000
```

## Troubleshooting

### Permission Issues

```bash
# Fix storage permissions
docker-compose exec app chown -R www-data:www-data storage bootstrap/cache
docker-compose exec app chmod -R 775 storage bootstrap/cache
```

### Database Issues

```bash
# Reset database
docker-compose exec app php artisan migrate:fresh --seed

# Check migration status
docker-compose exec app php artisan migrate:status
```

### Clear All Caches

```bash
docker-compose exec app php artisan optimize:clear
docker-compose exec app php artisan config:clear
docker-compose exec app php artisan route:clear
docker-compose exec app php artisan view:clear
docker-compose exec app php artisan cache:clear
```

### Rebuild from scratch

```bash
# Stop and remove everything
docker-compose down -v
docker system prune -a

# Rebuild
docker-compose up -d --build
```

## Performance Optimization

### Production Build
Dockerfile production đã bao gồm:
- ✅ Multi-stage build để giảm image size
- ✅ Opcache enabled
- ✅ Asset pre-compilation (Vite build)
- ✅ Composer optimization
- ✅ Nginx caching headers
- ✅ Gzip compression

### Resource Limits
Có thể thêm resource limits trong `docker-compose.yml`:

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

## Cấu trúc Thư mục Docker

```
docker/
├── nginx/
│   ├── nginx.conf          # Nginx main config
│   └── default.conf        # Site configuration
├── php/
│   ├── php.ini            # PHP configuration
│   └── www.conf           # PHP-FPM pool config
├── supervisor/
│   └── supervisord.conf   # Supervisor config (queue, schedule)
└── entrypoint.sh          # Container initialization script
```

## Monitoring

### View Logs

```bash
# All logs
docker-compose logs -f

# Specific service
docker-compose logs -f app
docker-compose logs -f redis

# Laravel logs
docker-compose exec app tail -f storage/logs/laravel.log
```

### Check Container Status

```bash
docker-compose ps
docker stats
```

## Deployment

Để deploy lên production server:

1. Copy tất cả files lên server
2. Cập nhật `.env` với thông tin production
3. Chạy: `docker-compose up -d --build`
4. Setup reverse proxy (Nginx/Caddy) nếu cần
5. Setup SSL certificate

## Support

Nếu gặp vấn đề, kiểm tra:
- Docker logs: `docker-compose logs`
- Laravel logs: `storage/logs/laravel.log`
- Nginx logs: Inside container at `/var/log/nginx/`

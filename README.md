# NOVA v0.1

**Önce düşünceyi keşfet, sonra insanı.**

Bu depo NOVA'nın ilk çalışan ürün hipotezini içerir: kullanıcılar içerik sahibini ilk anda görmez; bir düşünce ilgilerini çekerse `Kim söyledi?` ile kişiyi keşfeder. Tam anonim paylaşımlarda kimlik açılmaz.

## İçerik

- `backend/` — FastAPI + SQLAlchemy API
- `mobile/` — Flutter kaynak kodu
- `docs/` — milestone notları
- `docker-compose.yml` — PostgreSQL + API için geliştirme ortamı

## 1) Backend'i Windows'ta hızlı çalıştırma

PowerShell:

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e ".[dev]"
uvicorn app.main:app --reload
```

Varsayılan olarak SQLite kullanılır ve `backend/nova.db` oluşur. API:

- http://127.0.0.1:8000
- Swagger: http://127.0.0.1:8000/docs

Test:

```powershell
pytest
```

## 2) PostgreSQL ile çalıştırma

Bilgisayarda Docker Desktop varsa proje kökünde:

```powershell
docker compose up --build
```

Bu durumda API `http://127.0.0.1:8000` adresindedir.

## 3) Flutter projesini hazırlama

Bu pakette NOVA'nın `lib/` kaynakları ve `pubspec.yaml` hazırdır. Bilgisayarda Flutter kuruluysa:

```powershell
cd mobile
flutter create . --platforms=android,ios
flutter pub get
flutter run
```

> `flutter create .` komutu platform dosyalarını üretir; mevcut `lib/` kaynaklarını kullanmaya devam eder.

Android Emulator için:

```powershell
flutter run --dart-define=NOVA_API_URL=http://10.0.2.2:8000/api/v1
```

Windows/web üzerinde yerel testte varsayılan adres `http://127.0.0.1:8000/api/v1` olur. Fiziksel Android telefonda bilgisayarının yerel IP adresini ver:

```powershell
flutter run --dart-define=NOVA_API_URL=http://192.168.x.x:8000/api/v1
```

ve backend'i ağdan erişilebilir başlat:

```powershell
uvicorn app.main:app --reload --host 0.0.0.0
```

## Güvenlik notu

v0.1 parola hash'leme için standart kütüphanedeki PBKDF2-HMAC-SHA256 kullanır. Canlı yayına geçmeden önce Argon2 (`pwdlib[argon2]`), refresh-token rotasyonu, rate limit, e-posta doğrulaması, CORS kısıtları ve gizli anahtar yönetimi eklenmelidir.

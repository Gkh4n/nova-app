# NOVA v0.1 — Milestone 1

Bu milestone yalnızca NOVA'nın temel ürün hipotezini çalıştırır:

1. Kullanıcı kayıt olur.
2. Kullanıcı giriş yapar.
3. Düşünce paylaşır.
4. Feed, yazar kimliğini göstermeden düşünceyi sunar.
5. Başka bir kullanıcı `Kim söyledi?` düğmesine basar.
6. Backend reveal olayını ölçer ve yazar profil bilgisini döndürür.
7. Tam anonim içerikte kimlik hiçbir kullanıcıya açılmaz.

## Tamamlanmış API'ler

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `GET /api/v1/feed`
- `POST /api/v1/posts`
- `POST /api/v1/posts/{post_id}/reveal`
- `GET /health`

## Sonraki milestone

- Reaksiyonlar
- Yorumlar
- Günün sorusunun backend modeli
- Profil ekranı
- Takip sistemi
- Token'ın cihazda güvenli saklanması

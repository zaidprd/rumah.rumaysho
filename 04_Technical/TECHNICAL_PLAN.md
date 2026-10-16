# Rencana Teknis Android

## Rekomendasi awal (belum final)
Godot 4 2D; export Android App Bundle (AAB), offline-first; asset pipeline ringan untuk laptop terbatas. Evaluasi performa perangkat Android low-end.

## Sistem
- Scene manager: rumah, dapur, kamar, halaman.
- Interaction manager: tap, drag/drop, object state machine.
- Activity engine: objective, trigger, feedback, real-world handoff.
- Time manager: simulated story clock dan actual device time dipisah.
- Prayer schedule: parental location input, configurable calculation, safe pause, offline support.
- Parent area: PIN/parental gate, timer, akses pembelian, konten yang telah dipelajari.
- Persistence: local save, no unnecessary child personal data.
- Content registry: referensi dalil dan status review.
- Premium entitlement: Google Play Billing, validasi pembelian dan restore purchase, patuhi kebijakan Play terbaru.

## Google Play
- Akun Play Console, paket AAB signed, testing track, store listing, privacy policy, Data safety, target audience/families requirements, age rating, purchase disclosures.
- Verifikasi kebijakan terbaru sebelum publikasi; jangan menganggap daftar ini lengkap.
- Hindari SDK iklan dan analitik invasif pada anak.

## Kriteria penerimaan prototype
- Android dapat dimainkan offline tanpa karakter.
- Dapur: 5+ benda interaktif dengan keadaan dan konsekuensi.
- Satu aktivitas edukasi selesai dan ajakan praktik nyata muncul.
- Bisa jeda/resume, tidak kehilangan progress.
- Audio tanpa musik, tanpa iklan, tanpa pembelian di area anak.

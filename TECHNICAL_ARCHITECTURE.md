# Arsitektur Teknis

## Stack

Godot 4 Standard + GDScript, Compatibility renderer, landscape 1280×720 dengan stretch `canvas_items`. Offline-first dan data-minimal. Prototype tidak memakai plugin, jaringan, karakter, billing, atau telemetry.

```text
Presentation (scene, UI, accessibility)
  └─ Activity Runtime (objective, hint, completion)
      ├─ Interaction (tap, drag, snap, state)
      ├─ Content Registry (source/review/version)
      ├─ Session/Prayer Pause
      └─ Persistence (lokal)
Platform: Android lifecycle + Play Billing adapter (fase lanjut)
```

Prototype memakai satu controller untuk iterasi cepat. Setelah playtest, pisahkan `DraggableObject`, `StatefulFixture`, `ActivityController`, `SaveService`, dan `ParentSettings` tanpa mengubah perilaku.

## Struktur

```text
scenes/kitchen/   scene prototype
scripts/kitchen/  controller/state
tests/            smoke test headless
01_Product…06_*   dokumen awal
*.md root         dokumen kerja lengkap
tools/            Godot lokal; bukan distribusi
```

Model produksi: `ActivityDefinition` berisi id, versi, usia, tujuan, objective, real-world prompt, referensi, dan status review. `SaveData` berisi schema version, room/activity state, settings, dan entitlement cache. Migrasi harus idempotent/atomic dan pulih ke default jika rusak. Jangan simpan data pribadi anak.

## Waktu dan lifecycle

`StoryClock` hanya untuk suasana game. `PrayerScheduler` memakai zona/lokasi/metode pilihan orang tua atau jadwal manual; tidak menebak waktu pasti. Saat event: tunggu safe point, autosave, tampilkan jeda tenang, hentikan engagement. Uji zona waktu, DST, reboot, suspend/resume, dan lintas tengah malam.

## Android, billing, keamanan

Gunakan Android build template yang cocok dengan Godot, package id final, keystore terpisah, dan secret CI—jangan commit credential. Billing dibungkus `EntitlementProvider`; fake untuk test dan Play Billing untuk release. Query/restore hanya di parent area, cache entitlement untuk offline, dan verifikasi kebijakan/SDK saat implementasi.

- Parent gate untuk setting eksternal, pembelian, tautan, restore.
- Tidak ada permission Android tak perlu.
- Validator build menolak content non-`APPROVED` untuk rilis.
- QA: parser/headless, state, save migration, touch, low-end, interruption, dan playtest anak didampingi.


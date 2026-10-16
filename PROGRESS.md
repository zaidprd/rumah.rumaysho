# Progress Log

## 2026-10-16 — Dapur Umma v0.1

### Pembaruan visual — Dapur Umma Flat v0.2

- Dapur dibangun ulang sebagai ruang 2D flat minimalis: lemari, wastafel, keran, jendela, kulkas, dan meja makan.
- Menggunakan warna pastel rendah saturasi, kontras teks memadai, tanpa kedipan, tanpa gerakan cepat, tanpa musik, dan tanpa aset pihak ketiga aktif.
- Aktivitas tetap: ambil alat makan, cuci buah, tutup keran, dan tata meja.
- Aset uji sementara dari folder lain telah dihapus karena tidak lagi digunakan.
- Parser dan smoke test Godot lulus kembali.

### Selesai

- Audit project pack; dokumen awal dibaca dan dipertahankan.
- Verifikasi Godot Standard `4.7.2.stable` lokal.
- Project Godot runnable dengan scene Dapur Umma.
- Lemari, drag piring/gelas/apel, keran, proses cuci, snap target meja, kondisi selesai, jeda, dan local save.
- Tanpa karakter, musik, iklan, jaringan, billing, atau engagement adiktif.
- PRD, GDD, kurikulum, arsitektur, roadmap, dan smoke test.
- Parser/editor, smoke test, dan runtime headless lulus dengan exit code 0.
- Memperbaiki prioritas hit-test agar benda di dalam lemari dapat diambil.
- Menambahkan cangkir dan mangga sebagai aset uji non-karakter; keduanya dilacak di `ASSET_NOTICE.md` dan tidak boleh masuk rilis sebelum hak pakai dikonfirmasi.

### Keputusan

- Godot 4.7.2 Standard, GDScript, Compatibility renderer.
- Viewport 1280×720; mouse dan touch satu alur.
- Visual bentuk sementara agar art direction belum terkunci.
- Selesai hanya bila buah bersih, meja tersusun, keran mati.
- Semua rujukan agama masih `DRAFT`, bukan pengesahan.
- Karakter ditunda sampai review fikih.

### Berikutnya

1. Playtest Android dengan anak didampingi.
2. Perbaiki affordance, target, pacing, petunjuk.
3. Refactor menjadi komponen reusable.
4. Review KIT-01/02/03 oleh reviewer kompeten.
5. Android debug export, parent timer, prayer pause manual.

### Batasan

- Belum ada Android SDK/export template atau uji fisik.
- Belum ada narasi/audio/aset final.
- Parent area, jadwal shalat, dan billing sengaja belum dibuat.


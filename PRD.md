# Product Requirements Document — Rumah Rumaysho

## Ringkasan

Rumah Rumaysho adalah game 2D landscape, offline-first, untuk anak 3–8 tahun dan pendampingnya. Produk memadukan sandbox rumah interaktif dengan aktivitas singkat yang mengajarkan keterampilan hidup, pengetahuan dasar, dan adab. Landasan agama harus melewati review ahli sebelum rilis.

Prototype pertama adalah **Dapur Umma tanpa karakter** untuk membuktikan kualitas sentuh/drag, state benda, satu siklus belajar, penyimpanan lokal, dan jeda alami.

## Tujuan dan ukuran keberhasilan

- Anak menyelesaikan aktivitas tanpa teks panjang atau bantuan terus-menerus.
- Anak dapat mempraktikkan mencuci buah, menghemat air, atau menata meja.
- Sesi selesai alami dalam 5–10 menit tanpa streak, ranking, loot box, iklan, atau hadiah acak.
- Prototype stabil pada 16:9 dengan mouse/touch dan tanpa jaringan.

Target uji: 80% anak selesai dengan maksimal dua bantuan; 70% mengulang satu langkah nyata; crash-free session 99% pada perangkat uji; skor rasa aman orang tua minimal 4/5.

## Pengguna

- Anak 3–5: ikon besar, manipulasi langsung, satu tujuan per langkah.
- Anak 6–8: eksplorasi bebas dan sebab-akibat singkat.
- Orang tua: durasi, jeda shalat, konten, pembelian, dan laporan materi.
- Reviewer: sumber, redaksi, ilustrasi, dan status publikasi.

## Ruang lingkup MVP

- Hub rumah: dapur, kamar tidur, ruang belajar, kamar mandi, dan halaman bertahap.
- Sandbox dan aktivitas terpandu; local save tanpa akun anak.
- Parent gate, timer sesi, dan pengingat shalat manual/offline.
- Paket gratis berguna; premium hanya di area orang tua.
- Bahasa Indonesia; tanpa musik, iklan, chat, atau analitik invasif.

Di luar MVP: multiplayer, sosial, cloud save, AI percakapan, karakter final, dan transaksi sebelum parent area siap.

## Persyaratan

| ID | Persyaratan | Pri | Penerimaan |
|---|---|---:|---|
| FR-01 | Tap dan drag | P0 | Target sentuh minimal 64 px pada 1280×720 |
| FR-02 | State tersimpan | P0 | Buka ulang mempertahankan progres aman |
| FR-03 | Tujuan, akibat, praktik nyata | P0 | Ketiganya ada pada tiap aktivitas |
| FR-04 | Jeda aman | P0 | State tersimpan; tanpa penalti |
| FR-05 | Timer/prayer pause | P1 | Parent-only; fallback manual |
| FR-06 | Registry review | P1 | Konten belum disetujui tidak dirilis |
| FR-07 | Entitlement | P2 | Purchase/restore parent-only |

Target Android 9+, Compatibility renderer, startup <5 detik, sasaran 60 FPS/minimum 30 FPS di perangkat rendah. Gameplay inti offline, teks siap dilokalkan, audio opsional, warna bukan pembeda tunggal. Tidak mengumpulkan nama, foto, lokasi presisi, audio, atau identifier anak.

Gratis memuat rumah dasar dan aktivitas inti. Premium berupa paket sekali beli; harga/SKU divalidasi kemudian. Rilis perlu AAB, privacy policy, Data Safety, target audience, rating usia, testing track, audit kebijakan Play terbaru, QA, uji anak didampingi, review editorial/fikih/konten, dan privacy review.


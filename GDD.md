# Game Design Document — Rumah Rumaysho

## Pilar

1. **Bermain berpindah ke dunia nyata:** akhir aktivitas mengajak praktik bersama keluarga.
2. **Rumah hidup:** benda bereaksi masuk akal, bisa dipindah, dan menyimpan keadaan.
3. **Tenang:** tanpa musik, FOMO, streak, ranking kesalehan, hadiah acak, atau notifikasi pemancing.
4. **Aman:** ibadah tidak dinilai; kisah nabi/sahabat tanpa sosok atau dialog rekaan.

Rumah menjadi hub dapur, kamar, kamar mandi, ruang belajar, dan halaman. Anak memilih sandbox atau guided activity. Jam cerita terpisah dari waktu shalat perangkat. Pengingat shalat berhenti di safe point sesuai pengaturan orang tua.

Alur: **undangan → eksplorasi → tindakan → konsekuensi → refleksi → praktik nyata → selesai**. Tidak ada game over; kesalahan memberi respons netral dan hint bertahap.

## Vertical slice Dapur Umma

Tujuan: buka lemari, ambil piring/gelas, cuci apel, matikan keran, lalu tata meja.

| Objek | State | Interaksi | Feedback |
|---|---|---|---|
| Lemari | tutup/buka | tap | isi tersembunyi/terlihat |
| Piring | lemari/bebas/meja | drag | snap ke target |
| Gelas | lemari/bebas/meja | drag | snap ke target |
| Apel | kotor/dicuci/bersih/meja | drag + tahan di air | noda hilang |
| Keran | mati/menyala | tap | aliran; wajib dimatikan |
| Meja | kosong/sebagian/siap | drop | target dan pesan akhir |

Selesai bila apel bersih, semua benda tepat, dan keran mati. Pesan akhir mengajak menata meja nyata.

Tap untuk sakelar; drag untuk benda. Target minimal 64 px, benda tidak keluar layar, snap longgar. Instruksi satu kalimat di bawah. `Esc`/Jeda menyimpan state. Visual prototype berupa bentuk tanpa karakter. Fase audio hanya narasi/efek nonmusikal yang direview, dengan subtitle dan mute.

Ruangan lanjut: kamar (rapikan kasur/adab tidur), kamar mandi (bersih/hemat air; wudhu direview khusus), belajar (hijaiyah/berhitung/kisah tanpa sosok), halaman (menanam/sebab-akibat/syukur). Aktivitas 3–7 menit, tidak bergantung audio, timer cepat, atau warna; berhenti tidak merusak progres.


# MASTER_PRD.md — Aplikasi Dashboard & Kasir IRKOP CELL

**Versi:** 1.1
**Platform:** Web App + APK Android
**Prinsip utama:** 100% free tier, dibangun & dideploy lewat GitHub

> **Changelog v1.1:** `ARCHITECTURE.md` digabung ke dokumen ini (§2.1–§2.3) sehingga `ARCHITECTURE.md` tidak lagi dipakai terpisah. Ditambahkan alur **Tutup Kasir** yang sebelumnya belum ada (§5.3), beserta perubahan skema database terkait (`cashier_sessions`, `cashier_bank_accounts`) di `schema.sql`.

---

## 1. Ringkasan

Aplikasi dashboard/kasir untuk manajemen konter IRKOP CELL — mencakup transaksi harian, kasir, laporan, stok barang, service HP, kasbon, data pelanggan, pengeluaran, gaji karyawan, dan pengaturan sistem (termasuk NotifHook untuk deteksi notifikasi pembayaran).

Skala awal: **single outlet**, tapi struktur database disiapkan agar bisa upgrade ke multi-cabang tanpa migrasi besar.

Role user pada MVP: **Admin** dan **Kasir**.

---

## 2. Tech Stack & Arsitektur

| Layer | Pilihan | Catatan |
|---|---|---|
| Frontend Web | Next.js (App Router) | |
| Styling/UI | Tailwind CSS + shadcn/ui | |
| Mobile (APK) | Capacitor | wrap Next.js/PWA jadi APK Android |
| Native plugin | Custom Kotlin plugin (via Capacitor) | untuk NotifHook (`NotificationListenerService`) |
| Backend API | Cloudflare Workers | extend gateway existing `api.irkop.workers.dev` |
| Database | Cloudflare D1 | nama db: `irkop-konter` (1 project = 1 database) |
| File storage | Cloudflare R2 | foto produk, file Excel import/export |
| Hosting web | Cloudflare Pages | |
| Auth | NextAuth.js / JWT custom | role-based (Admin, Kasir) |
| CI/CD | GitHub Actions | build web + build APK sebagai job terpisah |
| Reference docs | Context7 | dipakai saat development, bukan dependency runtime |

> Semua layanan di atas punya free tier yang cukup untuk skala 1 outlet. Perlu dimonitor kalau nanti masuk fase multi-cabang.

### 2.1 Struktur Folder (Monorepo)

```
irkop-konter/
├── apps/
│   ├── web/                       # Next.js — sumber untuk web & di-wrap APK
│   │   ├── app/
│   │   │   ├── (auth)/login/
│   │   │   ├── dashboard/
│   │   │   ├── transaksi/
│   │   │   │   ├── baru/
│   │   │   │   └── laporan-harian/
│   │   │   ├── kasir/
│   │   │   ├── laporan/
│   │   │   ├── barang/
│   │   │   ├── service-hp/
│   │   │   ├── kasbon/
│   │   │   ├── pelanggan/
│   │   │   ├── pengeluaran/
│   │   │   ├── karyawan/
│   │   │   └── pengaturan/
│   │   │       ├── theme/
│   │   │       ├── notifhook/
│   │   │       ├── user-permission/
│   │   │       ├── master-akun/
│   │   │       └── log-audit/
│   │   ├── components/            # shadcn/ui + komponen custom
│   │   ├── lib/                   # api client, auth helper, utils
│   │   └── public/
│   │
│   ├── api/                       # Cloudflare Worker — extend gateway api.irkop.workers.dev
│   │   ├── src/
│   │   │   ├── routes/
│   │   │   │   ├── auth.ts
│   │   │   │   ├── transaksi.ts
│   │   │   │   ├── kasir.ts
│   │   │   │   ├── laporan.ts
│   │   │   │   ├── barang.ts
│   │   │   │   ├── service-hp.ts
│   │   │   │   ├── kasbon.ts
│   │   │   │   ├── pelanggan.ts
│   │   │   │   ├── pengeluaran.ts
│   │   │   │   ├── karyawan.ts
│   │   │   │   ├── pengaturan.ts
│   │   │   │   └── notifhook.ts
│   │   │   ├── middleware/
│   │   │   │   ├── auth.ts        # verifikasi JWT
│   │   │   │   └── rbac.ts        # cek role_permissions
│   │   │   └── index.ts           # router utama, mount semua routes
│   │   └── wrangler.toml          # binding D1: irkop-konter, binding R2
│   │
│   └── mobile/                    # Capacitor wrapper (build APK)
│       ├── android/
│       │   └── app/src/main/java/.../NotifListenerPlugin.kt
│       └── capacitor.config.ts
│
├── db/
│   ├── schema.sql
│   └── migrations/
│
├── .github/workflows/
│   ├── deploy-web.yml             # push main → build & deploy Pages + Workers
│   └── build-apk.yml              # trigger manual/tag → build APK, upload ke Releases
│
└── README.md
```

### 2.2 Daftar API Endpoint (REST, prefix `/v1`)

| Modul | Endpoint | Method |
|---|---|---|
| Auth | `/auth/login`, `/auth/logout`, `/auth/me` | POST/POST/GET |
| Dashboard | `/dashboard/summary` | GET |
| Transaksi | `/transaksi`, `/transaksi/:id` | GET, POST, PUT, DELETE |
| Transaksi | `/transaksi/hari-ini` | GET |
| Kasir | `/kasir/sesi` (status sesi hari ini) | GET |
| Kasir | `/kasir/sesi/buka` | POST |
| Kasir | `/kasir/sesi/tutup` | POST |
| Kasir | `/kasir/sesi/:id/rekonsiliasi` (preview saldo sistem vs input sebelum submit close) | GET |
| Kasir | `/kasir/bank`, `/kasir/mutasi` | POST/DELETE, POST |
| Laporan | `/laporan?range=harian\|bulanan\|tahunan&from=&to=` | GET |
| Barang | `/barang`, `/barang/:id`, `/barang/kategori` | CRUD |
| Barang | `/barang/import`, `/barang/export` | POST, GET |
| Service HP | `/service`, `/service/:id`, `/service/laporan` | CRUD, GET |
| KASBON | `/kasbon/profil`, `/kasbon/:id/bayar` | CRUD, POST |
| Pelanggan | `/pelanggan`, `/pelanggan/:id/gabung` | CRUD, POST |
| Pengeluaran | `/pengeluaran`, `/pengeluaran/:id` | CRUD |
| Karyawan | `/karyawan`, `/karyawan/:id/gaji` | CRUD, CRUD |
| Pengaturan | `/pengaturan/theme`, `/pengaturan/user`, `/pengaturan/role`, `/pengaturan/master-akun`, `/pengaturan/audit-log` | CRUD masing-masing |
| NotifHook | `/notifhook/sumber`, `/notifhook/webhook` (dipanggil APK), `/notifhook/status` | CRUD, POST, GET |

Semua endpoint (kecuali `/auth/login` dan `/notifhook/webhook` yang pakai secret key khusus dari APK) wajib lewat middleware `auth.ts` + `rbac.ts`, dicek terhadap tabel `role_permissions`.

### 2.3 Catatan Implementasi (dari ARCHITECTURE.md)

- `wrangler.toml` perlu binding D1 (`irkop-konter`) dan R2 (untuk file Excel & foto produk).
- `role_permissions` diseed dari matrix di §4, tapi tetap CRUD-able dari `/pengaturan/role`.
- `.github/workflows/deploy-web.yml` hanya jalan setelah push ke `main` — konsisten dengan aturan "push GitHub dulu baru deploy".
- `build-apk.yml` disarankan trigger manual/tag rilis (bukan tiap push) supaya nggak generate APK tiap commit kecil.

---

## 3. Alur Deploy

1. Push kode ke GitHub (branch `main`/`dev`) — **wajib**, tidak ada deploy tanpa push dulu.
2. GitHub Actions trigger build:
   - Job 1: build & deploy web ke Cloudflare Pages + Workers.
   - Job 2: build APK (Capacitor) → upload sebagai release artifact di GitHub Releases.
3. Connect project ke Cloudflare (Pages + Workers + D1 binding) setelah repo siap.

---

## 4. Role & Permission (MVP)

| Modul | Admin | Kasir |
|---|:---:|:---:|
| Dashboard | ✅ | ✅ (terbatas: tanpa Laba jika diinginkan) |
| Transaksi | ✅ | ✅ |
| Kasir | ✅ | ✅ |
| Laporan | ✅ | ✅ (harian saja, direkomendasikan) |
| Daftar Barang | ✅ | 👁️ Lihat saja |
| Service HP | ✅ | ✅ |
| KASBON | ✅ | ✅ |
| Pelanggan | ✅ | ✅ |
| Pengeluaran | ✅ | 👁️ Lihat saja |
| Gaji Karyawan | ✅ | ❌ |
| Pengaturan | ✅ | ❌ |

*Matrix di atas rekomendasi awal — bisa disesuaikan lagi karena disebut "custom" di modul Pengaturan → User & Permission, artinya matrix ini harus tetap bisa diedit dari UI, bukan hardcode.*

---

## 5. Modul-Modul

### 5.1 Dashboard
Ringkasan (card/widget): **Omset, Transaksi, Laba, Saldo Kasir, Transaksi Hari Ini**. Read-only, agregasi dari data transaksi & kasir hari berjalan.

### 5.2 Transaksi

**5.2.1 Transaksi Baru** — form:

| Field | Tipe | Catatan |
|---|---|---|
| Produk | Select (dari Daftar Barang) | |
| Kategori | Select | Voucher, Transfer, Tarik Tunai, dll — sesuai Daftar Kategori |
| Harga Produk | Number | |
| Modal Produk | Number | |
| Laba | Number (auto-calc) | Harga − Modal |
| Metode Pembayaran | Select | Tunai, Transfer, dll |
| Pelanggan | Select/Search | dari modul Pelanggan |
| Tanggal Transaksi | Date | default hari ini |
| Input Custom | Dynamic field | field tambahan, dikonfigurasi lewat Pengaturan (bisa tambah/hapus) |

Kategori **Service** pada form ini merujuk ke modul Service HP (form & halaman terpisah, tapi entry point-nya tetap muncul di sini sesuai kategori).

**5.2.2 Laporan Transaksi Hari Ini** — list transaksi hari berjalan, real-time.

### 5.3 Kasir

Sesi kasir berlaku **1x per hari per outlet** (bukan per shift/karyawan). Sesi punya 3 status: **Belum Dibuka → Sedang Berjalan → Sudah Ditutup**.

**5.3.1 Buka Sesi Kasir (Opening)**
- Kasir/Admin input **Saldo Awal** (tunai/laci) dan mengonfirmasi saldo awal tiap akun bank di Master Akun (default: melanjutkan `closing_balance` dari sesi hari sebelumnya — bukan input manual dari nol, kecuali sesi pertama kali).
- Sistem otomatis kirim **notifikasi ke Admin** saat tombol Opening diklik (mencatat jam masuk karyawan untuk pemantauan telat/tidak).
- Setelah dibuka, transaksi & mutasi kasir hari itu tercatat terhadap sesi ini.

**5.3.2 Tutup Kasir (Closing)** — *baru ditambahkan di v1.1*
- Tombol **"Tutup Kasir"** hanya muncul kalau sesi hari ini berstatus Sedang Berjalan.
- Sistem menghitung **saldo sistem** per akun (bank/e-wallet + tunai/laci) = saldo awal + seluruh mutasi masuk/keluar hari itu (dari transaksi, kasbon, pengeluaran, mutasi manual).
- Kasir input **saldo aktual/real** per akun (hasil cek fisik/aplikasi) → sistem hitung **selisih** = aktual − sistem, otomatis per akun.
- Kalau ada selisih (≠ 0) di akun manapun, **wajib isi catatan alasan** sebelum bisa submit Tutup Kasir.
- Setelah submit: sesi berubah status jadi Sudah Ditutup, `closing_balance` & saldo akhir tiap akun tersimpan permanen, dan otomatis jadi **saldo awal (opening) sesi besok** — bukan diinput ulang manual.
- Riwayat closing (termasuk selisih & catatan) muncul di Log/Audit dan bisa dilihat Admin di Laporan.
- Status sesi (Belum Dibuka / Sedang Berjalan / Sudah Ditutup) ditampilkan jelas di halaman Kasir dan sebagai widget di Dashboard.

### 5.4 Laporan
- Filter: Harian, Bulanan, Tahunan, dan filter tanggal custom (range picker).
- Sumber data: gabungan Transaksi, Service HP, Pengeluaran.
- *Rekomendasi:* tambahkan tombol export (Excel/PDF) untuk konsistensi dengan modul Daftar Barang.

### 5.5 Daftar Barang
- CRUD daftar barang & kategori.
- Import & export via file Excel (mapping kolom: nama, kategori, harga jual, harga modal, stok — disesuaikan saat implementasi).

### 5.6 Service HP
Form (referensi dari Transaksi Baru):

| Field | Tipe |
|---|---|
| Nama Device / Tipe | Text |
| Pelanggan | Select/Search |
| No HP | Text |
| Deskripsi Kerusakan | Textarea |
| Biaya Servis | Number |
| Harga Modal | Number |
| Laba | Number (auto-calc) |
| Tanggal Masuk | Date |
| Tanggal Keluar | Date |
| Garansi | Text/Number (durasi) |
| Teknisi | Select (dari data karyawan) |
| Catatan | Textarea |
| Status | Select — *rekomendasi default:* Diterima, Proses, Menunggu Sparepart, Selesai, Diambil, Batal |

Plus halaman **Laporan Service HP** (list + filter status/tanggal).

### 5.7 KASBON
- Grouping otomatis: transaksi kasbon dengan nama yang sama dikelompokkan jadi satu profil.
- Input pembayaran (cicilan/parsial) — tidak wajib langsung lunas.
- Histori pembayaran tersimpan per nama/profil.

### 5.8 Pelanggan
- Tambah kontak dengan multi-select (pilih beberapa sekaligus, misal dari import).
- Grouping/merge pelanggan dengan nama sama — contoh: 1 pelanggan dengan 2 nomor rekening berbeda bisa digabung jadi satu profil.

### 5.9 Pengeluaran
CRUD pengeluaran: kategori, jumlah, tanggal, catatan.

### 5.10 Gaji Karyawan
CRUD data karyawan + histori penggajian per periode.

### 5.11 Pengaturan
- **Dashboard/Website/Theme** — kustomisasi tampilan.
- **NotifHook**:
  - Indikator status backend: 🟢 aktif / 🔴 mati.
  - Endpoint Worker (URL webhook penerima notifikasi).
  - Tabel Sumber Notifikasi — kolom: **Sumber, Type, Value, Status** (contoh: `Dana` | `package_name` | `com.dana` | Aktif).
  - Form Tambah Sumber: Source name, Matcher type, Value (mis. package_name), lalu tombol Tambah.
- **User & Permission** — CRUD user + edit role matrix (lihat §4).
- **Master Akun** — daftar akun pembayaran terhubung (Dana, OrderKuota, SeaBank, dll — custom, bisa tambah sendiri).
- **Log/Audit** — riwayat aktivitas user (create/update/delete penting).

---

## 6. NotifHook — Detail Teknis

1. Plugin native Kotlin custom di dalam project Capacitor, implement `NotificationListenerService` Android.
2. Plugin memfilter notifikasi masuk berdasarkan `package_name` yang terdaftar di tabel Master Sumber Notifikasi.
3. Notifikasi yang cocok diteruskan (webhook) ke endpoint Worker.
4. Worker mem-parsing isi notifikasi lalu (rekomendasi) mencocokkan otomatis ke Transaksi/KASBON yang menunggu konfirmasi.
5. Status 🟢/🔴 di Pengaturan dihitung dari last-ping/heartbeat APK ke Worker.

Alur ringkas (dari ARCHITECTURE.md):

```
[APK: NotifListenerPlugin.kt]
   → tangkap notifikasi (filter by package_name di notif_sources)
   → POST ke /notifhook/webhook (pakai device secret key)
[Worker: notifhook.ts]
   → simpan ke notif_logs (status: pending)
   → coba cocokkan otomatis ke transaksi/kasbon pending
   → update status → matched / ignored
[Web: Pengaturan → NotifHook]
   → tampilkan status 🟢/🔴 berdasarkan last-ping dari APK
```

**Catatan:** fitur ini butuh izin akses notifikasi (`BIND_NOTIFICATION_LISTENER_SERVICE`) yang harus diaktifkan manual oleh user di Android Settings pertama kali install — perlu ada halaman onboarding/panduan di APK.

---

## 7. Ringkasan Entitas Data (high-level)

`users`, `outlets` (disiapkan, belum dipakai di UI MVP), `products`, `product_categories`, `transactions`, `transaction_custom_fields`, `cashier_sessions`, `cashier_bank_accounts`, `cashier_mutations`, `customers`, `customer_accounts`, `service_orders`, `kasbon_profiles`, `kasbon_entries`, `kasbon_payments`, `expenses`, `employees`, `salaries`, `notif_sources`, `notif_logs`, `master_accounts`, `role_permissions`, `audit_logs`.

Semua tabel transaksional menyertakan `outlet_id` sejak awal (default 1 nilai) agar siap multi-cabang tanpa migrasi skema besar.

---

## 8. Non-Functional Requirements

- **Responsive**, mobile-first (kasir kemungkinan besar pakai HP/tablet di APK).
- **Security**: auth token (JWT), role-based access control server-side (bukan cuma sembunyikan UI), HTTPS (default Cloudflare).
- **CRUD penuh** di semua modul data master (Barang, Kategori, Pelanggan, Karyawan, Master Akun, Sumber Notifikasi, User).
- Tetap dalam batas free tier Cloudflare (D1, Workers, Pages, R2) — perlu dicek limit request/storage saat volume transaksi naik.

---

## 9. Roadmap Fase (rekomendasi)

| Fase | Scope |
|---|---|
| 1 | Auth, Dashboard, Transaksi (+ kategori dasar), Kasir (buka & tutup), Laporan Harian — Web only |
| 2 | Daftar Barang (+ import/export Excel), Pelanggan, KASBON |
| 3 | Service HP, Pengeluaran, Gaji Karyawan, Laporan Bulanan/Tahunan |
| 4 | Pengaturan lengkap (Theme, User & Permission, Master Akun, Log/Audit) |
| 5 | Build APK (Capacitor) + NotifHook (native plugin) |
| 6 | Aktivasi multi-cabang (skema sudah siap sejak Fase 1) |

---

## 10. Open Questions (untuk dikonfirmasi tim, di luar MVP)

- Perlu approve otomatis notif hasil NotifHook sebelum masuk transaksi full otomatis, Tapi Bisa di edit pakai drowpdown ketika ada return / Cancel.
- Format export laporan: Excel.
- Status default Service HP di §5.6 — konfirmasi apakah 6 status ini final atau perlu ditambah/dikurangi.

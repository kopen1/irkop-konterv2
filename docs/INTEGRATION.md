# IRKOP Frontend — API/D1 Integration

Frontend memakai Central API yang sudah ada, bukan membuat Worker/database baru.

- Central API: `https://api.irkop.workers.dev`
- Namespace Konter: `/v1/konter/*`
- Development memakai same-origin `/api/irkop/*` yang di-rewrite ke Central API.

## Auth

Login: `POST /v1/konter/auth/login`.

JWT disimpan pada `irkop.jwt`; request terautentikasi mengirim `Authorization: Bearer <JWT>`. `GET /auth/me` memvalidasi sesi. HTTP 401 menghapus sesi.

## Live D1 CRUD

- Barang → `/barang`
- Pelanggan → `/pelanggan`
- Pengeluaran → `/pengeluaran`
- Karyawan → `/karyawan`
- Master Akun → `/pengaturan/master-akun`
- Service HP → `/service`
- KASBON → `/kasbon/profil`

`ResourceCrud` menyediakan GET, POST, PUT, DELETE.

Transaksi memakai POST `/transaksi`; dashboard memakai `/dashboard/summary` + `/transaksi/hari-ini`; kasir memakai `/kasir/sesi`, `/kasir/sesi/buka`, `/kasir/sesi/tutup`, dan rekonsiliasi.

## Environment

```text
NEXT_PUBLIC_API_BASE_URL=
NEXT_PUBLIC_API_PREFIX=/api/irkop/v1/konter
```

Jika API Contract resmi memakai bentuk response berbeda, mapping cukup disesuaikan di `lib/api.ts` tanpa membuat endpoint baru.

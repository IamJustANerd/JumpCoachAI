# 🚀 Jump Coach AI: Pelatih Lompatan Berbasis Kecerdasan Buatan

Jump Coach AI adalah aplikasi seluler inovatif yang dirancang untuk **menilai kualitas dan performa lompatan pengguna** menggunakan model Kecerdasan Buatan (AI) canggih. Aplikasi ini bertujuan menyediakan pelatihan lompatan yang dapat diakses **kapan saja dan di mana saja**, hanya dengan melakukan input kondisi fisik awal dan kalibrasi sederhana.

---

## ✨ Fitur Utama Aplikasi

Aplikasi Jump Coach AI dilengkapi dengan serangkaian fitur untuk mendukung latihan dan pemantauan performa pengguna:

* **Sistem Otentikasi Pengguna:** Fitur **Login** yang aman untuk menyimpan data pribadi dan riwayat pelatihan Anda, memastikan kontinuitas data meskipun berganti perangkat.
* **Profil yang Dapat Disesuaikan:** Pengguna dapat mengatur dan memperbarui data **Profil** fisik mereka sesuai kebutuhan.
* **Riwayat Lompatan (History):** Menyimpan catatan lengkap dari sesi lompatan sebelumnya untuk membantu pengguna memantau kemajuan dari waktu ke waktu.
* **Pencapaian Lompatan Tertinggi:** Menampilkan **Lompatan Tertinggi** yang pernah dicapai sebagai motivasi untuk terus meningkatkan performa.
* **Model Penilaian AI:** Inti dari aplikasi. Model AI canggih menilai **skor lompatan** Anda secara *real-time* dan memberikan **kritik serta saran** yang spesifik dan terpersonalisasi.

---

## 🛠️ Detail Teknis dan Arsitektur

### Teknologi yang Digunakan

| Komponen | Deskripsi |
| :--- | :--- |
| **Aplikasi Mobile** | **Flutter** (Multi-platform Development Framework) |
| **Pengembangan** | **VSCode** dan **Android Studio** |
| **Model AI** | **Random Forest** |
| **Dukungan LLM** | **AI Studio** (untuk Large Language Model, jika digunakan dalam fitur saran) |

### Detail Model AI

* **Tipe Model:** **Random Forest**
* **Dataset:** Sekitar **700** sampel data lompatan.
* **Lokasi File Model:** Model AI dapat ditemukan dalam repositori ini dengan nama file: `model2.onnx`.

---

## 📝 Panduan Penggunaan dan Instalasi

Untuk menjalankan aplikasi ini, Anda perlu memastikan koneksi antara perangkat seluler dan server *backend* (laptop/komputer) berfungsi dengan baik dalam jaringan yang sama.

### 1. Persiapan Server Lokal

1.  Arahkan terminal ke folder `lib`.
2.  Jalankan *script* server Python:
    ```bash
    python server.py
    ```
3.  **Konfigurasi IP:** Di dalam file `server.py`, pastikan Anda **mengganti alamat IPv4** dengan alamat IP lokal dari laptop atau komputer yang menjalankan server. **Pastikan perangkat seluler dan server berada dalam jaringan Wi-Fi yang sama.**

### 2. Instalasi Aplikasi Mobile

Ada dua cara untuk menginstal aplikasi:

* **Instalasi Langsung (APK):**
    * Unduh file aplikasi bernama **`app-release.apk`** dari repositori (atau sumber yang disediakan) dan instal secara manual di perangkat Android Anda.
* **Running Melalui Android Studio (Debugging):**
    * Hubungkan perangkat seluler Anda ke laptop/komputer menggunakan kabel data.
    * Buka Android Studio atau terminal di *root* proyek.
    * Jalankan perintah berikut, ganti `<nama_handphone>` dengan nama perangkat Anda yang terdeteksi:
        ```bash
        flutter run -d <nama_handphone>
        ```

Setelah aplikasi terbuka di perangkat seluler, Anda dapat mencabut kabel data dan mulai menggunakan aplikasi.

---

## 🖼️ Tampilan Aplikasi (Snapshot)

Berikut adalah beberapa tampilan dari aplikasi Jump Coach AI:

| Halaman Login | Halaman Utama/Profile |
| :---: | :---: |
| ! (readme_img/1.png) | ! (readme_img/2.png) |
| *[Tambahkan gambar lain sesuai kebutuhan]* | |

---

## 📹 Video Demo

Video demonstrasi fungsionalitas aplikasi dapat dilihat melalui tautan berikut:
\[gdrive...]
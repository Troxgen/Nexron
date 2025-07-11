
# Nexron PC Controller

**Nexron**, Flutter tabanlı mobil uygulama ile bir Windows bilgisayara uzaktan komut göndermenizi sağlayan bir projedir. Amaç, mobil cihaz üzerinden PC üzerinde çeşitli işlemleri uzaktan başlatmak ve kontrol etmektir.

## ✨ Özellikler

- Flutter mobil uygulaması ile sesli veya yazılı komut gönderimi
- C# Windows Forms uygulaması üzerinden komutları alma ve yürütme
- PC üzerinde uygulama açma, dosya çalıştırma, sistem kontrolü vb. destek
- Ağ üzerinden haberleşme (aynı Wi-Fi ağı veya lokal IP ile)

## 🧩 Proje Yapısı

```bash
Nexron/
│
├── Flutter/       # Flutter mobil uygulaması (komut gönderici)
│
└── C#/        # C# Windows Forms uygulaması (komut alıcı)
````

## 🚀 Kurulum

### 1. Mobil Uygulama (Flutter)

```bash
cd flutter_client
flutter pub get
flutter run
```

### 2. Windows Uygulaması (C#)

* `csharp_server/NexronController.sln` dosyasını Visual Studio ile aç.
* Gerekli NuGet paketlerini yükle.
* Derleyip çalıştır.

> ⚠️ Bilgisayar ve mobil cihaz aynı ağda olmalı. C# uygulaması IP ve port üzerinden veri alır.

## 📡 Kullanım

1. Mobil uygulamayı başlat, komut gir (örneğin `chrome aç`).
2. Komut, ağ üzerinden C# uygulamasına gönderilir.
3. C# uygulaması komutu alır, işler ve sonucu geri döner (isteğe bağlı).

## 🔐 Güvenlik

* Şu an temel ağ haberleşmesi kullanılmaktadır.
* Gelecek sürümlerde TCP/IP üzerinden şifreleme ve token bazlı erişim planlanmaktadır.

## 🛠️ Geliştirme Notları

* Mobil uygulama `speech_to_text`, `flutter_tts`, `http` gibi paketleri kullanır.
* Komutlar JSON olarak iletilir.
* C# tarafı `HttpListener` veya `TcpListener` ile yapılandırılmış olabilir (yönteme göre ayarlanmalı).

## 📃 Lisans

MIT License. Katkılar memnuniyetle karşılanır.

---

## ✍️ Açıklama Metni (Proje Tanımı)

**Nexron**, mobil cihazdan bilgisayara komut vermeyi mümkün kılan bir uzaktan kontrol sistemidir. Flutter ile geliştirilen mobil arayüz üzerinden gönderilen komutlar, C# ile geliştirilen Windows Forms uygulaması tarafından işlenir ve bilgisayarda belirli işlemleri yerine getirir.

Bu sistem, örneğin telefon üzerinden "Spotify başlat", "Bilgisayarı kapat", "Ses aç", gibi komutlarla bilgisayarı yönetmenizi sağlar. Özellikle Smart Home, ofis otomasyonu veya kişisel üretkenlik senaryoları için uygundur.

---


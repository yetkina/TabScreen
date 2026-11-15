# TabScreen

[English (EN)](#english-en) · [Türkçe (TR)](#türkçe-tr)

---

## English (EN)

**Use your Android tablet as a wireless second screen for your Mac. Free, open source, no ads.**

TabScreen is a small macOS app that sets up and controls [Sunshine](https://github.com/LizardByte/Sunshine) (the streaming server) and a virtual display ([Crisp](https://crispmac.app/) or BetterDisplay), so the free [Moonlight](https://moonlight-stream.org/) app on your tablet can show a real extra screen.

### Features

- Start, stop and restart Sunshine, and choose whether it starts at login
- Detects what is installed and installs the rest with Homebrew (or shows alternatives)
- Picks the virtual display and writes the Sunshine config for you
- Illustrated how-to and troubleshooting guide, in English and Turkish
- Menu bar item

### Requirements

- macOS 13 or later, Apple Silicon
- An Android tablet or phone with [Moonlight](https://play.google.com/store/apps/details?id=com.limelight)
- Mac and tablet on the same network (5 GHz Wi-Fi recommended)
- [Homebrew](https://brew.sh) (recommended, for automatic installs)

### Install

Download the latest `.dmg` from the [Releases](../../releases) page and drag **TabScreen** to Applications.

### Quick start

1. Open TabScreen → **Setup → Auto setup**.
2. Create a virtual display in Crisp (1920×1200 fits many tablets, HiDPI off).
3. Allow Sunshine under *Privacy & Security → Screen Recording* and *Accessibility*.
4. On the tablet, open Moonlight, add your Mac's IP, enter the PIN in the Sunshine web UI, then tap **Desktop**.

The in-app **How-to & Help** page covers common connection problems.

### Build from source

```sh
./build.sh      # builds build/TabScreen.app
./release.sh    # signs, notarizes and packages a .dmg (needs a Developer ID certificate)
```

### Why not the Mac App Store?

The App Store requires a sandbox. TabScreen installs software with Homebrew, manages a launchd service and writes Sunshine's config, which a sandboxed app cannot do.

### Author

Yetkin AYDIN · [www.yaydin.com](https://www.yaydin.com) · info@yaydin.com

### License

MIT, see [LICENSE](LICENSE). Sunshine, Moonlight and Crisp are separate projects with their own licenses; TabScreen does not bundle them.

[↑ Back to top](#tabscreen)

---

## Türkçe (TR)

**Android tabletinizi Mac'iniz için kablosuz ikinci ekrana dönüştürün. Ücretsiz, açık kaynak, reklamsız.**

TabScreen, [Sunshine](https://github.com/LizardByte/Sunshine) (yayın sunucusu) ve sanal ekranı ([Crisp](https://crispmac.app/) veya BetterDisplay) kurup yöneten küçük bir macOS uygulamasıdır. Böylece tabletinizdeki ücretsiz [Moonlight](https://moonlight-stream.org/) uygulaması gerçek bir ek ekran gösterebilir.

### Özellikler

- Sunshine'ı başlatma, durdurma, yeniden başlatma ve girişte otomatik başlatmayı seçme
- Neyin kurulu olduğunu algılar, eksikleri Homebrew ile kurar (veya alternatifleri gösterir)
- Sanal ekranı seçer ve Sunshine ayarını sizin için yazar
- İngilizce ve Türkçe görsel rehber ve sorun giderme
- Menü çubuğu simgesi

### Gereksinimler

- macOS 13 veya üzeri, Apple Silicon
- [Moonlight](https://play.google.com/store/apps/details?id=com.limelight) yüklü bir Android tablet veya telefon
- Mac ve tablet aynı ağda (5 GHz Wi-Fi önerilir)
- [Homebrew](https://brew.sh) (otomatik kurulum için önerilir)

### Kurulum

[Releases](../../releases) sayfasından en son `.dmg` dosyasını indirin ve **TabScreen**'i Uygulamalar klasörüne sürükleyin.

### Hızlı başlangıç

1. TabScreen'i açın → **Kurulum → Otomatik kurulum**.
2. Crisp'te bir sanal ekran oluşturun (1920×1200 birçok tablete uyar, HiDPI kapalı).
3. *Gizlilik ve Güvenlik → Ekran Kaydı* ve *Erişilebilirlik* bölümlerinde Sunshine'a izin verin.
4. Tablette Moonlight'ı açın, Mac'inizin IP'sini ekleyin, PIN'i Sunshine web arayüzüne girin ve **Desktop**'a dokunun.

Uygulamanın içindeki **Nasıl Yapılır & Yardım** sayfası sık görülen bağlantı sorunlarını anlatır.

### Kaynaktan derleme

```sh
./build.sh      # build/TabScreen.app üretir
./release.sh    # imzalar, noter onayına gönderir ve .dmg paketler (Developer ID sertifikası gerekir)
```

### Neden Mac App Store'da yok?

App Store sandbox zorunlu kılar. TabScreen Homebrew ile yazılım kurar, bir launchd servisini yönetir ve Sunshine ayarını yazar; bunlar sandbox içindeki bir uygulamayla yapılamaz.

### Geliştirici

Yetkin AYDIN · [www.yaydin.com](https://www.yaydin.com) · info@yaydin.com

### Lisans

MIT, bkz. [LICENSE](LICENSE). Sunshine, Moonlight ve Crisp kendi lisanslarına sahip ayrı projelerdir; TabScreen bunları içermez.

[↑ Başa dön](#tabscreen)

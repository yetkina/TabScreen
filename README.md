# TabScreen

**Use your Android tablet as a wireless second screen for your Mac. Free, open source, no ads.**
**Android tabletinizi Mac'iniz için kablosuz ikinci ekrana dönüştürün. Ücretsiz, açık kaynak, reklamsız.**

TabScreen is a small macOS app that sets up and controls [Sunshine](https://github.com/LizardByte/Sunshine) (streaming server) and a virtual display ([Crisp](https://crispmac.app/) or BetterDisplay), so the free [Moonlight](https://moonlight-stream.org/) app on your tablet can show a real extra screen.

## Features / Özellikler

- Start, stop and restart Sunshine; choose whether it starts at login
  Sunshine'ı başlat, durdur, yeniden başlat; girişte otomatik başlatmayı seç
- Detects what is installed and installs the rest with Homebrew (or shows alternatives)
  Neyin kurulu olduğunu algılar, eksikleri Homebrew ile kurar (veya alternatifleri gösterir)
- Picks the virtual display and writes the Sunshine config for you
  Sanal ekranı seçer ve Sunshine ayarını sizin için yazar
- Illustrated how-to and troubleshooting guide in English and Turkish
  İngilizce ve Türkçe görsel rehber ve sorun giderme
- Menu bar item

## Requirements / Gereksinimler

- macOS 13 or later, Apple Silicon
- An Android tablet (or phone) with [Moonlight](https://play.google.com/store/apps/details?id=com.limelight)
- Mac and tablet on the same network (5 GHz Wi-Fi recommended)
- [Homebrew](https://brew.sh) (recommended, for automatic installs)

## Install / Kurulum

Download the latest `.dmg` from the [Releases](../../releases) page and drag **TabScreen** to Applications.

## Build from source / Kaynaktan derleme

```sh
./build.sh      # builds build/TabScreen.app
./release.sh    # signs, notarizes and packages a .dmg (needs a Developer ID certificate)
```

## Quick start / Hızlı başlangıç

1. Open TabScreen → **Setup → Auto setup**.
2. Create a virtual display in Crisp (1920×1200 fits many tablets, HiDPI off).
3. Allow Sunshine under *Privacy & Security → Screen Recording* and *Accessibility*.
4. On the tablet, open Moonlight, add your Mac's IP, enter the PIN in the Sunshine web UI, tap **Desktop**.

The in-app **How-to & Help** page covers common connection problems.

## Why not the Mac App Store? / Neden App Store'da yok?

The App Store requires a sandbox. TabScreen has to install software with Homebrew, manage a launchd service and write Sunshine's config, which a sandboxed app cannot do.
App Store sandbox zorunludur; TabScreen Homebrew ile kurulum yapar, launchd servisini yönetir ve Sunshine ayarını yazar, bunlar sandbox içinde mümkün değildir.

## Author / Geliştirici

Yetkin AYDIN · [www.yaydin.com](https://www.yaydin.com) · info@yaydin.com

## License / Lisans

MIT, see [LICENSE](LICENSE). Sunshine, Moonlight and Crisp are separate projects with their own licenses; TabScreen does not bundle them.

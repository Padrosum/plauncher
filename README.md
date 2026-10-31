# PadrosHorRust

**Padros**, [Horizon](https://github.com/horizon-rust/horizon) projesinin **launcher-only**,
kişisel ve **çevrimdışı** çatalıdır. Oyunu Microsoft hesabına bağlamadan, oyun dosyalarını
**senin kendi Minecraft kurulumundan** alarak başlatır.

Depoda oyun motoru yok: `horizon-client`, `horizon-server`, dünyalar, renderer ve araçlar
çıkarıldı. Kalanlar launcher ve launcher'ın derlenmek için ihtiyaç duyduğu 11 crate.

> Bu depo **hiçbir Mojang/Microsoft oyun dosyası içermez**. Çalışmak için bilgisayarında
> satın alınmış ve kurulmuş bir Minecraft: Java Edition olması gerekir.

## Neler var

- **Padros arayüzü** — Horizon markası, sponsor, Discord ve partner (Sculk) bölümleri kaldırıldı.
  Kenar çubuğunda tek bir **Website** bağlantısı var: <https://alihankarakus.com>.
- **Game files** — Settings içinden Minecraft klasörünü, client jar'ını ve server jar'ını elle
  seçebilirsin. Her jar, sürümün kendi `research-lock.json` pinine (SHA-1) karşı doğrulanır.
- **Set up automatically** — tek düğme: bilgisayarındaki Minecraft kurulumunu bulur, klasörü
  kaydeder, gerekirse Java çalışma zamanını indirir ve seçili sürümü Play için hazırlar.
- **Çevrimdışı oyun** — launcher'ın geliştirici seçeneği `dev_offline` ile Microsoft oturumu
  olmadan oynanır (`settings.json` → `"dev_offline": true`).
- **Kendini güncellemez** — çatalın kendi ikilisini upstream sürümüyle değiştirmemesi için
  launcher'ın self-update'i kalıcı olarak kapatıldı. Yeni Horizon sürümleri de otomatik kurulmaz.
- **Masaüstü menüsü** — ilk açılışta `Padros` adıyla uygulama menüsüne girer.
- **8 dil** — İngilizce, Fransızca, Almanca, İspanyolca, Rusça, Ukraynaca, Lehçe ve Çince.
  (Türkçe arayüz çevirisi upstream'de yok; arayüz metinleri İngilizce kalır.)

## Gereksinimler

**Çalıştırmak için (Linux):**

| Gereksinim | Not |
|---|---|
| Minecraft: Java Edition | Oyun dosyaları için; launcher bunları indirmez |
| Vulkan sürücüsü | `mesa-vulkan-drivers`, `vulkan-radeon` veya `nvidia-utils` |
| X11 veya Wayland | GPUI pencereleme |
| `libxkbcommon-x11` | Klavye girdisi |
| ALSA (`libasound2`) | Ses |
| `libudev` | Oyun kolu desteği |

Dağıtıma göre:

```sh
# Debian / Ubuntu
sudo apt install libxkbcommon-x11-0 libvulkan1 libasound2t64 libudev1

# Fedora
sudo dnf install libxkbcommon-x11 vulkan-loader alsa-lib systemd-libs

# Arch
sudo pacman -S libxkbcommon-x11 vulkan-icd-loader alsa-lib systemd-libs
```

**Kaynaktan derlemek için ayrıca:**

- Rust **1.85+** (<https://rustup.rs>)
- `cargo`, `rustc`
- İlk derlemede internet (crates.io'dan bağımlılıklar indirilir)

## Kurulum

Depoyu klonla ve betiği çalıştır:

```sh
git clone https://github.com/Padrosum/plauncher.git
cd PadrosHorRust
./install.sh
```

Betik sırayla:

1. Rust sürümünü denetler,
2. `launcher/` içinde `cargo build --release` çalıştırır,
3. ikiliyi `~/.local/bin/horizon-launcher` olarak kurar,
4. `padros` adında bir kısayol oluşturur,
5. çalışma zamanı kitaplıklarını (`ldd`, Vulkan) kontrol eder,
6. `PATH` uyarısı verir.

Root olarak çalıştırırsan varsayılan önek `/usr/local`, normal kullanıcıda `~/.local` olur.

### Kurulum seçenekleri

| Seçenek | Açıklama |
|---|---|
| `--prefix DİZİN` | Kurulum kökü (`DİZİN/bin/horizon-launcher`) |
| `--binary DOSYA` | Derlemek yerine hazır `horizon-launcher` ikilisini kur |
| `--no-build` | Derleme yapma; depodaki hazır ikiliyi kullan |
| `--jobs N`, `-j N` | `cargo` için paralel iş sayısı |
| `--uninstall` | Kurulu ikiliyi ve `padros` kısayolunu kaldır |
| `--purge` | `--uninstall` ile: launcher verisini de sil (oyun kayıtları hariç) |
| `--dry-run` | Hiçbir şey yazmadan yapılacakları göster |
| `-h`, `--help` | Yardım |

Örnekler:

```sh
./install.sh --prefix /usr/local              # sistem geneli (sudo)
./install.sh --binary ~/İndirilenler/horizon-launcher
./install.sh --no-build -j 4
./install.sh --uninstall                      # ayarlar korunur
./install.sh --uninstall --purge               # launcher verisi de silinir
sudo DESTDIR=/tmp/pkg ./install.sh --prefix /usr   # paketleme
```

### Elle derleme

```sh
cd launcher
cargo build --release
# ikili: launcher/target/release/horizon-launcher
```

`launcher/` kök workspace'ten ayrıdır; bu yüzden derleme `cd launcher` içinde yapılır.

### Elle kurulum

```sh
install -Dm755 launcher/target/release/horizon-launcher ~/.local/bin/horizon-launcher
ln -sfn horizon-launcher ~/.local/bin/padros
```

Masaüstü girdisini launcher ilk açılışta kendisi ekler; istersen:

```sh
install -Dm644 packaging/linux/horizon-launcher.desktop \
  ~/.local/share/applications/horizon-launcher.desktop
```

## İlk çalıştırma

`padros` (veya `horizon-launcher`) komutunu çalıştır.

1. **Settings → Game files → Set up** düğmesine bas.
   Launcher Minecraft kurulumunu bulur ve seçili sürümü hazırlar.
2. Bulamazsa aynı bölümden elle seç:
   - **Minecraft folder** — örn. `~/.minecraft`
   - **Client jar** — `versions/<sürüm>/<sürüm>.jar` (SHA-1 pinine karşı doğrulanır; klasörü
     Minecraft klasörü yapar, `assets/` bulunması gerekir)
   - **Server jar** — `server-jars/<sürüm>.jar` olarak saklanır
3. **Home → Play**.

Hazırlık bir kez yapılır; sonraki açılışlar doğrudan Play'e gider.

### Microsoft hesabı ve `dev_offline`

Bu çatal Microsoft oturumu açmaz. Launcher'ın kendi geliştirici seçeneği çevrimdışı oynamayı
açar:

- **Settings → Developer options** → *Offline mode*, veya
- `~/.local/share/horizon-launcher/settings.json` içinde `"dev_offline": true`

Bu seçenek upstream'de zaten vardır; çatal onu **kendiliğinden açmaz**. Kurulum betiği de hiçbir
sahiplik/oturum kontrolünü atlatmaz.

> **Önemli:** Oyunu oynamak için Minecraft'a sahip olman gerekir. Bu proje bir kırma aracı
> değildir ve oyun dosyalarını dağıtmaz. Online-mode sunucular sunucu tarafında Microsoft
> doğrulaması yapar; bu launcher'da sökülebilecek bir şey değildir.

## Veri konumları

| Yol | İçerik |
|---|---|
| `~/.local/share/horizon-launcher/` | Launcher verisi (`HORIZON_LAUNCHER_HOME` ile değiştirilir) |
| `…/settings.json` | Ayarlar (`minecraft_dir`, `dev_offline`, dil, görünüm…) |
| `…/versions/<sürüm>/` | İndirilmiş/hazırlanmış Horizon sürümleri |
| `…/server-jars/<sürüm>.jar` | Elle seçilen server jar'ları |
| `~/.local/share/horizon/` | Oyunun kendi klasörü: kayıtlar, `logs/`, `crash-reports/` |
| `~/.local/share/applications/horizon-launcher.desktop` | Masaüstü menüsü girdisi |

`HORIZON_LAUNCHER_HOME` ortam değişkeni veri klasörünü taşır (test ve betikler için).

Oyun kayıtların `~/.local/share/horizon/` altındadır; `install.sh --uninstall --purge` bunlara
**dokunmaz**.

## Sorun giderme

**"This version is not prepared yet"**
Settings → Game files → **Set up** ile sürümü hazırla.

**Minecraft bulunamadı**
Minecraft klasörünü elle seç. Launcher `versions/<sürüm>/<sürüm>.jar` ve `assets/` arar.
Farklı bir launcher kullanıyorsan (Prism, ATLauncher…) jar'ı **Client jar** ile doğrudan seç.

**Oyun açılmıyor / siyah ekran**
Vulkan sürücünü denetle:

```sh
ldconfig -p | grep libvulkan
vulkaninfo --summary
```

Eksikse dağıtımının Vulkan paketini kur.

**`padros: command not found`**
`~/.local/bin` `PATH`'te değil:

```sh
export PATH="$HOME/.local/bin:$PATH"      # ~/.bashrc veya ~/.zshrc'ye ekle
```

**Eski Horizon arayüzü geri geldi**
Bu çatalda self-update kapalı. Yine olursa çalışan ikilinin bizim derlememiz olduğunu doğrula:

```sh
md5sum ~/.local/bin/horizon-launcher launcher/target/release/horizon-launcher
```

**Günlükler**
Settings → About → **Logs** (veya `~/.local/share/horizon/logs/latest.log`).

## Bu çatalda değişenler

- Oyun motoru ve araçları çıkarıldı; yalnızca launcher + gerekli 11 crate kaldı.
- Sponsor, Discord, Website (eski `playhorizon.dev`) ve Partner (Sculk) bölümleri kaldırıldı.
- Website bağlantısı <https://alihankarakus.com> adresine yönlendirildi.
- Horizon adı geçen kullanıcı arayüzü yerleri **Padros** yapıldı.
- Launcher'ın kendi kendini güncellemesi kapatıldı (`self_update_allowed() → false`).
- Yeni Horizon sürümlerinin otomatik kurulumu varsayılan olarak kapalı.
- **Game files** bölümü ve **Set up automatically** akışı eklendi.
- Upstream `links.json` artık ağdan çekilmiyor; bağlantılar derlemenin içinde.
- Lisans GPL-3.0-or-later oldu (aşağıya bak).

## Lisans

Bu çatal **GNU General Public License, sürüm 3 veya sonrası** (`GPL-3.0-or-later`) altında
dağıtılır. Tam metin: [`LICENSE`](LICENSE).

Özgün Horizon çalışması MIT lisanslıdır; telif ve izin metni [`LICENSE-MIT`](LICENSE-MIT)
dosyasında korunur. Nelerin değiştiği ve atıflar [`NOTICE`](NOTICE) ile
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) içinde listelenir. Üçüncü taraf yazı tipleri,
ikonlar ve mod yükleyici logoları kendi lisanslarını korur.

Minecraft, Mojang Synergies AB'nin ticari markasıdır. Oyun kodu ve varlıkları Mojang/Microsoft'a
aittir ve [Minecraft EULA](https://www.minecraft.net/en-us/eula) kapsamındadır. Bu depo hiçbir
Mojang dosyası içermez; yalnızca kullanıcının bilgisayarında zaten bulunan dosyaları okur.

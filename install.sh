#!/usr/bin/env bash
# PadrosHorRust kurulum betiği.
#
#   ./install.sh                 derler ve ~/.local/bin'e kurar
#   ./install.sh --prefix /usr/local
#   ./install.sh --binary ./horizon-launcher    (hazır ikili)
#   ./install.sh --uninstall
#
# Ayrıntılar: ./install.sh --help
set -Eeuo pipefail

readonly PROG="$(basename "$0")"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

PREFIX=""
BINARY=""
UNINSTALL=0
PURGE=0
DRY_RUN=0
NO_BUILD=0
JOBS=""

say()  { printf '\033[1m==>\033[0m %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
warn() { printf '\033[33muyarı:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31mhata:\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<EOF
PadrosHorRust kurulum betiği

Kullanım:
  $PROG [SEÇENEKLER]

Seçenekler:
  --prefix DİZİN     Kurulum kökü (varsayılan: root ise /usr/local, değilse ~/.local)
  --binary DOSYA     Derlemek yerine bu hazır horizon-launcher ikilisini kur
  --no-build         Derleme yapma; depodaki/yanındaki hazır ikiliyi kullan
  --jobs N, -j N     cargo derlemesinde paralel iş sayısı
  --uninstall        Kurulu ikiliyi ve "padros" kısayolunu kaldır
  --purge            --uninstall ile birlikte launcher verisini de sil
                     (ayarlar, indirilmiş Horizon sürümleri, sunucu jar'ları, loglar).
                     Oyun kayıtların (~/.local/share/horizon) SİLİNMEZ.
  --dry-run          Hiçbir şey yazmadan yapılacakları göster
  -h, --help         Bu yardımı göster

Örnekler:
  $PROG                                  # kaynaktan derle, ~/.local/bin'e kur
  $PROG --prefix /usr/local              # sistem geneli (sudo ile)
  $PROG --binary ~/İndirilenler/horizon-launcher
  $PROG --no-build -j 4
  $PROG --uninstall
  sudo DESTDIR=/tmp/pkg $PROG --prefix /usr   # paketleme için

Kurulumdan sonra:
  * "padros" komutu (ve horizon-launcher) PATH'te olmalı.
  * İlk açılışta launcher kendini masaüstü menüsüne ekler.
  * Settings → Game files → "Set up" ile oyun dosyalarını hazırla, sonra Play.

Gereksinimler (Linux): Rust 1.85+ (kaynaktan derleme için), Vulkan sürücüsü,
X11/Wayland, libxkbcommon-x11, ses için ALSA. Ayrıntılar README.md'de.
EOF
}

# --- argümanlar ---------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prefix)
            [[ $# -ge 2 ]] || die "--prefix bir dizin ister"
            PREFIX="$2"; shift 2 ;;
        --prefix=*)
            PREFIX="${1#*=}"; shift ;;
        --binary)
            [[ $# -ge 2 ]] || die "--binary bir dosya yolu ister"
            BINARY="$2"; shift 2 ;;
        --binary=*)
            BINARY="${1#*=}"; shift ;;
        --no-build)
            NO_BUILD=1; shift ;;
        --jobs|-j)
            [[ $# -ge 2 ]] || die "$1 bir sayı ister"
            JOBS="$2"; shift 2 ;;
        --jobs=*)
            JOBS="${1#*=}"; shift ;;
        --uninstall)
            UNINSTALL=1; shift ;;
        --purge)
            PURGE=1; shift ;;
        --dry-run)
            DRY_RUN=1; shift ;;
        -h|--help)
            usage; exit 0 ;;
        *)
            die "bilinmeyen seçenek: $1 (--help yaz)"
            ;;
    esac
done

[[ -z "$JOBS" || "$JOBS" =~ ^[1-9][0-9]*$ ]] || die "--jobs pozitif bir sayı olmalı"

if [[ -z "$PREFIX" ]]; then
    if [[ "$(id -u)" -eq 0 ]]; then PREFIX=/usr/local; else PREFIX="$HOME/.local"; fi
fi

# Sona eğik çizgi bırakma.
PREFIX="${PREFIX%/}"
[[ -n "$PREFIX" ]] || die "--prefix boş olamaz"

readonly BIN_NAME="horizon-launcher"
readonly LINK_NAME="padros"
readonly BIN_DIR="$PREFIX/bin"
readonly TARGET="$BIN_DIR/$BIN_NAME"
readonly LINK="$BIN_DIR/$LINK_NAME"
readonly STAGED_TARGET="${DESTDIR:-}$TARGET"
readonly STAGED_LINK="${DESTDIR:-}$LINK"

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '    + %s\n' "$*"
    else
        "$@"
    fi
}

# --- kaldırma -----------------------------------------------------------------------------------

if [[ "$UNINSTALL" -eq 1 ]]; then
    say "Kaldırılıyor: $TARGET"
    if [[ -e "$STAGED_TARGET" || -L "$STAGED_TARGET" ]]; then
        run rm -f "$STAGED_TARGET"
        note "ikili silindi"
    else
        warn "$STAGED_TARGET zaten yok"
    fi
    if [[ -e "$STAGED_LINK" || -L "$STAGED_LINK" ]]; then
        run rm -f "$STAGED_LINK"
        note "$LINK_NAME kısayolu silindi"
    fi

    if [[ "$PURGE" -eq 1 ]]; then
        say "Launcher verisi siliniyor: $DATA_HOME/horizon-launcher"
        note "ayarlar, indirilmiş sürümler, hazırlanmış kaynaklar, sunucu jar'ları"
        if [[ -d "$DATA_HOME/horizon-launcher" ]]; then
            run rm -rf "$DATA_HOME/horizon-launcher"
        else
            warn "$DATA_HOME/horizon-launcher yok"
        fi
        note "oyun kayıtların korundu: $DATA_HOME/horizon"
    else
        note "ayarların ve sürümlerin korundu: $DATA_HOME/horizon-launcher"
        note "hepsini silmek için: $PROG --uninstall --purge"
    fi
    say "Bitti."
    exit 0
fi

# --- ikiliyi bul veya derle ---------------------------------------------------------------------

build_from_source() {
    command -v cargo >/dev/null 2>&1 || die \
        "cargo bulunamadı. Rust kur: https://rustup.rs (veya dağıtımının rust paketi), sonra tekrar dene."
    command -v rustc >/dev/null 2>&1 || die "rustc bulunamadı; Rust kurulumun eksik."

    local version major minor
    version="$(rustc --version | awk '{print $2}')"
    major="${version%%.*}"
    minor="${version#*.}"; minor="${minor%%.*}"
    if (( major < 1 || (major == 1 && minor < 85) )); then
        die "Rust 1.85 veya daha yenisi gerekli (sende: $version). rustup update"
    fi

    [[ -f "$SCRIPT_DIR/launcher/Cargo.toml" ]] || die \
        "Kaynak depo bulunamadı ($SCRIPT_DIR/launcher). Kurulum betiğini depo kökünden çalıştır ya da --binary kullan."

    say "Derleniyor (ilk derleme birkaç dakika sürebilir, crates indirilir)"
    note "dizin: $SCRIPT_DIR/launcher"

    local -a cargo_cmd=(cargo build --release)
    [[ -f "$SCRIPT_DIR/launcher/Cargo.lock" ]] && cargo_cmd+=(--locked)
    [[ -n "$JOBS" ]] && cargo_cmd+=(--jobs "$JOBS")

    if [[ "$DRY_RUN" -eq 1 ]]; then
        printf '    + (cd %q && %s)\n' "$SCRIPT_DIR/launcher" "${cargo_cmd[*]}"
    else
        ( cd "$SCRIPT_DIR/launcher" && "${cargo_cmd[@]}" )
    fi

    BINARY="$SCRIPT_DIR/launcher/target/release/$BIN_NAME"
}

choose_binary() {
    if [[ -n "$BINARY" ]]; then
        say "Hazır ikili kullanılıyor: $BINARY"
        [[ -f "$BINARY" ]] || die "$BINARY bulunamadı"
        return
    fi

    local prebuilt="$SCRIPT_DIR/$BIN_NAME"
    if [[ "$NO_BUILD" -eq 1 ]]; then
        if [[ -f "$prebuilt" ]]; then
            BINARY="$prebuilt"
        elif [[ -f "$SCRIPT_DIR/launcher/target/release/$BIN_NAME" ]]; then
            BINARY="$SCRIPT_DIR/launcher/target/release/$BIN_NAME"
        else
            die "--no-build verildi ama hazır ikili yok ($prebuilt)"
        fi
        say "Hazır ikili kullanılıyor: $BINARY"
        return
    fi

    if [[ -f "$SCRIPT_DIR/launcher/Cargo.toml" ]]; then
        build_from_source
    elif [[ -f "$prebuilt" ]]; then
        say "Derleme kaynağı yok; yanındaki hazır ikili kullanılıyor: $prebuilt"
        BINARY="$prebuilt"
    else
        die "Ne kaynak ne hazır ikili bulundu. Depoyu klonla ya da --binary DOSYA ver."
    fi

    [[ -f "$BINARY" ]] || die "Derleme bitti ama $BINARY yok"
}

choose_binary

if [[ "$DRY_RUN" -eq 0 ]]; then
    [[ -x "$BINARY" ]] || die "$BINARY çalıştırılabilir değil"
    if ! file "$BINARY" 2>/dev/null | grep -q 'ELF'; then
        warn "$BINARY bir ELF (Linux) ikilisi gibi görünmüyor"
    fi
fi

# --- çalışma zamanı kitaplıkları ----------------------------------------------------------------

check_runtime() {
    local bin="$1" missing
    missing="$(ldd "$bin" 2>/dev/null | awk '/not found/ {print $1}' | sort -u || true)"
    if [[ -n "$missing" ]]; then
        warn "Eksik paylaşılan kitaplıklar:"
        while IFS= read -r lib; do note "$lib"; done <<<"$missing"
        note "Debian/Ubuntu: sudo apt install libxkbcommon-x11-0 libvulkan1 libasound2t64"
        note "Fedora:        sudo dnf install libxkbcommon-x11 vulkan-loader alsa-lib"
        note "Arch:          sudo pacman -S libxkbcommon-x11 vulkan-icd-loader alsa-lib"
    fi
    local vulkan
    vulkan="$(ldconfig -p 2>/dev/null | grep -m1 'libvulkan\.so\.1' || true)"
    if command -v ldconfig >/dev/null 2>&1 && [[ -z "$vulkan" ]]; then
        warn "Vulkan yükleyicisi (libvulkan.so.1) görünmüyor; oyun açılmayabilir."
        note "Bir Vulkan sürücüsü kur (ör. mesa-vulkan-drivers / vulkan-radeon / nvidia-utils)."
    fi
}

if [[ "$DRY_RUN" -eq 0 ]]; then
    check_runtime "$BINARY"
fi

# --- kur ----------------------------------------------------------------------------------------

say "Kuruluyor: $TARGET"
run install -d "$(dirname -- "$STAGED_TARGET")"
run install -m 0755 "$BINARY" "$STAGED_TARGET"

# "padros" kısayolu: göreli bağ, taşınınca da çalışır.
run ln -sfn "$BIN_NAME" "$STAGED_LINK"
note "$LINK_NAME -> $BIN_NAME"

if [[ "$DRY_RUN" -eq 0 && -z "${DESTDIR:-}" ]]; then
    if installed_version="$("$TARGET" --version 2>/dev/null)"; then
        note "sürüm: $installed_version"
    else
        warn "Kurulan ikili --version çalıştıramadı; yine de kuruldu."
    fi
fi

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        warn "$BIN_DIR PATH'te değil."
        note "Kabuğuna ekle: export PATH=\"$BIN_DIR:\$PATH\""
        note "Masaüstü menüsü yine çalışır (launcher ilk açılışta girdisini kendisi ekler)."
        ;;
esac

say "Bitti."
note "Başlat: padros        (veya: $TARGET)"
note "İlk açılış: Settings → Game files → Set up, sonra Home → Play."
note "Kaldır: $PROG --uninstall"

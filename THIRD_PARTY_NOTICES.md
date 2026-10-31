# Third-party notices

PadrosHorRust bundles the following third-party works. Each keeps its own license; the GNU GPL
that covers this fork does not replace them.

## Fonts

All bundled fonts are licensed under the SIL Open Font License 1.1:

- `crates/horizon-theme/fonts/BricolageGrotesque-*.ttf` is
  [Bricolage Grotesque](https://github.com/ateliertriay/bricolage) by Atelier Triay
  (`fonts/OFL-BricolageGrotesque.txt`).
- `crates/horizon-theme/fonts/Geist-*.ttf` and `GeistMono-*.ttf` are
  [Geist](https://github.com/vercel/geist-font) by Vercel (`fonts/OFL-Geist.txt`).
- `crates/horizon-theme/fonts/PixelifySans-*.ttf` is
  [Pixelify Sans](https://github.com/eifetx/Pixelify-Sans) by The Pixelify Sans Project Authors
  (`fonts/OFL-PixelifySans.txt`).

## Pixelarticons

`crates/horizon-theme/icons/pixel/*.svg` are icons from
[Pixelarticons](https://github.com/halfmage/pixelarticons) by Gerrit Halfmann, under the MIT
license (`crates/horizon-theme/icons/pixel/LICENSE-pixelarticons.txt`). `star.svg` is Horizon's own,
drawn on the same grid.

## Mod loader logos

The launcher shows the logo of the mod loader an instance plays with.

- `launcher/assets/logos/quilt.png` is the Quilt mini icon (`brand/128png/quilt_mini_icon_transparent.png`)
  from [QuiltMC/art](https://github.com/QuiltMC/art), by the Quilt Project, dedicated to the public
  domain under [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/).
- `launcher/assets/logos/neoforge.png` is NeoForged's icon (`art/neoforged_icon_16x16.png`) from
  [neoforged/.github](https://github.com/neoforged/.github/tree/main/art), © the NeoForged team,
  created by Ridanisaurus, under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). It is
  unmodified (the launcher scales it up by whole pixels).
- Fabric's and Forge's icons are not shipped: neither publishes a license for its logo. The launcher
  fetches them from their own sites when an instance needs them
  ([fabric-loader's icon](https://github.com/FabricMC/fabric-loader/blob/master/src/main/resources/assets/fabricloader/icon.png),
  [files.minecraftforge.net's](https://files.minecraftforge.net/)).

Each logo belongs to its project. Showing it says which loader an instance runs; it does not mean
the project endorses PadrosHorRust.

## Sign in with Microsoft

The launcher keeps Microsoft's sign-in panel for builds that are compiled with a client ID. Its
four-square symbol in `launcher/src/microsoft.rs` reproduces the squares, positions and colours of
Microsoft's official `ms-symbollockup_mssymbol_19.svg`, unmodified.
([Sign in with Microsoft branding](https://learn.microsoft.com/en-us/entra/identity-platform/howto-add-branding-in-apps)).
Microsoft and its logo are trademarks of the Microsoft group of companies; PadrosHorRust is not
endorsed by Microsoft.

## Rust dependencies

The crates this workspace builds against keep their own licenses (MIT, Apache-2.0, BSD and others).
`cargo metadata` or `cargo deny` lists them; nothing from those crates is relicensed by this fork.

---
title: "ESP32向けRust開発環境をNixで構築する"
emoji: "📻"
type: "tech"
topics: ["ESP32", "nix", "Rust"]
published: true
---

# 急いでいる方向け

次の手順で構築からビルドまで可能です(direnvを導入している必要があります)

```shell
nix flake new -t github:turtton/flake-templates#esp32-idf <appname>
```

作成されたフォルダ内でDirenvを有効にしてから(`direnv allow`)、以下を実行します

```shell
cargo generate --init esp-rs/esp-idf-template cargo # See: https://github.com/esp-rs/esp-idf-template
```

Build environmentに入り、ビルドを実行します。
```shell
$ nix develop
$ cargo build
```
> この環境では`cargo run`が利用できないため直接`flash`コマンドを使う必要があることに注意して下さい。詳細は[現状の問題点](#現状の問題点)にて記載しています

# 構築手順

## Rustプロジェクトの構築

`cargo-generate`を用いたプロジェクト作成方法が[公式テンプレート](https://github.com/esp-rs/esp-idf-template)より案内されていますのでそれを使用します。

```shell
nix run nixpkgs#cargo-generate generate esp-rs/esp-idf-template cargo
```

Project Nameに指定した名前のディレクトリが存在するため移動しておきます。

## Nixによるビルド可能な環境の構築

こちらでは自身が試行錯誤した時系列に沿って手順を案内します。

生成されたプロジェクトの`rust-toolchain.toml`を確認してみると、以下のようになっているはずです。

```toml:toolchain.toml
[toolchain]
channel = "esp"
```

もしrustupなどでcargo等が導入済みであっても、espターゲットはデフォルトでは存在しないためビルドすることができません。
ということで、まずはespターゲットのツールチェインを導入する必要があります。

通常の方法であれば、`espup`を用いて専用のツールチェインを導入し、環境変数を設定することでビルド可能な状態にしますが、こちらをNixの力を用いてやってみます。

`esp32 rust nix`とかで雑に検索すると[knarkzel/esp32](https://github.com/knarkzel/esp32)というRepositoryに出会うはずです。
こちらでは[espressif/idf-rust](https://hub.docker.com/r/espressif/idf-rust)というDockerImageから`.cargo`と`.rustup`ファイルを抽出して提供してくれています。とりあえず[Minimal example](https://github.com/knarkzel/esp32?tab=readme-ov-file#minimal-example)にある通りに`flake.nix`を作成してみましょう。
```nix:flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    esp32 = {
      url = "github:knarkzel/esp32";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    esp32,
  }: let
    pkgs = import nixpkgs {system = "x86_64-linux";};
    idf-rust = esp32.packages.x86_64-linux.esp32;
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [
        idf-rust
      ];

      shellHook = ''
        export PATH="${idf-rust}/.rustup/toolchains/esp/bin:$PATH"
        export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
      '';
    };
  };
}
```
これで`nix develop`を実行し、`cargo build`してみると、途中までは順調に進むものの`esp-idf-sys`のコンパイルが失敗してビルドできません。
エラー内容などで検索してみると[esp-idf-sys](https://github.com/esp-rs/esp-idf-sys)の[#184](https://github.com/esp-rs/esp-idf-sys/issues/184)に辿りつくと思います。

色々と議論されていますが、要はこいつがpython使ったりして外部依存を取ってくるので、FHSを満たしていないNixだと盛大にコケるってことがわかります。issueの最後の方にうまくいったflakeファイルが置かれていますので、今の環境と繋ぎ合わせて以下のようになります。
```nix:flake.nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    esp32 = {
      url = "github:knarkzel/esp32";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , esp32
    }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
      idf-rust = esp32.packages.x86_64-linux.esp32;
      fhs = pkgs.buildFHSUserEnv {
        name = "fhs-shell";
        targetPkgs = pkgs: with pkgs; [
          gcc

          pkg-config
          gnumake
          cmake
          ninja

          git
          wget

          idf-rust
          cargo-generate
          cargo-espflash

          espflash
          python3
          python3Packages.pip
          python3Packages.virtualenv
          ldproxy
        ];
        profile = ''
            export LIBCLANG_PATH="${idf-rust}/.rustup/toolchains/esp/xtensa-esp32-elf-clang/esp-17.0.1_20240419/esp-clang/lib"
            export PATH="${idf-rust}/.rustup/toolchains/esp/bin:$PATH"
            export PATH="${idf-rust}/.rustup/toolchains/esp/xtensa-esp-elf/esp-13.2.0_20230928/xtensa-esp-elf/bin:$PATH"
            export RUST_SRC_PATH="$(rustc --print sysroot)/lib/rustlib/src/rust/src"
        '';
      };
    in
    {
      devShells.${pkgs.system} = {
        default = fhs.env;
      };
    };
}
```
> ちなみに元のissueでは`~/.rustup`を消したとかなんとか言ってますが今回の環境と関係ないので無視してもらって構いません。

再度`nix develop`してbuild environmentに入り`cargo build`を実行してみましょう。今度はビルドが通り、無事に環境構築完了です...が、以下のような注意点があります。

# 現状の問題点

環境構築後、`nix develop`内で`cargo run --release`をしてみると、`/dev/ttyUSBn`へのアクセス権限が無いと言われます。
それならばと手動で`sudo espflash flash --monitor target/xtensa-esp32-espidf/release/<appname>`とやってみても、そもそもsudoの実行がbuild environmentでは禁止されているため書き込みができません。
> もしBuild environment内で`/dev/ttyUSBn`にアクセスする方法をご存じの方がいらしたらコメントなどで教えてください。

現状の回避策として、[direnv](https://github.com/direnv/direnv)を使用し、espflashをbuild envの外で使えるようにしてみます。
私のテンプレートから生成していない人は以下のようにコードを追記してください。

```diff nix:flake.nix
    devShells.${pkgs.system} = {
      default = fhs.env;
+     flash = pkgs.mkShell {
+       packages = [
+         pkgs.espflash
+       ];
+     };
    };
```

```shell:.envrc
if ! has nix_direnv_version || ! nix_direnv_version 3.0.5; then
    source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.5/direnvrc" "sha256-RuwIS+QKFj/T9M2TFXScjBsLR6V3A17YVoEW/Q6AZ1w="
fi
use flake .#flash
```

以下のようにコマンドをBuild environment**外で**実行します。
```shell
$ direnv allow
# 必要があれば`nix develop`してから`cargo build --release`してbuild environmentから出る
$ sudo espflash flash --monitor target/xtensa-esp32-espidf/release/<appname>
```
これでESP32への書き込みができるはずです。

# 終わりに

一部問題はあるものの、自身の環境を汚すことなく再現可能な開発環境を手に入れられたので一旦良しとして記事にしました。
そもそもESP32+Rust開発に関しては情報が少なく、ましてやNixを使う人は少数かと思いますが、DependencyHellや環境汚染の無いクリーンな環境に興味がある方は是非やってみてください。

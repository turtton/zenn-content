---
title: NixOSでゆるふわセキュアブート
emoji: 🔐
type: tech
topics: [nixos, secureboot]
published: true
---

# 概要

NixOSで[preloader-signed ](https://aur.archlinux.org/packages/preloader-signed)を利用できるようにしました
モジュールとして公開しています↓

https://github.com/turtton/dotnix/tree/main/nixosModules

# 経緯

NixOSでセキュアブートを実現するメジャーな方法として、[Lanzaboote](https://github.com/nix-community/lanzaboote)がありますが、このシステムでは自身の鍵で署名を行うため、マザーボードによっては個人の署名鍵の登録に対応していなかったりでうまく動作しないことがあります。実際に私の環境でもうまく動作しませんでした。といっても2年前の話なので今は良くなってるのかも...?

そもそもArchLinuxユーザー時代はこんな面倒な手順は踏んでおらず、ArchWikiの[「署名済みのブートローダーを使う」](https://wiki.archlinux.jp/index.php/Unified_Extensible_Firmware_Interface/%E3%82%BB%E3%82%AD%E3%83%A5%E3%82%A2%E3%83%96%E3%83%BC%E3%83%88#%E7%BD%B2%E5%90%8D%E6%B8%88%E3%81%BF%E3%81%AE%E3%83%96%E3%83%BC%E3%83%88%E3%83%AD%E3%83%BC%E3%83%80%E3%82%92%E4%BD%BF%E3%81%86)を参考にAURのpreloader-signedを利用していたのでなんでこんな面倒なことしてるんだという気持ちに。
元々セキュアブートを有効化する動機として、セキュリティうんぬんよりも単に普段デュアルブートしたWindowsで遊ぶゲームにひっついてる[~~マルウェア~~アンチチート](https://support-valorant.riotgames.com/hc/ja/articles/10088435639571-Windows-11%E3%81%A7VAN-9001-VAN-9003-VAN-9090%E3%81%AE%E3%82%A8%E3%83%A9%E3%83%BC%E8%A1%A8%E7%A4%BA%E3%81%8C%E5%87%BA%E3%81%9F%E5%A0%B4%E5%90%88%E3%81%AE%E3%83%88%E3%83%A9%E3%83%96%E3%83%AB%E3%82%B7%E3%83%A5%E3%83%BC%E3%83%86%E3%82%A3%E3%83%B3%E3%82%B0-VALORANT)のご機嫌を取るために毎回マザボの設定を切り替えるのが面倒なだけなので、NixOSでも同様にpreloader-signedを利用できるようにしたいと思い、パッケージとしてまとめたのがもう2年前の話。

当時はnixpkgs内で実装されていたEFIのバージョンチェッカーが複数のEFIバイナリが出てきた時に解析に失敗するバグがあり、それを直すところからやったりしてました。何気にこれが自分のnixpkgsに対する初コントリビューションだったり。

https://github.com/NixOS/nixpkgs/pull/326701

そんなことをしつつなんやかんやで自分用として2年ぐらい使ってたわけですが、最近NixOS利用者増えてるっぽいし、同じような考えの人が使えるようにとモジュール公開をすべく自身のリポジトリを整理しました。当時はArchWikiのセットアップ手順を愚直に実行するために`boot.loader.systemd-boot.extraInstallCommands`内でcpコマンドを使うべく`uutils-coreutils-noprefix`を無理矢理使ったりしてたけど、設定を見直して調整したりしました。

過去のはこれ
https://github.com/turtton/dotnix/blob/e8eff0f768b390ee230aeb559143bcc4858920b9/os/core/secureboot/preloader.nix#L26-L48

今はこうなった
https://github.com/turtton/dotnix/blob/3d380756fee9b0778873fe47ff9d22f1a92de622/nixosModules/preloader-signed.nix#L30-L45

ちゃんとモジュールとして使えるようになってます。switchする度に署名も自動で行なわれるのでArchLinux時代より便利。
ちなみに[README](https://github.com/turtton/dotnix/blob/main/nixosModules/README.md)に書いてる`boot.loader.systemd-boot.preloader-signed`の`efiSystemDrive`および`efiPartId`はboot領域のパーティションを指定するためのオプションなので、ご自身の環境に合わせて設定してください。


まあここ数ヶ月はもうWindowsの起動すらしてないんですけどね...

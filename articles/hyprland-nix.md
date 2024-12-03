---
title: "NixOSでPlasma5からHyprlandに移行した話"
emoji: "🔮"
type: "tech"
topics: ["nix", "nixos", "hyprland", "windowmanager", "wayland"]
published: true
---

# はじめに

今年3月に[NixOSに移行した時](https://zenn.dev/watagame/scraps/e64841d674d16e)からPlasma5を使用していたが、元の環境の不満ポイント[^1]が我慢ならなくなってきたのと、[unixporn](https://www.reddit.com/r/unixporn/?rdt=39704)とかを眺めててタイル型WMを使いたい欲が溢れて止まらなくなったので、移行したときの話を適当に書く

先に現状を出しておくとこんな感じ

https://x.com/turtton/status/1855981495934132466

- StatusBar: [Hyprpanel](https://hyprpanel.com)
- Widget: [Eww(予定)](https://github.com/elkowar/eww)
- Launcher: [Rofi(wayland)](https://github.com/lbonn/rofi)
- Terminal: [Alacritty](https://alacritty.org)
- Lockscreen: [Hyprlock](https://github.com/hyprwm/hyprlock/)
- ScreenShot: [Grimblast](https://github.com/hyprwm/contrib/tree/main/grimblast)
- FileManager: [Dolphin(qt5)](https://apps.kde.org/dolphin/)

### 参考にしたプロジェクト
- https://github.com/MrVivekRajan/Hypr-Dots/tree/Type-2?tab=readme-ov-file#spring-city
- https://github.com/NeshHari/XMonad

現状の問題とかはここでまとめている  
https://github.com/turtton/dotnix/issues/1


# StatusBar

Ewwによる完全自作→Waybar→Hyprpanelという流れで、Hyprpanelに落ち着いた

カスタマイズ性で言えばEwwが最強ではあるが、全部作るのはあまりにもつらいのと、システムトレイがうまく動かなくて断念した後、Waybarを試したがこちらもカスタマイズが思ったようにできなかったので、Hyprpanelで一旦ヨシとした

設定はこれ  
https://github.com/turtton/dotnix/blob/main/home-manager/wm/hyprland/hyprpanel.nix

現環境はメインモニターのIDが2としてHyprlandに認識されているので、他環境との互換性も考えて0と2の両方にステータスバーを配置している  
そこまでカスタマイズの自由度もないので言うことは無いが、日時の表示を良い感じに直しているのと、アップデート表示をいじって使用しているパッケージの深刻(レベル5以上)な脆弱性の数を表示するようにしている
https://github.com/turtton/dotnix/blob/d4a4b792bd2b576e156a5bd9155da07ecb29752e/home-manager/wm/hyprland/hyprpanel.nix#L74-L75

見た目はこんな感じ  
![](/images/hyprland-nix/vulcount.png)

本当は何のパッケージに何の脆弱性があるのか表示するウィジェットも作りたかったが、まあそれはまたの機会に(誰かEwwで作ってくれないかな)

# Launcher

Rofiがメジャーっぽかったのでこれにした

テーマはNeshHari/XMonadから拝借してる
https://github.com/turtton/dotnix/blob/main/home-manager/wm/hyprland/rofi/default.nix

ちなみにrofi-emojiはwayland環境では動作しなかったので代わりに[bemoji](https://github.com/marty-oehme/bemoji)を使用している。そのまま起動するだけでrofiを使ってくれて楽
https://github.com/turtton/dotnix/blob/d4a4b792bd2b576e156a5bd9155da07ecb29752e/home-manager/wm/hyprland/key-bindings.nix#L111

clipboardの履歴は[cliphist](https://github.com/sentriz/cliphist)を採用した。こちらもrofiに対応したワンライナーが書いてあるので楽に導入できる
https://github.com/turtton/dotnix/blob/d4a4b792bd2b576e156a5bd9155da07ecb29752e/home-manager/wm/hyprland/key-bindings.nix#L14
![](/images/hyprland-nix/cliphist.png)

# Terminal

本当はWeztermを使いたかったが、現行の最新版では全体がモザイクになってしまうバグがあったのでAlacrittyに落ち着いた。~~Nvidiaゆるせねえ~~
> どうやら最新コミットでは直ってるらしい。ビルドキャッシュをちゃんと保存できるようにして自前ビルドするか、次のリリースが出るかしたらまた試してみる

Plasmaで使ってたテーマに合わせようかとも思ったけど完全再現は無理そうなので無難に[tokyo-nightテーマ](https://github.com/zatchheems/tokyo-night-alacritty-theme/blob/main/tokyo-night.toml)をもとにhome-managerで設定した
https://github.com/turtton/dotnix/blob/main/home-manager/gui/term/alacritty.nix

# Lockscreen

display-managerとかのやつを使ってもよかったが、せっかくHyprlockなんてものがあるのと、参考元がめっちゃかっこいいロック画面を作ってたのでそれを使うことにした

![](/images/hyprland-nix/hyprlock.png)

曜日とかを日本語設定で出すと非常にダサくなったのでちょっと調整した。ちなみに下の電源ボタンとかは完全な飾りで機能しない。[これ](https://github.com/hyprwm/hyprlock/issues/366)が実装されたら機能させられるかもしれない。
実はアイコンがバグってるけど謎なので放置してる。
https://github.com/turtton/dotnix/blob/main/home-manager/wm/hyprland/hyprlock.nix

ちなみにこれはただのソフトウェアなのでログイン時はgreetdで自動ログインしてHyprlandが起動した後に呼び出してる。できればpamの設定をいじって入力したパスワード情報をログイン後のあれこれに使いたいが、あんまり情報がなさそうなので放置してる(そのせいでログイン後の1passwordの認証時にもう一度パスワードを入力させられててちょっと微妙。多分libsecretとかの関係？)

https://github.com/turtton/dotnix/blob/d4a4b792bd2b576e156a5bd9155da07ecb29752e/os/wm/hyprland.nix#L7
https://github.com/turtton/dotnix/blob/d4a4b792bd2b576e156a5bd9155da07ecb29752e/hosts/default.nix#L155-L169
https://github.com/turtton/dotnix/blob/d4a4b792bd2b576e156a5bd9155da07ecb29752e/home-manager/wm/hyprland/settings.nix#L14-L15

# ScreenShot

元々Plasma時代は[Spectacle](https://apps.kde.org/spectacle/)に大変お世話になっていたので、その時の体験を再現するべく色々やった結果、Grimblast+[Swappy](https://github.com/jtheoof/swappy)+[zenity](https://gitlab.gnome.org/GNOME/zenity)で良い感じにした
https://github.com/turtton/dotnix/blob/d4a4b792bd2b576e156a5bd9155da07ecb29752e/home-manager/wm/hyprland/key-bindings.nix#L102-L107
スクリーンショットを取る→Swappyで編集→zenityで保存or破棄、という流れ  
保存時にGwenviewを開くようにしても良いかもしれない

# FileManager

thunar→Nautilus→Dolphinの流れで落ち着いた。元々thunarは利用している人が多かったため試していたが、テーマの適用が上手くいかなかったためNautilusに移行したものの、元々Dolphinを使っていたので機能不足に感じてしまい、結局Dolphinに戻った。  
後述するテーマの設定がうまくいっていなかったらNautilusの可能性も全然あった。ちなみにNautilusはプラグイン系を適用するためにhome-managerではなくos側の設定として登録する必要があるので使いたい人は注意。自分も完全に動いたわけではないが、[こんなぐらいの設定](https://github.com/turtton/dotnix/blob/main/os/desktop/nautilus.nix)は最低限必要になる  
Dolphinの方は以下の通り
https://github.com/turtton/dotnix/blob/main/home-manager/gui/filemanager/dolphin/default.nix
自分で登録している[jetbrains-dolphin-qt5](https://github.com/turtton/dotnix/blob/main/overlay/jetbrains-dolphin.nix)(表示しているフォルダをJetbrains製品で開くやつ)が便利すぎて手放せなくなってる。そのうちnixpkgsにPR出すかも

# その他

## GTK/QTのテーマ適用

今回の以降で一番苦戦した要素。多くの非Nix環境のDotfilesでは色々な設定ファイルを直接配置して設定しているが、それをNixでやってもうまくいったりいかなかったりする。自身の環境でもテーマが適用されてもアイコンが適用されないとかが頻発した。

結論から言うとGTKはhome-managerの設定に則りつつ、QTも+αで設定ファイルを配置すると良い
https://github.com/turtton/dotnix/blob/main/home-manager/wm/hyprland/gtk.nix
https://github.com/turtton/dotnix/blob/main/home-manager/wm/hyprland/qt/default.nix
そして何よりも大事なのがHyprlandに**直接Qtの環境変数を設定すること**。これがないとHyprland経由で起動したrofi経由だとテーマが適用されない(ターミナルから起動するといける)みたいなことが起きる(これのせいでめちゃくちゃ苦労した)
https://github.com/turtton/dotnix/blob/d4a4b792bd2b576e156a5bd9155da07ecb29752e/home-manager/wm/hyprland/settings.nix#L8-L11
あとはQt5製品(NixだとlibsForQt5から始まるやつ)を使用すること。Qt6製品はKvantumが対応してないとか諸々の問題でテーマが適用されない(これもクソ罠なので注意)

## Chromium系ソフトウェアのIME入力対応

Chromium系ソフトウェアはデフォルトではネイティブWayland環境で実行されず、IMEがおかしくなる問題がある。前者は環境変数`NIXOS_OZONE_WL`を1にすることで多くのアプリケーションで解決できるが、後者のIME問題が残る。
といっても先駆者によって解決方法は示されている(ありがとうございます)
https://qiita.com/Meatwo310/items/947d26adbbddb9a7d098#chromiumelectron%E5%91%A8%E3%82%8A%E3%81%AE%E8%AA%BF%E6%95%B4
あとはこれらのオプションを各パッケージへ適用すればよい。が、パッケージによって最適な設定方法が異なる。

具体的にはパッケージの定義されたnixファイルの引数に`commandLineArgs`があるものと無いものがある。
あるものは以下のように設定する
```nix
pkg.override { commandLineArgs = [ "--enable-wayland-ime" "--enable-features=UseOzonePlatform" "--ozone-platform=wayland" ]; };
```
無いとかなりやっかいで、私の環境では`pkgs.symlinkJoin`を利用して実行ファイルと`.desktop`ファイルを上書きしている。といってもこの辺はパッケージによって色々と違いがあるので個別の説明は省略する。
上の例と合わせてoverlayの機能を使って対象のパッケージを書き換えた結果は以下に示すので、コード読んでみてほしい。
https://github.com/turtton/dotnix/blob/main/overlay/force-wayland.nix

## ちょっとした悩みたち

導入して数週間経った今でも解決できてない微妙な悩みも一応書き連ねておく(解決策があれば教えてください)

- Chromium系ソフトウェアのIME入力時や頻繁に画面更新されるページ(動画など)で画面がちらつく(Nvidiaのせい？)
- NetworkManagerのVPNなどの接続をグラフィカルに切り替えられない(良い感じのGUIが見つけられず、`nmcli con up id <name>`で接続するしかない。`networkmanager_dmenu`を試したがrofi-waylandでは動かない？)

# 私のdotfileに興味のある方へ

issueにて試そうとされていた方がいたため、[README](https://github.com/turtton/dotnix/blob/main/README.md)でも簡単には書いていますがこちらでも記載しておきます。

基本的にはvirtboxプロファイルから試すことをおすすめします。無駄なアプリケーションが少なく、比較的少ないストレージ容量(75GB程度)で試せるものです。実践導入前に仮想環境で試していたものですが、設定の参照先は同じであるため実機で使用しているmaindeskと同じHyprland環境を試すことができます。
導入時は[hardware-configuration.nix](https://github.com/turtton/dotnix/blob/main/hosts/virtbox/hardware-configuration.nix)をご自身のものと置き換えることと、ユーザー名を`turtton`にしてOSをインストールするか、[ここ](https://github.com/turtton/dotnix/blob/f9b9ee42bcde979847cfa9231c31354e943fc85a/hosts/default.nix#L212)を変更して今のユーザー名に合わせるようにしてください。
あとは記載しているコマンドを叩くだけで、Nixの高い再現性によってスクリーンショットのままの環境が手に入ります。

よいNixOSライフを！


[^1]: [plasma-manager](https://github.com/nix-community/plasma-manager)を使っていたが使っていたテーマの完全再現ができない(ウィンドウボタンのテーマが指定できなくてグローバルテーマに持ってかれる)とか、latteの設定をうまく固定できない、単純にplasma5環境だと新規ウィンドウの生成が遅い、通知が表示されると全体のフレームレーットが一瞬落ちる、など
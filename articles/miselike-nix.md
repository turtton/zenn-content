---
title: "Nix Flake+direnvでプロジェクトのパッケージ管理"
emoji: "👷"
type: "tech"
topics: ["nix", "nixflakes", "direnv"]
published: true
---

唐突なんですけど、「mise」人気ですよね。ArchLinuxを利用していた頃は自分も使っていました。
ただ、NixOSを利用するようになってからは、全部Flake+direnvでええやんとなってしまったのでmiseを使わなくなりました。
利点としては10万を越える豊富なパッケージが利用できることと、高い自由度があると思います。
まあ「nixわけわかめだからtomlとかで設定できるmiseが良いんじゃ」って言われそうなんですけど、nix言語は[関数の生えたJSONらしい](https://www.reddit.com/r/NixOS/comments/1d4gobt/nix_is_just_json_with_functions/)のでそんな難しくないです。

...冗談はともかく、今はノリと勢いとAIでなんとかなるので雰囲気を掴んでその良さを知ってもらえたらうれしいなって思います。どちらかと言えばNixOS以外のユーザー向けです。

:::message
以下の内容は[Nixを導入](https://github.com/DeterminateSystems/nix-installer)した上で[Flakesが有効になっている](https://wiki.nixos.org/wiki/Flakes/ja#Setup)こと、[direnv](https://direnv.net)を導入していることを前提としています。
:::

# flake.nixの作成
ゼロから書くのは大変面倒なので、テンプレートを使うのが楽です。連携用のシステムである[nix-direnv](https://github.com/nix-community/nix-direnv)には専用のテンプレートが配布されているので、以下でテンプレートから作成します。

```sh
$ nix flake new -t github:nix-community/nix-direnv hello-flake
```

:::details 今いるディレクトリに展開したい場合
```sh
$ nix flake init -t github:nix-community/nix-direnv
```
:::

これで`hello-flake`ディレクトリが作成され、その中に`flake.nix`と`.envrc`が配置されます。

とりあえずターミナルで`hello-flake`ディレクトリに移動し、以下のコマンドを実行します。
```sh
$ cd hello-flake
# gitの初期化
$ git init
$ echo ".direnv" >> .gitignore
$ git add .
# Direnvを有効化
$ direnv allow
```

:::details gitを初期化する理由
flakeはgitの管理システムに一部依存しており、管理対象となっているファイルのみを評価します。管理対象を絞らないことで、後々困る(flake.nixからファイルを参照できないor余計なファイルを参照してしまう)ことがあるので初期化しておくことをお勧めします。
:::

初回だけちょっと時間がかかります。
これで`nix develop`相当の処理が実行され、パスが通るようになります。

:::details ざっくりとした挙動
1. `flake.nix`が評価され、`devShells.default`が呼び出される
2. `devShells.default`で指定されたパッケージがインストール
3. 環境変数`PATH`にインストールされたパッケージのパスが追加される

※パッケージ以外の設定もそんな感じで反映されます。

この内容から気付いた人もいるかもしれませんが、`nix develop`コマンド自体も仮想環境を立ち上げているとかではなく、単にbashを起動してパスを通しているだけです(結構勘違いされがち)
:::

# パッケージの追加

ちょっとだけflake.nixの内容をいじってみましょう。

18行目の`bashInteractive`の後に`hello`パッケージを追加してみます。

```diff nix:flake.nix
- devShells.default = pkgs.mkShell { packages = [ pkgs.bashInteractive ]; };
+ devShells.default = pkgs.mkShell { packages = [ pkgs.bashInteractive pkgs.hello ]; };
```

ターミナルで一度Enterを押すなりするとhelloパッケージがインストールされ、helloコマンドが利用できるようになります。
```sh
$ hello
Hello, world!
```

こんな感じで好きにパッケージを追加することができます。
有効なパッケージは[公式の検索サイト](https://search.nixos.org/packages?channel=unstable)で探すことができます。
https://search.nixos.org/packages?channel=unstable
miseとは異なり、細かいバージョンを指定するのは難しいですが、flake.lockにより定義からインストールされるパッケージのバージョンは固定されるので、チームで同じ環境を共有することができます。

更新は以下のコマンドで行います。
```sh
$ nix flake update
```

# `flake.nix`のフォーマット
プロジェクト管理ではないですが、色々書いていると乱雑になるので、早めに設定しておくと幸せになれます。
```diff nix:flake.nix
 pkgs = nixpkgs.legacyPackages.${system};
in
{
+  formatter = pkgs.nixfmt-tree;
```

```sh
$ nix fmt
```

# カスタムスクリプトの追加
miseのタスクランナーが人気らしいので、flakeでもできるよってのをアピールしておきます。

nixpkgsには、パッケージだけでなく便利なユーティリティもたくさん含まれています。
その中でも[`pkgs.writeScriptBin`](https://noogle.dev/f/pkgs/writeScriptBin)を使うと簡単にスクリプトを追加できます。
例えば、GitHub Actionの履歴を取得する場合
```diff nix:flake.nixos
packages = [
    pkgs.bashInteractive
    pkgs.hello
+    (pkgs.writeScriptBin "gh-actions-history" "gh run list --limit 100")
];
```

これでまたターミナルでEnterを一度押すと`gh-actions-history`コマンドが利用できるようになります。
```sh
$ gh-actions-history
STATUS  TITLE           WORKFLOW     BRANCH       EVENT        ID           ELAPSED   AGE        
✓       🐛 Use roo-...  build co...  main         push         20206750647  5h8m1s    about 2 ...
...
```

実態はただのシェルスクリプトなので、複数行に及ぶ宣言も可能です。またPCにインストールしていない、packages内で追加したパッケージも使えます。
```diff nix:flake.nixos
    (pkgs.writeScriptBin "gh-actions-history" "gh run list --limit 100")
+    pkgs.jq
+    (pkgs.writeScriptBin "show-api-paths" ''
+      PATHS=$(jq -r '.paths | keys[]' openapi.json)
+      for url in $PATHS; do
+        echo $url
+      done
+    '')
];
```

```sh 
# 例： https://gist.github.com/biggates/4955d608379a8b1b3224e815c7dd0dc9
# $ curl -L -o openapi.json https://gist.githubusercontent.com/biggates/4955d608379a8b1b3224e815c7dd0dc9/raw/0f69ccfb49181f17f2e2c1f5caedc345f1f40af5/petstore_oas3_requestBody_example.json
$ show-api-paths
/pet
/pet/findByStatus/MultipleExamples
/pet/findByStatus/singleExample
```


# 環境変数の設定

これに関してはDirenv側で`.env`とかを読み込むようにしてもいいんですが、一応flake.nix側で設定する方法も紹介しておきます。
例えば`FOO`という環境変数を設定したい場合、以下のようにします。

```diff nix:flake.nix
packages = [
    ...
];
+env = {
+  "FOO" = "BAR";
+};
```

再度ターミナルでEnterを押してから以下のような出力が得られるはずです。

```sh
$ echo $FOO
BAR
```

# 初回セットアップの自動化

ディレクトリに入った時に特定の処理を実行したい場合、`shellHook`を使うと便利です。
例えば、とりあえず`pnpm install`を実行したい場合、以下のようにします。

```diff nix:flake.nix
env = {
...
};
+ shellHook = ''
+   if [ ! -d "node_modules" ]; then
+     echo "初回セットアップ: pnpm install を実行しています..."
+     pnpm install
+   fi
+ '';
```

これでディレクトリに入るたびに`node_modules`ディレクトリが存在するか確認し、なければ`pnpm install`を実行します。
shellの名の通り、普通のシェルスクリプトが書けるので、好きにカスタマイズできます。

# Editor連携

これはNix Flakeの機能というよりdirenvの機能ですが、お好みのEditor/IDEを経由してこれらのパッケージや環境変数にアクセスすることも可能です。
代表的なプラグインでは以下のようなものがあります。

VSCode: [direnv](https://marketplace.visualstudio.com/items?itemName=mkhl.direnv)
https://marketplace.visualstudio.com/items?itemName=mkhl.direnv

IDEA: [Direnv Integration](https://plugins.jetbrains.com/plugin/15285-direnv-integration)
https://plugins.jetbrains.com/plugin/15285-direnv-integration

# おわりに
こんな感じでmiseでできることは大体できると思います。
「こんなんmiseとか別の便利ツールではできるんやがFlakeではどうなの？」とか、「ここがよくわからん！」みたいなのがあれば教えてください。

応用編として外部flakeを使うと`nix fmt`で[全ファイルのフォーマット](https://github.com/numtide/treefmt-nix)ができたりとか無限の可能性があるんですが、まあそれはまた別の機会に。


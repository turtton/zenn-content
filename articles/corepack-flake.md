---
title: "Nix FlakeでCorepack"
emoji: "📦️"
type: "tech"
topics: ["nixos", "corepack"]
published: true
---

nixのパッケージマネージャは素晴らしいが、フロントエンドのパッケージマネージャのバージョンを細かく合わせるのには向かない。
プロジェクトによっては`package.json`の`packageManager`フィールドでバージョンを細かく指定してくれているので、それを尊重したい。

ということでcorepack enableするとNixOS環境では失敗するという話と、その回避方法はこちらが詳しい。

https://zenn.dev/eiel/articles/15103684351cb8

これをnix flakeで利用したい。ということで以下のように記載するといける

```nix
{
  description = "Corepack environment with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        corepack = with pkgs; stdenv.mkDerivation {
          name = "corepack";
          buildInputs = [ pkgs.nodejs-slim ];
          phases = [ "installPhase" ];
          installPhase = ''
            mkdir -p $out/bin
            corepack enable --install-directory=$out/bin
          '';
        };
      in
      {
        devShells.default = with pkgs; mkShell {
          packages = [ bashInteractive corepack ];
        };
      });
}
```

ついでに[direnv](https://direnv.net)および[nix-direnv](https://github.com/nix-community/nix-direnv)とか入れておくとディレクトリに入っただけでpathが通るので便利。

とはいえ、毎回上を書くのは面倒なのでテンプレートから使うのが便利。

以下のコマンドをcorepack設定済みなプロジェクトで実行してもらえれば`flake.nix`と`.envrc`が配置されます。

```sh
nix flake init -t github:turtton/flake-templates#corepack
```


ソースはこれ
https://github.com/turtton/flake-templates/blob/main/templates/corepack/flake.nix

# 余談

上の手法は一年前ぐらいに作って以降ずっとお世話になっているわけですが、どうやらNode.js v25からCorepackは分離されてるらしい。
https://nodejs.org/dist/latest/docs/api/corepack.html
https://zenn.dev/monicle/articles/b7a9314f9f1efb
ということで半分供養の意味も込めてこの記事を作りました。
今後どうするのが正解なのかわかってないのでよければ教えてください。

最初の内容と矛盾してるんですが、個人的にはnixpkgsにある適当なバージョンのpnpmとかbunとか使うことに抵抗ないのでそれでいいかな〜とか思ってたりする。

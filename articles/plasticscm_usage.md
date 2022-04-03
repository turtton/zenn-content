---
title: "VRChatのアバターの差分バックアップを取ろう【PlasticSCM】"
emoji: "🗄️"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["VRChat", "Unity", "PlasticSCM"]
published: true
---

# きっかけ

ここ数ヶ月でVRChatにハマり、アバターのアップロードのために初めてUnityを触るようになりました。アバターに小物を持たせたり、エモートを入れたりしているとあっという間に設定が複雑化し、更なる改変時の設定ミスや、データの紛失などで再起不能になる恐怖と戦うことになります。

筆者は元々Gitの差分バックアップ大好き人間なので、Unity上で使える差分バックアップシステムの存在を知り即導入しました。

# PlasticSCMとは

バージョン管理システムの1つで、GUIツールやクラウドサービスも一緒に提供されています。Gitなどとの細かい違いは[公式サイト](https://www.plasticscm.com/#:~:text=what%20makes%20plastic%20scm%20different%3F)に表でまとめられています。

2020年に[Unityに買収された](https://blog.unity.com/ja/news/codice-software-joins-unity-technologies-to-bring-version-control-to-real-time-3d-workflows)こともあり、Unityとの親和性は一番高そう。

# インストール

https://www.plasticscm.com

1. 公式サイトから**TryNow**を押すとクラウドを使用するための個人情報の入力を求められるので必要事項を記入します。
   Unityアカウントでサインインすることもできるので、アカウントを別で作りたい場合以外はそっちを使いましょう。

このときのページで書いてある通り5GBまで無料のクラウドと契約することになります。万が一バックアップデータが5GBを超えた場合は月5$を請求されるので注意です。 (アバター三体+小物色々あるプロジェクトをアップロードしても0.3GB程度だったのでそこまで気にしなくても大丈夫そうです)

![subscription](/images/plasticscm_usage/subscription_details.png)

2. **FINISH SIGN UP**を押した先のページで**Download**を押すとインストーラのダウンロードが始まるので、そのままインストールします。

途中コンポーネントの選択を要求されますが、Unity上で扱うだけなら無視で大丈夫です。

![components](/images/plasticscm_usage/installer_components.png)

# プロジェクトのセットアップ

1. インストールが終わるとソフトが起動し、サインインが要求されます。

> PlasticSCMはデフォルトでデスクトップショートカットを作成しません。もし起動しない場合はwindowsキー→`plastic`と入力するとソフトを見つけることができます。

![siginin](/images/plasticscm_usage/plastic_signin.png)

2. Cloudを契約したアカウントでサインインすると、登録した組織名が表示されます。

![organization](/images/plasticscm_usage/display_organization.jpg)

3. PlasticSCMには二種類のGUIソフトウェアが存在します。今回はシンプルな**Gluon**を選択します。

4. プロジェクトの選択を要求されるので、`新規`->`新規リポジトリを作成`より任意のリポジトリ名を入力してOKを押します。

アバターを管理しているプロジェクトのディレクトリを`作業ディレクトリ`欄に入力します。

> 場所がわからない場合はUnityで一度プロジェクトを開き、Projectタブ内で右クリック->`show in explorer`で表示することができます。

![select](/images/plasticscm_usage/select_project.png)

5. 画面が切り替わり、このようになります。
   ![workspace](/images/plasticscm_usage/workspace.png)

# 不要ファイルの除外

Unityのプロジェクトファイルには一部バックアップ不要なファイルが存在します。

詳しくは[PlasticSCMのブログ](https://blog.plasticscm.com/2020/01/definitive-ignoreconf-for-unity-projects.html)にまとめられていますが、主な不要ファイルの除外方法を説明します。

> 以下の手動で設定する方法の他に、上記ブログにあるテンプレート使う、Unityでプロジェクトを開き自動生成することでも設定が可能です。

`Library`/`Logs`/`Temp`を選択し右クリック->`無視リストに追加`->`項目のフルパスを使用`を選択し、出てきたポップアップウィンドウのOKを選択します。

> 個別で選択した場合は`無視リストに追加`を押した後、`/`が付いている方を選択してください(例: `/Temp`)

![ignore](/images/plasticscm_usage/ignorerules.png)

3つのフォルダのステータスが無視に設定され、`ignore.conf`が追加されていれば正しく設定できています。

![ignoredworkspace](/images/plasticscm_usage/ignored_workspace.png)

# バックアップを取る

PlasticSCMではバックアップを取ることを`チェックイン`といいます。チェックインを行うことでその段階でのファイルの変更状態を保存します。

`変更をチェックイン`タブに移動し、`全てチェック`と書かれたチェックボックスをクリックしチェックを入れて任意のコメントを入力した後、`チェックイン`ボタンをクリックすることでバックアップが取られます。画像ではコメントを`Firstチェックイン!`としています。(コメントは日本語も入力できます)

![checkin](/images/plasticscm_usage/first_checkin.png)

> 初回チェックインにおいて、データ暗号化のためのパスワード入力を要求されることがあります。備考にも書かれていますが、同じサーバー上では同じパスワードを設定するようにしてください。
>
> ![serverpass](/images/plasticscm_usage/server_password.png)

# Unity上でPlasticSCMと連携する

1. 対象プロジェクトを開き、メニュー欄から`Edit`->`Project Settings`->`VersionControl`から`PlasticSCM`を選択します。

   ![versioncontrol](/images/plasticscm_usage/set_versioncontrol.png)

2. 下に`Check Out`ボタンが表示されるのでクリックすると設定の変更が適応されます。

   ![checkout](/images/plasticscm_usage/unity_checkout.png)

3. 新しくPlasticSCMタブが追加されていれば正しく設定できています。今後はここからチェックインなどの操作が可能です。

   ![plasticmenu](/images/plasticscm_usage/unity_pscmmenu.png)

# その他の操作

以下はPlasticSCMでできる特殊な操作となります。基本的なバックアップはここまででできているので、以降は必要に応じてご覧ください。

> 一部操作はGluonではできない場合があります。その場合は現在の変更を全てチェックインまたは取り消した後Gluonを閉じ、PlasticSCMを開いて更新を選択し、以降の操作もPlasticSCM上で行ってください。

## 直前のバックアップまで戻る

- Unity上で行う

  `PlasticSCM`タブから取り消したい変更にチェックを入れて、`変更を取り消す`をクリック

- Gluon上で行う

  `変更をチェックイン`タブから取り消したい変更にチェックを入れて、`取り消し`をクリック



## 特定の変更セットまで戻る

> ⛔この操作はGluon上で行うことはできません

⚠️この操作を行った後、戻る前にロールバックすることはできません。一時的に変更を遡りたい場合はブランチを分けることをお勧めします。

1. `変更セット`から戻りたい変更を右クリックし、`ワークスペースを子の変更セットに切り替え`を選択します。

   ![select](/images/plasticscm_usage/select_changeset.png)

2. 切り替えた変更より上の変更セットを全て削除します。

   対象の変更セットを右クリック->`詳細`->`変更セットを削除`

   ![remove](/images/plasticscm_usage/remove_changeset.png)

3. 右上の リロード(🔁)ボタンを押すとワークスペースが更新され、変更が認識されます。



## ブランチを分けて作業する

これまでの説明では常にmainブランチ上で作業を行ってきていました。そのため変更セットを巻き戻し、削除した場合は二度と基に戻せないといったリスクが存在していましたが、ブランチを分けることでそのような問題を回避し、いつでもmainブランチの変更セットに巻き戻したり、mainブランチに別ブランチの変更セットを適応したりすることができます。

> ⛔ブランチを扱うレベルの操作は高度なものが多いため、GluonではなくPlasticSCM上で操作する前提で記述しています。

### 新たなブランチを作成する

以下ではmainブランチを基に子ブランチを作成します。

1. ブランチタブから`main`ブランチを右クリックし、子ブランチを作成を選択します。
   ![branch](/images/plasticscm_usage/create_branch.png)

2. 任意の名前を設定し、`OK`をクリックします。このとき`ワークスペースをこのブランチに切り替え`にチェックを入れておくと作成後自動でワークスペースが切り替わります。

   ![setname](/images/plasticscm_usage/set_branch_name.png)

### ブランチを切り替える

> 保留中の変更が存在する場合は全てチェックインまたは取り消してから以下の操作を行ってください。

1. `ブランチ`タブから切り替えたいブランチを右クリックし、`ワークスペースをこのブランチに切り替え`を選択します。

   ![change](/images/plasticscm_usage/change_branch.png)

2. 確認のダイアログが表示されるので`はい`を選択します。

### 別ブランチの変更を適応する

1. 変更を**適応させたい**ブランチ(mainブランチなど)に切り替えてください。

2. `ブランチ`タブから変更元のブランチを右クリックし、`このブランチからマージ`を選択します。

   ![merge](/images/plasticscm_usage/merge_branch.png)

3. 変更されるファイルを確認した後、変更を適応をクリックします。

   ![apply_merge](/images/plasticscm_usage/apply_merge.png)

4. 変更されたファイルを`保留中の変更`タブから選択し、任意のコメントを入力して`チェックイン`を押すと、マージした変更がチェックインされます。

   ![apply_changes](/images/plasticscm_usage/checkin_mergelink.png)

5. ブランチエクスプローラーで確認すると、変更がmainブランチに取り込まれたことが分かります。(ここでは右の緑色が現在のブランチの最新の変更セットを表しています)

   ![branches](/images/plasticscm_usage/branch_explorer.png)

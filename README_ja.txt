
Spotlight plugin for MailSpool 0.1.4u


                    Yoshida Masato <yoshidam@yoshidam.net>

概要

  MH や Gnus の nnml 形式のメールフォルダ用の Spotlight プラ
  グインです。Mail ディレクトリの下の数字名のファイルのメタ
  データを抽出し， Spotlight にインポートします。

  メタデータ抽出のために Ruby インタプリタを組み込んでいます。
  GetMetadataForFile.rb というファイルを書き換えて簡単にカス
  タマイズすることができます。ただし，処理はちょっと重くなっ
  ています。

  メールのパースには TMail (http://www.loveruby.net/ja/prog/tmail.html)
  を使用しています。HTML メールのパースに ymHTML
  (http://www.yoshidam.net/Ruby_ja.html#ymHTML) を使用しています。


インストール

  MailSpool.mdimporter を ~/Library/Spotlight/ の下にコピー
  してください。


使いかた

  ## 認識しているかどうか確認
  $ mdimport -L

  ## 動作テスト
  $ mdimport -d2 -n ~/Mail/test/

  ## インポート
  $ mdimport ~/Mail/test/

  ## メタデータの確認
  $ mdls ~/Mail/test/1

  ## 検索のテスト
  $ mdfind -onlyin ~/Mail/ 'kMDItemTitle == "テスト*"'



ライセンス

  TMail は LGPL，それ以外の部分は Ruby ライセンスです。


履歴

  Jan 06, 2008 version 0.1.4u
               Universal Binary 化
  Oct 10, 2005 version 0.1.4
               英語環境で動作しない問題に対応
  May 23, 2005 version 0.1.2
               kMDItemContentCreationDate が正しく設定されな
               いバグを修正
               日本語メールのcharsetパラメタを信用にしないよ
               うに変更
  May  8, 2005 version 0.1.1
  May  7, 2005 version 0.1

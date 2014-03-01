
Spotlight plugin for MailSpool 0.1.4u


                    Yoshida Masato <yoshidam@yoshidam.net>

Introduction

  This is a Spotlight plugin for the mail folder of MH
  or Gnus nnml backend. It extracts metadata from
  numbered files under Mail directory, and imports the metadata
  into Spotlight database.

  It uses Ruby interpreter to extract metadata.
  So you can easily customize the extraction to edit
  GetMetadataForFile.rb file.
  But processing is slightly heavy because of Ruby.

  To parse mails, it includes TMail library
  (http://www.loveruby.net/ja/prog/tmail.html).
  To parse HTML mails, it includes ymHTML library
  (http://www.yoshidam.net/Ruby_ja.html#ymHTML).


Install

  Copy MailSpool.mdimporter to ~/Library/Spotlight/.


Usage

  ## list plugins
  $ mdimport -L

  ## test to extraction
  $ mdimport -d2 -n ~/Mail/test/

  ## import
  $ mdimport ~/Mail/test/

  ## list metadata
  $ mdls ~/Mail/test/1

  ## test to search
  $ mdfind -onlyin ~/Mail/ 'kMDItemTitle == "Test*"'



License

  TMail is under LGPLÅCand the other parts are under Ruby licenseÅB


History

  Jan 06, 2008 version 0.1.4u
               Universal Binary version.
  Oct 10, 2005 version 0.1.4
               support to work in English environment.
  May 23, 2005 version 0.1.2
  May  8, 2005 version 0.1.1
  May  7, 2005 version 0.1

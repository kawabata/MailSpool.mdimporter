
Spotlight plugin for MailSpool 0.1.4u


                    Yoshida Masato <yoshidam@yoshidam.net>

�T�v

  MH �� Gnus �� nnml �`���̃��[���t�H���_�p�� Spotlight �v��
  �O�C���ł��BMail �f�B���N�g���̉��̐������̃t�@�C���̃��^
  �f�[�^�𒊏o���C Spotlight �ɃC���|�[�g���܂��B

  ���^�f�[�^���o�̂��߂� Ruby �C���^�v���^��g�ݍ���ł��܂��B
  GetMetadataForFile.rb �Ƃ����t�@�C�������������ĊȒP�ɃJ�X
  �^�}�C�Y���邱�Ƃ��ł��܂��B�������C�����͂�����Əd���Ȃ�
  �Ă��܂��B

  ���[���̃p�[�X�ɂ� TMail (http://www.loveruby.net/ja/prog/tmail.html)
  ���g�p���Ă��܂��BHTML ���[���̃p�[�X�� ymHTML
  (http://www.yoshidam.net/Ruby_ja.html#ymHTML) ���g�p���Ă��܂��B


�C���X�g�[��

  MailSpool.mdimporter �� ~/Library/Spotlight/ �̉��ɃR�s�[
  ���Ă��������B


�g������

  ## �F�����Ă��邩�ǂ����m�F
  $ mdimport -L

  ## ����e�X�g
  $ mdimport -d2 -n ~/Mail/test/

  ## �C���|�[�g
  $ mdimport ~/Mail/test/

  ## ���^�f�[�^�̊m�F
  $ mdls ~/Mail/test/1

  ## �����̃e�X�g
  $ mdfind -onlyin ~/Mail/ 'kMDItemTitle == "�e�X�g*"'



���C�Z���X

  TMail �� LGPL�C����ȊO�̕����� Ruby ���C�Z���X�ł��B


����

  Jan 06, 2008 version 0.1.4u
               Universal Binary ��
  Oct 10, 2005 version 0.1.4
               �p����œ��삵�Ȃ����ɑΉ�
  May 23, 2005 version 0.1.2
               kMDItemContentCreationDate ���������ݒ肳���
               ���o�O���C��
               ���{�ꃁ�[����charset�p�����^��M�p�ɂ��Ȃ���
               ���ɕύX
  May  8, 2005 version 0.1.1
  May  7, 2005 version 0.1

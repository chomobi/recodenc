#! /usr/bin/perl
################################################################################
# Recodenc
# Copyright © 2016-2017 terqüéz <gz0@ro.ru>
#
# This file is part of Recodenc.
#
# Recodenc is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
################################################################################
# Опции конфигурационного файла:
#	page — идентификатор поднятой страницы 0..7
#	eu4_c2 — OFF = не сохранять в др. каталог; ON = сохранять
#	eu4_cat1 — каталог №1
#	eu4_cat2 — каталог №2
#	eu4l_origru — каталог с русской локализацией EU4 (FULL)
#	eu4l_origen — каталог с оригинальной английской локализацией EU4
#	eu4l_saveru — каталог для сохранения скомпилированной Lite-локализации
#	eu4d_dlc — каталог с zip-архивами DLC EU4
#	eu4d_dst — каталог для сохранения извлечённой локализации
#	ck2_c2 — OFF = не сохранять в др. каталог; ON = сохранять
#	ck2_cat1 — каталог №1
#	ck2_cat2 — каталог №2
#	ck2l_origru — каталог с русской локализацией CK2 (Full)
#	ck2l_origen — каталог с оригинальной английской локализацией CK2
#	ck2l_saveru — каталог для сохранения скомпилированной Lite-локализации
#	fnt_c2 — OFF = не сохранять в др. каталог; ON = сохранять
#	fnt_cat1 — каталог №1
#	fnt_cat2 — каталог №2
#	cnv_c2 — OFF = не сохранять в др. каталог; ON = сохранять
#	cnv_cat1 — каталог №1
#	cnv_cat2 — каталог №2
#	ptx_c2 — OFF = не сохранять в др. каталог; ON = сохранять
#	ptx_cat1 — каталог №1
#	ptx_cat2 — каталог №2
################################################################################
BEGIN {
	if ($^O eq 'MSWin32') {
		require Win32::Console;
		Win32::Console::Free();
	}
}
use utf8;
use v5.18;
use warnings;
use integer;
use vars qw($PROGNAME $VERSION $LABEL_PADDING);
use IUP;
use IUP::Button;
use IUP::Constants qw(:basic :keys);
use IUP::Dialog;
use IUP::FileDlg;
use IUP::GridBox;
use IUP::Hbox;
use IUP::Image;
use IUP::Item;
use IUP::Label;
use IUP::Menu;
use IUP::Separator;
use IUP::Submenu;
use IUP::Tabs;
use IUP::Text;
use IUP::Toggle;
use IUP::Vbox;
use Recodenc;
use Scalar::Util qw(looks_like_number);
use Encode qw(encode decode);
use Encode::Locale;
binmode(STDIN, ":encoding(console_in)");
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");

*PROGNAME = \'Recodenc';
*VERSION = \'0.6.1';
*LABEL_PADDING = \'3x3';

# загрузка конфигурации
my $conf_path_dir; # имя каталога файла конфигурации
my $conf_path_file; # имя файла конфигурации
if ($^O eq 'MSWin32') {
	$conf_path_dir = "$ENV{APPDATA}/recodenc";
}
else {
	if (defined($ENV{XDG_CONFIG_HOME})) {
		$conf_path_dir = "$ENV{XDG_CONFIG_HOME}/recodenc";
	}
	else {
		$conf_path_dir = "$ENV{HOME}/.config/recodenc";
	}
}
unless (-d encode('locale_fs', $conf_path_dir)) {
	mkdir encode('locale_fs', $conf_path_dir) or die "Не удалось создать каталог: $conf_path_dir\n";
}
$conf_path_file = "$conf_path_dir/recodenc.conf";
my %config;
if (-e encode('locale_fs', $conf_path_file)) {
	%config = &config_read(encode('locale_fs', $conf_path_file));
}
### рисование интерфейса
## инициализация переменных для хранения указателей на элементы интерфейса
# иконка в заголовке окна
my $window_icon_16x16 = IUP::Image->new(
	pixels =>
[[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
 [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
 [0,1,0,0,0,1,1,0,0,0,1,0,0,0,1,0],
 [0,1,0,1,1,0,1,0,1,1,1,0,1,1,1,0],
 [0,1,0,0,0,1,1,0,0,1,1,0,1,1,1,0],
 [0,1,0,1,1,0,1,0,1,1,1,0,1,1,1,0],
 [0,1,0,1,1,0,1,0,0,0,1,0,0,0,1,0],
 [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
 [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
 [0,1,0,0,0,1,0,1,1,0,1,0,0,0,1,0],
 [0,1,0,1,1,1,0,0,1,0,1,0,1,1,1,0],
 [0,1,0,0,1,1,0,1,0,0,1,0,1,1,1,0],
 [0,1,0,1,1,1,0,1,1,0,1,0,1,1,1,0],
 [0,1,0,0,0,1,0,1,1,0,1,0,0,0,1,0],
 [0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
 [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]],
	colors => ['0 0 0', '255 255 255']
);
# создание флагов
my $eu4_togl = IUP::Toggle->new(TITLE => 'Сохранить в:', ACTION => sub{$config{eu4_c2} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $ck2_togl = IUP::Toggle->new(TITLE => 'Сохранить в:', ACTION => sub{$config{ck2_c2} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $fnt_togl = IUP::Toggle->new(TITLE => 'Сохранить в:', ACTION => sub{$config{fnt_c2} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $cnv_togl = IUP::Toggle->new(TITLE => 'Сохранить в:', ACTION => sub{$config{cnv_c2} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $ptx_togl = IUP::Toggle->new(TITLE => 'Сохранить в:', ACTION => sub{$config{ptx_c2} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
# создание текстовых полей
my $eu4_text_proc = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{eu4_cat1} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $eu4_text_save = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{eu4_cat2} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $eu4l_text_origru = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{eu4l_origru} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $eu4l_text_origen = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{eu4l_origen} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $eu4l_text_saveru = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{eu4l_saveru} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $eu4d_text_dlc = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{eu4d_dlc} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $eu4d_text_dst = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{eu4d_dst} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $ck2_text_proc = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{ck2_cat1} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $ck2_text_save = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{ck2_cat2} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $ck2l_text_origru = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{ck2l_origru} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $ck2l_text_origen = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{ck2l_origen} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $ck2l_text_saveru = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{ck2l_saveru} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $fnt_text_proc = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{fnt_cat1} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $fnt_text_save = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{fnt_cat2} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $cnv_text_proc = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{cnv_cat1} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $cnv_text_save = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{cnv_cat2} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $ptx_text_proc = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{ptx_cat1} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
my $ptx_text_save = IUP::Text->new(EXPAND => 'HORIZONTAL', VALUECHANGED_CB => sub{$config{ptx_cat2} = shift->GetAttribute('VALUE'); return IUP_DEFAULT});
# создание строки для вывода статуса
my $status = IUP::Label->new(EXPAND => 'HORIZONTAL', PADDING => $LABEL_PADDING);
# присвоение значениий флагам
$eu4_togl->SetAttribute(VALUE => $config{eu4_c2});
$ck2_togl->SetAttribute(VALUE => $config{ck2_c2});
$fnt_togl->SetAttribute(VALUE => $config{fnt_c2});
$cnv_togl->SetAttribute(VALUE => $config{cnv_c2});
$ptx_togl->SetAttribute(VALUE => $config{ptx_c2});
# присвоение значений текстовым полям
$eu4_text_proc->SetAttribute(VALUE => $config{eu4_cat1});
$eu4_text_save->SetAttribute(VALUE => $config{eu4_cat2});
$eu4l_text_origru->SetAttribute(VALUE => $config{eu4l_origru});
$eu4l_text_origen->SetAttribute(VALUE => $config{eu4l_origen});
$eu4l_text_saveru->SetAttribute(VALUE => $config{eu4l_saveru});
$eu4d_text_dlc->SetAttribute(VALUE => $config{eu4d_dlc});
$eu4d_text_dst->SetAttribute(VALUE => $config{eu4d_dst});
$ck2_text_proc->SetAttribute(VALUE => $config{ck2_cat1});
$ck2_text_save->SetAttribute(VALUE => $config{ck2_cat2});
$ck2l_text_origru->SetAttribute(VALUE => $config{ck2l_origru});
$ck2l_text_origen->SetAttribute(VALUE => $config{ck2l_origen});
$ck2l_text_saveru->SetAttribute(VALUE => $config{ck2l_saveru});
$fnt_text_proc->SetAttribute(VALUE => $config{fnt_cat1});
$fnt_text_save->SetAttribute(VALUE => $config{fnt_cat2});
$cnv_text_proc->SetAttribute(VALUE => $config{cnv_cat1});
$cnv_text_save->SetAttribute(VALUE => $config{cnv_cat2});
$ptx_text_proc->SetAttribute(VALUE => $config{ptx_cat1});
$ptx_text_save->SetAttribute(VALUE => $config{ptx_cat2});
# создание вкладок
my $tabs = IUP::Tabs->new(
	TABCHANGEPOS_CB => \&save_page_raised,
	child => [
		IUP::Vbox->new(
			TABTITLE => 'EU4',
			child => [
				IUP::GridBox->new(
					SIZECOL => 2,
					SIZELIN => 1,
					NUMDIV => 3,
					ALIGNMENTLIN => 'ACENTER',
					ALIGNMENTCOL0 => 'ARIGHT',
					child => [
						IUP::Label->new(TITLE => 'Для обработки:', PADDING => $LABEL_PADDING),
						$eu4_text_proc,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($eu4_text_proc, \$config{eu4_cat1})}),
						$eu4_togl,
						$eu4_text_save,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($eu4_text_save, \$config{eu4_cat2})})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Кодировать (CP1251)', ACTION => sub{&w_recodenc_l10n_eu4($Recodenc::ENC_CP1251); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Кодировать (CP1252CYR)', ACTION => sub{&w_recodenc_l10n_eu4($Recodenc::ENC_CP1252CYREU4); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Транслитерировать', ACTION => sub{&w_recodenc_l10n_eu4($Recodenc::ENC_TRANSLIT); return IUP_DEFAULT})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Декодировать (CP1251)', ACTION => sub{&w_recodenc_l10n_eu4($Recodenc::DEC_CP1251); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Декодировать (CP1252CYR)', ACTION => sub{&w_recodenc_l10n_eu4($Recodenc::DEC_CP1252CYREU4); return IUP_DEFAULT}),
					]
				)
			]
		),
		IUP::Vbox->new(
			TABTITLE => 'EU4Lite',
			child => [
				IUP::GridBox->new(
					SIZECOL => 2,
					SIZELIN => 2,
					NUMDIV => 3,
					ALIGNMENTLIN => 'ACENTER',
					ALIGNMENTCOL0 => 'ARIGHT',
					child => [
						IUP::Label->new(TITLE => 'Рус. лок.:', PADDING => $LABEL_PADDING),
						$eu4l_text_origru,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($eu4l_text_origru, \$config{eu4l_origru})}),
						IUP::Label->new(TITLE => 'Анг. лок.:', PADDING => $LABEL_PADDING),
						$eu4l_text_origen,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($eu4l_text_origen, \$config{eu4l_origen})}),
						IUP::Label->new(TITLE => 'Сохранить в:', PADDING => $LABEL_PADDING),
						$eu4l_text_saveru,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($eu4l_text_saveru, \$config{eu4l_saveru})})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'CP1251', ACTION => sub{&w_recodenc_l10n_eu4_lite($Recodenc::ENC_CP1251); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'CP1252CYR', ACTION => sub{&w_recodenc_l10n_eu4_lite($Recodenc::ENC_CP1252CYREU4); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Транслитерировать', ACTION => sub{&w_recodenc_l10n_eu4_lite($Recodenc::ENC_TRANSLIT); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Только тэгы', ACTION => sub{&w_recodenc_l10n_eu4_tags(); return IUP_DEFAULT})
					]
				)
			]
		),
		IUP::Vbox->new(
			TABTITLE => 'EU4Dlc',
			child => [
				IUP::GridBox->new(
					SIZECOL => 2,
					SIZELIN => 1,
					NUMDIV => 3,
					ALIGNMENTLIN => 'ACENTER',
					ALIGNMENTCOL0 => 'ARIGHT',
					child => [
						IUP::Label->new(TITLE => 'Каталог DLC:', PADDING => $LABEL_PADDING),
						$eu4d_text_dlc,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($eu4d_text_dlc, \$config{eu4d_dlc})}),
						IUP::Label->new(TITLE => 'Каталог назначения:', PADDING => $LABEL_PADDING),
						$eu4d_text_dst,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($eu4d_text_dst, \$config{eu4d_dst})})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Извлечь локализацию', ACTION => sub{&w_recodenc_l10n_eu4_dlc(); return IUP_DEFAULT})
					]
				)
			]
		),
		IUP::Vbox->new(
			TABTITLE => 'CK2',
			child => [
				IUP::GridBox->new(
					SIZECOL => 2,
					SIZELIN => 1,
					NUMDIV => 3,
					ALIGNMENTLIN => 'ACENTER',
					ALIGNMENTCOL0 => 'ARIGHT',
					child => [
						IUP::Label->new(TITLE => 'Для обработки:', PADDING => $LABEL_PADDING),
						$ck2_text_proc,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($ck2_text_proc, \$config{ck2_cat1})}),
						$ck2_togl,
						$ck2_text_save,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($ck2_text_save, \$config{ck2_cat2})})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Кодировать (CP1251)', ACTION => sub{&w_recodenc_l10n_ck2($Recodenc::ENC_CP1251); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Кодировать (CP1252CYR)', ACTION => sub{&w_recodenc_l10n_ck2($Recodenc::ENC_CP1252CYRCK2); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Транслитерировать', ACTION => sub{&w_recodenc_l10n_ck2($Recodenc::ENC_TRANSLIT); return IUP_DEFAULT})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Декодировать (CP1251)', ACTION => sub{&w_recodenc_l10n_ck2($Recodenc::DEC_CP1251); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Декодировать (CP1252CYR)', ACTION => sub{&w_recodenc_l10n_ck2($Recodenc::DEC_CP1252CYRCK2); return IUP_DEFAULT}),
					]
				)
			]
		),
		IUP::Vbox->new(
			TABTITLE => 'CK2Lite',
			child => [
				IUP::GridBox->new(
					SIZECOL => 2,
					SIZELIN => 2,
					NUMDIV => 3,
					ALIGNMENTLIN => 'ACENTER',
					ALIGNMENTCOL0 => 'ARIGHT',
					child => [
						IUP::Label->new(TITLE => 'Рус. лок.:', PADDING => $LABEL_PADDING),
						$ck2l_text_origru,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($ck2l_text_origru, \$config{ck2l_origru})}),
						IUP::Label->new(TITLE => 'Анг. лок.:', PADDING => $LABEL_PADDING),
						$ck2l_text_origen,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($ck2l_text_origen, \$config{ck2l_origen})}),
						IUP::Label->new(TITLE => 'Сохранить в:', PADDING => $LABEL_PADDING),
						$ck2l_text_saveru,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($ck2l_text_saveru, \$config{ck2l_saveru})})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'CP1251', ACTION => sub{&w_recodenc_l10n_ck2_lite($Recodenc::ENC_CP1251); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'CP1252CYR', ACTION => sub{&w_recodenc_l10n_ck2_lite($Recodenc::ENC_CP1252CYRCK2); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Транслитерировать', ACTION => sub{&w_recodenc_l10n_ck2_lite($Recodenc::ENC_TRANSLIT); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Только тэгы', ACTION => sub{&w_recodenc_l10n_ck2_tags(); return IUP_DEFAULT})
					]
				)
			]
		),
		IUP::Vbox->new(
			TABTITLE => 'Шрифт',
			child => [
				IUP::GridBox->new(
					SIZECOL => 2,
					SIZELIN => 1,
					NUMDIV => 3,
					ALIGNMENTLIN => 'ACENTER',
					ALIGNMENTCOL0 => 'ARIGHT',
					child => [
						IUP::Label->new(TITLE => 'Для обработки:', PADDING => $LABEL_PADDING),
						$fnt_text_proc,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($fnt_text_proc, \$config{fnt_cat1})}),
						$fnt_togl,
						$fnt_text_save,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($fnt_text_save, \$config{fnt_cat2})})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Очистить', ACTION => sub{&w_recodenc_font($Recodenc::ENC_NULL); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'CP1251', ACTION => sub{&w_recodenc_font($Recodenc::ENC_CP1251); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'CP1252CYREU4', ACTION => sub{&w_recodenc_font($Recodenc::ENC_CP1252CYREU4); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'CP1252CYRCK2', ACTION => sub{&w_recodenc_font($Recodenc::ENC_CP1252CYRCK2); return IUP_DEFAULT})
					]
				)
			]
		),
		IUP::Vbox->new(
			TABTITLE => 'Мод сохранения',
			child => [
				IUP::GridBox->new(
					SIZECOL => 2,
					SIZELIN => 1,
					NUMDIV => 3,
					ALIGNMENTLIN => 'ACENTER',
					ALIGNMENTCOL0 => 'ARIGHT',
					child => [
						IUP::Label->new(TITLE => 'Для обработки:', PADDING => $LABEL_PADDING),
						$cnv_text_proc,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($cnv_text_proc, \$config{cnv_cat1})}),
						$cnv_togl,
						$cnv_text_save,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($cnv_text_save, \$config{cnv_cat2})})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Конвертировать (CP1251)', ACTION => sub{&w_recodenc_modexport($Recodenc::ENC_CP1251); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Конвертировать (CP1252CYR)', ACTION => sub{&w_recodenc_modexport($Recodenc::ENC_CP1252CYREU4); return IUP_DEFAULT})
					]
				)
			]
		),
		IUP::Vbox->new(
			TABTITLE => 'Простой текст',
			child => [
				IUP::GridBox->new(
					SIZECOL => 2,
					SIZELIN => 1,
					NUMDIV => 3,
					ALIGNMENTLIN => 'ACENTER',
					ALIGNMENTCOL0 => 'ARIGHT',
					child => [
						IUP::Label->new(TITLE => 'Для обработки:', PADDING => $LABEL_PADDING),
						$ptx_text_proc,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($ptx_text_proc, \$config{ptx_cat1})}),
						$ptx_togl,
						$ptx_text_save,
						IUP::Button->new(TITLE => 'Выбрать каталог', ACTION => sub{&seldir($ptx_text_save, \$config{ptx_cat2})})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Код. (CP1251)', TIP => 'Кодировать (CP1251)', ACTION => sub{&w_recodenc_plaintext($Recodenc::ENC_CP1251); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Код. (CP1252CYREU4)', TIP => 'Кодировать (CP1252CYREU4)', ACTION => sub{&w_recodenc_plaintext($Recodenc::ENC_CP1252CYREU4); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Код. (CP1252CYRCK2)', TIP => 'Кодировать (CP1252CYRCK2)', ACTION => sub{&w_recodenc_plaintext($Recodenc::ENC_CP1252CYRCK2); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Транслитерировать', ACTION => sub{&w_recodenc_plaintext($Recodenc::ENC_TRANSLIT); return IUP_DEFAULT})
					]
				),
				IUP::Hbox->new(
					HOMOGENEOUS => 'YES',
					child => [
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Дек. (CP1251)', TIP => 'Декодировать (CP1251)', ACTION => sub{&w_recodenc_plaintext($Recodenc::DEC_CP1251); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Дек. (CP1252CYREU4)', TIP => 'Декодировать (CP1252CYREU4)', ACTION => sub{&w_recodenc_plaintext($Recodenc::DEC_CP1252CYREU4); return IUP_DEFAULT}),
						IUP::Button->new(EXPAND => 'HORIZONTAL', TITLE => 'Дек. (CP1252CYRCK2)', TIP => 'Декодировать (CP1252CYRCK2)', ACTION => sub{&w_recodenc_plaintext($Recodenc::DEC_CP1252CYRCK2); return IUP_DEFAULT})
					]
				)
			]
		)
	]
);
# TODO т. к. нельзя обозначить клавиатурные комбинации в меню, следует указать их в краткой справке
# создание главного окна
my $mw = IUP::Dialog->new(
	TITLE => "$PROGNAME v$VERSION",
	ICON => $window_icon_16x16,
	K_ANY => \&prockeys,
	MENU =>
		IUP::Menu->new(
			child => [
				IUP::Submenu->new(
					TITLE => 'Файл',
					child =>
						IUP::Menu->new(
							child => [
								IUP::Item->new(TITLE => "Выход\t[Ctrl+Q]", ACTION => \&action_close)
							]
						)
				),
				IUP::Submenu->new(
					TITLE => 'Справка',
					child =>
						IUP::Menu->new(
							child => [
								IUP::Item->new(TITLE => "Краткая справка\t[F1]", ACTION => \&action_shorthelp),
								IUP::Item->new(TITLE => "Таблица транслитерации", ACTION => \&action_translittable),
								IUP::Separator->new(),
								IUP::Item->new(TITLE => "О программе", ACTION => \&action_about)
							]
						)
				)
			]
		),
	child =>
		IUP::Vbox->new(
			child => [
				$tabs,
				IUP::Hbox->new(
					ALIGNMENT => 'ACENTER',
					child => [
						$status,
						IUP::Button->new(TITLE => 'Закрыть', ACTION => \&action_close)
					]
				)
			]
		)
);
# показ главного окна
$mw->ShowXY(IUP_CENTER, IUP_CENTER);
# присвоение значения вкладкам
$tabs->SetAttribute(VALUEPOS => $config{page});
# запуск главного цикла обработки событий
IUP->MainLoop;
# запись конфигурации
if (-e encode('locale_fs', $conf_path_file)) {
	my %config2;
	my $c1;
	my $c2;
	%config2 = &config_read(encode('locale_fs', $conf_path_file));
	$c1 = scalar(keys(%config));
	$c2 = scalar(keys(%config2));
	if ($c1 != $c2) {&w_config_write()}
	else {
		my $fl_cfgwrt;
		for my $key (sort keys %config) {
			unless ($config{$key} eq $config2{$key}) {$fl_cfgwrt = 1}
		}
		if (defined($fl_cfgwrt)) {&w_config_write()}
	}
}
else {&w_config_write()}
exit(0);
################
# ПОДПРОГРАММЫ #
################
# Конвертор файлов локализации EU4
sub w_recodenc_l10n_eu4 {
	&win_busy();
	my $fl;
	if    ($config{eu4_c2} eq 'OFF') {$fl = Recodenc::l10n_eu4(shift, $config{eu4_cat1})}
	elsif ($config{eu4_c2} eq 'ON')  {$fl = Recodenc::l10n_eu4(shift, $config{eu4_cat1}, $config{eu4_cat2})}
	proc_fl($fl);
	return 0;
}
# Построитель файлов Lite-локализации EU4
sub w_recodenc_l10n_eu4_lite {
	&win_busy();
	my $fl = Recodenc::l10n_eu4_lite(shift, $config{eu4l_origen}, $config{eu4l_origru}, $config{eu4l_saveru});
	proc_fl($fl);
	return 0;
}
# Вывод тэгов локализации EU4
sub w_recodenc_l10n_eu4_tags {
	&win_busy();
	my $fl = Recodenc::l10n_eu4_tags($config{eu4l_origen}, $config{eu4l_dlc}, $config{eu4l_origru}, $config{eu4l_saveru});
	proc_fl($fl);
	return 0;
}
# Извлечение английской локализации из zip-архивов с DLC
sub w_recodenc_l10n_eu4_dlc {
	&win_busy();
	my $fl = Recodenc::l10n_eu4_dlc($config{eu4d_dlc}, $config{eu4d_dst});
	proc_fl($fl);
	return 0;
}
# Конвертор файлов локализации CK2
sub w_recodenc_l10n_ck2 {
	&win_busy();
	my $fl;
	if    ($config{ck2_c2} eq 'OFF') {$fl = Recodenc::l10n_ck2(shift, $config{ck2_cat1})}
	elsif ($config{ck2_c2} eq 'ON')  {$fl = Recodenc::l10n_ck2(shift, $config{ck2_cat1}, $config{ck2_cat2})}
	proc_fl($fl);
	return 0;
}
# Построитель файлов Lite-локализации CK2
sub w_recodenc_l10n_ck2_lite {
	&win_busy();
	my $fl = Recodenc::l10n_ck2_lite(shift, $config{ck2l_origen}, $config{ck2l_origru}, $config{ck2l_saveru});
	proc_fl($fl);
	return 0;
}
# Вывод тэгов локализации CK2
sub w_recodenc_l10n_ck2_tags {
	&win_busy();
	my $fl = Recodenc::l10n_ck2_tags($config{ck2l_origen}, $config{ck2l_origru}, $config{ck2l_saveru});
	proc_fl($fl);
	return 0;
}

# Очистка и модификация карт шрифтов
sub w_recodenc_font {
	&win_busy();
	my $fl;
	if    ($config{fnt_c2} eq 'OFF') {$fl = Recodenc::font(shift, $config{fnt_cat1})}
	elsif ($config{fnt_c2} eq 'ON')  {$fl = Recodenc::font(shift, $config{fnt_cat1}, $config{fnt_cat2})}
	proc_fl($fl);
	return 0;
}

# Конвертирование файлов локализации мода-сейва из CK2 в EU4
sub w_recodenc_modexport {
	&win_busy();
	my $fl;
	if    ($config{cnv_c2} eq 'OFF') {$fl = Recodenc::modexport(shift, $config{cnv_cat1})}
	elsif ($config{cnv_c2} eq 'ON')  {$fl = Recodenc::modexport(shift, $config{cnv_cat1}, $config{cnv_cat2})}
	proc_fl($fl);
	return 0;
}

# Конвертирование файлов простого текста из UTF8 в CP1252CYR
sub w_recodenc_plaintext {
	&win_busy();
	my $fl;
	if    ($config{ptx_c2} eq 'OFF') {$fl = Recodenc::plaintext(shift, $config{ptx_cat1})}
	elsif ($config{ptx_c2} eq 'ON')  {$fl = Recodenc::plaintext(shift, $config{ptx_cat1}, $config{ptx_cat2})}
	proc_fl($fl);
	return 0;
}

# функция чтения конфигурационного файла
sub config_read { # TODO: оптимизировать
	my $file = shift;
	my %cfg = (
		page => '',
		eu4_c2 => '',
		eu4_cat1 => '',
		eu4_cat2 => '',
		eu4l_origru => '',
		eu4l_origen => '',
		eu4l_saveru => '',
		eu4d_dlc => '',
		eu4d_dst => '',
		ck2_c2 => '',
		ck2_cat1 => '',
		ck2_cat2 => '',
		ck2l_origru => '',
		ck2l_origen => '',
		ck2l_saveru => '',
		fnt_c2 => '',
		fnt_cat1 => '',
		fnt_cat2 => '',
		cnv_c2 => '',
		cnv_cat1 => '',
		cnv_cat2 => '',
		ptx_c2 => '',
		ptx_cat1 => '',
		ptx_cat2 => ''
	);
	open(my $cfh, '<:unix:perlio:encoding(utf-8)', $file);
	while (my $cstr = <$cfh>) {
		chomp $cstr;
		if ($cstr =~ m/^$/ or $cstr =~ /^\#/) {next}
		my @cstr = split m/:/, $cstr, 2;
		if (defined($cfg{$cstr[0]})) {$cfg{$cstr[0]} = $cstr[1]}
	}
	close $cfh;
	# проверка страницы
	if (looks_like_number($cfg{page})) {
		if ($cfg{page} < 0 and $cfg{page} > 5) {$cfg{page} = 0}
	}
	else {$cfg{page} = 0}
	# проверка флагов
	unless ($cfg{eu4_c2} eq 'ON' or $cfg{eu4_c2} eq 'OFF') {$cfg{eu4_c2} = 'OFF'};
	unless ($cfg{ck2_c2} eq 'ON' or $cfg{ck2_c2} eq 'OFF') {$cfg{ck2_c2} = 'OFF'};
	unless ($cfg{fnt_c2} eq 'ON' or $cfg{fnt_c2} eq 'OFF') {$cfg{fnt_c2} = 'OFF'};
	unless ($cfg{cnv_c2} eq 'ON' or $cfg{cnv_c2} eq 'OFF') {$cfg{cnv_c2} = 'OFF'};
	unless ($cfg{ptx_c2} eq 'ON' or $cfg{ptx_c2} eq 'OFF') {$cfg{ptx_c2} = 'OFF'};
	# возвращение хэша с настройками
	return %cfg;
}

# функция записи конфигурационного файла
sub config_write {
	my $file = shift;
	my $cnhs = shift;
	open(my $cfh, '>:unix:perlio:encoding(utf-8)', $file);
	for my $key (sort keys %config) {print $cfh "$key:$config{$key}\n"}
	close $cfh;
}

sub w_config_write {
	print 'Запись конфигурационного файла ... ';
	&config_write(encode('locale_fs', $conf_path_file), %config);
	print "ok\n";
}

# функция обработки ошибок
sub proc_fl {
	if    ($_[0] == 0) {win_unbusy()}
	elsif ($_[0] == $Recodenc::FL_SRC_DIR_NOT_FOUND) {win_unbusy("Каталог с исходными данными не найден!")}
	elsif ($_[0] == $Recodenc::FL_DST_DIR_NOT_FOUND) {win_unbusy("Каталог для сохранения не найден!")}
	elsif ($_[0] == $Recodenc::FL_SRCEN_DIR_NOT_FOUND) {win_unbusy("Не найден каталог с английской локализацией!")}
	elsif ($_[0] == $Recodenc::FL_SRCRU_DIR_NOT_FOUND) {win_unbusy("Не найден каталог с русской локализацией!")}
	elsif ($_[0] == $Recodenc::FL_DSTRU_DIR_NOT_FOUND) {win_unbusy("Не найден каталог для сохранения локализации!")}
	elsif ($_[0] == $Recodenc::FL_SRC_AND_DST_DIR_ARE_THE_SAME) {win_unbusy("Каталог с исходными данными и каталог назначения совпадают!")}
	else {win_unbusy("Неизвестный код ошибки: $_[0]")}
}

################################################################################
# Подпрограммы поддержки графического интерфейса
#
sub prockeys {
# Обрабатывает клавиатурные комбинации
	my (undef, $k) = @_;
	return &action_close if $k == K_cQ; # Ctrl+Q
	return &action_shorthelp if $k == K_F1; # F1
	return IUP_DEFAULT;
}

sub action_close {
# Вызывает выход из главного цикла обработки событий
	return IUP_CLOSE
}

sub seldir {
#Вызывает диалог выбора каталога и записывает выбранное значение в переменную с именем каталога
#параметр: ссылка на переменную, в которую записывать значение
	my $fd = IUP::FileDlg->new(DIALOGTYPE => 'DIR');
	$fd->Popup(IUP_CENTER, IUP_CENTER);
	if ($fd->STATUS == 0) {
		shift->SetAttribute(VALUE => $fd->VALUE);
		my $cf = shift;
		$$cf = $fd->VALUE;
	}
	return IUP_DEFAULT;
}

sub save_page_raised {
#Сохраняет в переменную текущую открытую вкладку
	(undef, $config{page}, undef) = @_;
	return IUP_DEFAULT;
}

sub win_busy {
#Занять окно
	$status->SetAttribute(TITLE => 'Обработка ...');
	$mw->SetAttribute(ACTIVE => 'NO');
	$mw->UpdateChildren;
	IUP->Flush;
}

sub win_unbusy {
#Вернуть управление окном пользователю
	my $cstr = shift;
	$mw->SetAttribute(ACTIVE => 'YES');
	if   (defined($cstr)) {$status->SetAttribute(TITLE => $cstr)}
	else                  {$status->SetAttribute(TITLE => 'Готово!')}
}

sub action_shorthelp {
my $label = IUP::Label->new(TITLE => <<'END', PADDING => $LABEL_PADDING);
Структура графического интерфейса программы:
	вкладки определяют формат, с которым работаем
	виджеты на вкладках — что с ними можно сделать
Форматы:
	EU4(Lite) — каталог /localisation/*.yml
	EU4Dlc — каталог /dlc/*.zip
	CK2(Lite) — каталог /localisation/*.csv
	Шрифт — каталог с файлами *.fnt
	Мод сохранения — каталог /localisation/*.yml
	Простой текст — каталог с текстовыми файлами. Расширение не проверяется — берутся все подряд.
В конце пути не должно быть косой черты/обратной косой черты!
Кодировать — перевести в указанную кодировку из UTF-8.
Декодировать — перевести из указанной кодировки в UTF-8.
END
	my $btn = IUP::Button->new(TITLE => 'Ok', EXPAND => 'HORIZONTAL');
	my $d = IUP::Dialog->new(
		TITLE => 'Краткая справка',
		ICON => $window_icon_16x16,
		child =>
			IUP::Vbox->new(child => [$label, $btn])
	);
	$btn->ACTION(sub{$d->Destroy()});
	$d->ShowXY(IUP_CENTER, IUP_CENTER);
}

sub action_translittable {
# Показывает таблицу транслитерации
	my $label = IUP::Label->new(TITLE => <<'END', PADDING => $LABEL_PADDING);
а — Aa	я — Ää
о — Oo	ё — Ëë
у — Uu	ю — Üü
э — Êê	е — Ee
ы — Îî	и — Ii

б — Bb	в — Vv
г — Gg	д — Dd
ж — Jj	з — Zz
й — Yy	к — Kk
л — Ll	м — Mm
н — Nn	п — Pp
р — Rr	с — Ss
т — Tt	ф — Ff
х — Hh	ц — Qq
ч — Cc	ш — Xx
щ — Çç	ъ — ’
ь — Yy
END
	my $btn = IUP::Button->new(TITLE => 'Ok', EXPAND => 'HORIZONTAL');
	my $d = IUP::Dialog->new(
		TITLE => 'Таблица транслитерации',
		ICON => $window_icon_16x16,
		child =>
			IUP::Vbox->new(child => [$label, $btn])
	);
	$btn->ACTION(sub{$d->Destroy()});
	$d->ShowXY(IUP_CENTER, IUP_CENTER);
	return IUP_DEFAULT;
}

sub action_about {
#Вывести сообщение о программе
	my $label = IUP::Text->new(
		MULTILINE => 'YES',
		SCROLLBAR => 'VERTICAL',
		EXPAND => 'YES',
		VISIBLELINES => 19,
		VISIBLECOLUMNS => 40,
		VALUE => <<"END");
Recodenc
Версия: $VERSION
Copyright © 2016-2017 terqüéz <gz0\@ro.ru>
Ресурсы для разработчиков и справка:
https://github.com/chomobi/recodenc

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
END
	$label->READONLY('YES');
	my $btn = IUP::Button->new(TITLE => 'Ok', EXPAND => 'HORIZONTAL');
	my $d = IUP::Dialog->new(
		TITLE => 'О программе',
		ICON => $window_icon_16x16,
#		RESIZE => 'NO',
		child =>
			IUP::Vbox->new(child => [$label, $btn])
	);
	$btn->ACTION(sub{$d->Destroy()});
	$d->ShowXY(IUP_CENTER, IUP_CENTER);
	return IUP_DEFAULT;
}

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
use utf8;
use v5.18;
use warnings;
use integer;
use vars qw(
	$PROGNAME
	$VERSION
	$ACTION_ENCODE
	$ACTION_DECODE
	$ACTION_TRANSLIT
	$ACTION_TAGS
	$ACTION_CLEAN
	$HV_HELP
	$HV_VERSION
	);
use Getopt::Long qw(:config bundling_values gnu_compat no_auto_abbrev no_ignore_case prefix_pattern=--|- long_prefix_pattern=--);
use Recodenc;
use Encode qw(encode decode);
use Encode::Locale;
binmode(STDIN, ":encoding(console_in)");
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");
@ARGV = map {decode('locale', $_)} @ARGV;

*PROGNAME = \'Recodenc';
*VERSION  = \'0.6.0';
*ACTION_ENCODE = \1;
*ACTION_DECODE = \2;
*ACTION_TRANSLIT = \3;
*ACTION_TAGS = \4;
*ACTION_CLEAN = \5;
*HV_HELP = \1;
*HV_VERSION = \2;

my $mode = 'e';
my $actn = $ACTION_ENCODE;
my $encoding = 'cp1252cyreu4';
my $hv = 0;
my @dirs;

GetOptions('m|mode=s' => \$mode,
           'n|encode' => sub{$actn = $ACTION_ENCODE},
           'd|decode' => sub{$actn = $ACTION_DECODE},
           't|translit' => sub{$actn = $ACTION_TRANSLIT},
           'e|encoding=s' => \$encoding,
           'g|tags' => sub{$actn = $ACTION_TAGS},
           'c|clean' => sub{$actn = $ACTION_CLEAN},
           'h|help' => sub{$hv = $HV_HELP},
           'v|version' => sub{$hv = $HV_VERSION}) or die("Ошибка в аргументах командной строки!\n");

if    ($hv == $HV_HELP) {&help(); exit(0)}
elsif ($hv == $HV_VERSION) {&version(); exit(0)}

@dirs = @ARGV;

if    ($mode eq 'e' or $mode eq 'eu4') {
	proc_fl(Recodenc::l10n_eu4(det_enc('eu4'), @dirs));
}
elsif ($mode eq 'l' or $mode eq 'eu4l') {
	if ($actn != $ACTION_TAGS) {
		proc_fl(Recodenc::l10n_eu4_lite(det_enc('eu4'), @dirs));
	}
	elsif ($actn == $ACTION_TAGS) {
		proc_fl(Recodenc::l10n_eu4_tags(@dirs));
	}
}
elsif ($mode eq 'd' or $mode eq 'eu4d') {
	proc_fl(Recodenc::l10n_eu4_dlc(@dirs));

}
elsif ($mode eq 'c' or $mode eq 'ck2') {
	proc_fl(Recodenc::l10n_ck2(det_enc('ck2'), @dirs));
}
elsif ($mode eq 'k' or $mode eq 'ck2l') {
	if ($actn != $ACTION_TAGS) {
		proc_fl(Recodenc::l10n_ck2_lite(det_enc('ck2'), @dirs));
	}
	if ($actn == $ACTION_TAGS) {
		proc_fl(Recodenc::l10n_ck2_tags(@dirs));
	}
}
elsif ($mode eq 'f' or $mode eq 'fnt') {
	proc_fl(Recodenc::font(det_enc(), @dirs));
}
elsif ($mode eq 'm' or $mode eq 'cnv') {
	proc_fl(Recodenc::modexport(det_enc('eu4'), @dirs));
}
elsif ($mode eq 't' or $mode eq 'ptx') {
	proc_fl(Recodenc::plaintext(det_enc(), @dirs));
}
exit(0);
################################################################################
# СЕРВИСНЫЕ ФУНКЦИИ
################################################################################
# Определение кодировки
sub det_enc {
	my $gam = shift; # игра: eu4 — EU4, ck2 — CK2
	if    ($actn == $ACTION_ENCODE) {
		if    ($encoding eq 'cp1251') {
			return $Recodenc::ENC_CP1251;
		}
		elsif ($encoding eq 'cp1252cyreu4') {
			if ($gam eq 'ck2') {
				die "Задана неверная локализация кодировки CP1252CYR.\n";
			}
			else {
				return $Recodenc::ENC_CP1252CYREU4;
			}
		}
		elsif ($encoding eq 'cp1252cyrck2') {
			if ($gam eq 'eu4') {
				die "Задана неверная локализация кодировки CP1252CYR.\n";
			}
			else {
				return $Recodenc::ENC_CP1252CYRCK2;
			}
		}
		elsif ($encoding eq 'cp1252cyr') {
			if    ($gam eq 'eu4') {
				return $Recodenc::ENC_CP1252CYREU4;
			}
			elsif ($gam eq 'ck2') {
				return $Recodenc::ENC_CP1252CYRCK2;
			}
			else {
				die "CP1252CYR без указания движка игры в недопустимом месте.\n";
			}
		}
		else {
			die "Не получилось определить кодировку для операции кодирования.\n";
		}
	}
	elsif ($actn == $ACTION_DECODE) {
		if    ($encoding eq 'cp1251') {
			return $Recodenc::DEC_CP1251;
		}
		elsif ($encoding eq 'cp1252cyreu4') {
			if ($gam eq 'ck2') {
				die "Задана неверная локализация кодировки CP1252CYR.\n";
			}
			else {
				return $Recodenc::DEC_CP1252CYREU4;
			}
		}
		elsif ($encoding eq 'cp1252cyrck2') {
			if ($gam eq 'eu4') {
				die "Задана неверная локализация кодировки CP1252CYR.\n";
			}
			else {
				return $Recodenc::DEC_CP1252CYRCK2;
			}
		}
		elsif ($encoding eq 'cp1252cyr') {
			if    ($gam eq 'eu4') {
				return $Recodenc::DEC_CP1252CYREU4;
			}
			elsif ($gam eq 'ck2') {
				return $Recodenc::DEC_CP1252CYRCK2;
			}
			else {
				die "CP1252CYR без указания движка игры в недопустимом месте.\n";
			}
		}
		else {
			die "Не получилось определить кодировку для операции декодирования.\n";
		}
	}
	elsif ($actn == $ACTION_TRANSLIT) {
		return $Recodenc::ENC_TRANSLIT;
	}
	elsif ($actn == $ACTION_CLEAN) {
		return $Recodenc::ENC_NULL;
	}
	else {
		die "Не получилось определить кодировку.\n";
	}
}
# Обработка ошибок
sub proc_fl {
	if    ($_[0] == 0) {return 0}
	elsif ($_[0] == $Recodenc::FL_SRC_DIR_NOT_FOUND) {die "Каталог с исходными данными не найден!\n"}
	elsif ($_[0] == $Recodenc::FL_DST_DIR_NOT_FOUND) {die "Каталог для сохранения не найден!\n"}
	elsif ($_[0] == $Recodenc::FL_SRCEN_DIR_NOT_FOUND) {die "Не найден каталог с английской локализацией!\n"}
	elsif ($_[0] == $Recodenc::FL_SRCRU_DIR_NOT_FOUND) {die "Не найден каталог с русской локализацией!\n"}
	elsif ($_[0] == $Recodenc::FL_DSTRU_DIR_NOT_FOUND) {die "Не найден каталог для сохранения локализации!\n"}
	elsif ($_[0] == $Recodenc::FL_SRC_AND_DST_DIR_ARE_THE_SAME) {die "Каталог с исходными данными и каталог назначения совпадают!\n"}
	else {die "Неизвестный код ошибки: $_[0]\n"}
}
################################################################################
# ФУНКЦИИ ПОДДЕРЖКИ ИНТЕРФЕЙСА КОМАНДНОЙ СТРОКИ
################################################################################
sub help {
print <<'EOT';
Использование: recodenc [КЛЮЧ_РЕЖИМА КЛЮЧИ]... КАТАЛОГ [КАТАЛОГИ]...
          или: recodenc -h
          или: recodenc --help
          или: recodenc -v
          или: recodenc --version
Преобразует текстовые файлы специального формата в каталогах (изменяя
исходные файлы или создавая файлы для обработанного содержания в
каталоге назначения). Короткие ключи допускается объединять с данными,
например: -me -ecp1251. Параметры, обязательные для длинных опций,
обязательны и для коротких. Вертикальная черта означает "ИЛИ".
При указании каталогов в конце не должно быть косой черты.

-m e|l|d|c|k|f|m|t
--mode=eu4|eu4l|eu4d|ck2|ck2l|fnt|cnv|ptx
                   Устанавливает режим обработки файлов.
                   e eu4  EU4 (по умолчанию)
                   l eu4l EU4Lite Сборка лёгкой версии локализации
                   d eu4d EU4Dlc  Извлечение локализации из DLC
                   c ck2  CK2
                   k ck2l CK2Lite Сборка лёгкой версии локализации
                   f fnt  FNT     Шрифт
                   m cnv  CNV     Мод сохранения
                   t ptx  PTX     Простой текст
                   Короткие режимы можно указывать в длинном параметре
                   и наоборот.
-n, --encode       Кодировать. (по умолчанию)
-d, --decode       Декодировать.
-t, --translit     Транслитерировать.
-e, --encoding=cp1252cyr|cp1252cyreu4|cp1252cyrck2|cp1251
                   Устанавливает кодировку.
                   По умолчанию cp1252cyreu4.
-g, --tags         Тэгы.
-c, --clean        Очистить.
-h, --help         Показать этот текст и завершить выполнение.
-v, --version      Показать версию и завершить выполнение.

Указание суффикса игры в кодировке cp1252cyr обязательно только для
режима преобразования шрифтов. В остальных режимах он не учитывается.
За один запуск обрабатывается только один исходный каталог (вложенные
не поддерживаются, как и отдельные файлы).

Режим EU4
Действия: -n|-d|-t. Транслитерация указания кодировки не требует.
Кодировки: cp1251, cp1252cyr.
При указании одного каталога изменяются файлы в нём. При указании двух
каталогов файлы читаются из первого каталога и сохраняются во втором.
Остальные каталоги отбрасываются.

Режим EU4Lite
Действия: -n|-t|-g.
Кодировки: cp1251, cp1252cyr.
Требуется указание трёх каталогов:
  1) Каталог с оригинальной английской локализацией.
  2) Каталог с русской локализацией.
  3) Каталог для сохранения результирующей локализации.
Остальные каталоги отбрасываются.

Режим EU4Dlc
Требуется указание двух каталогов:
  1) Каталог с zip-архивами DLC.
  2) Каталог для сохранения извлечённой локализации.
Остальные каталоги отбрасываются.

Режим CK2
Действия: -n|-d|-t. Транслитерация указания кодировки не требует.
Кодировки: cp1251, cp1252cyr.
При указании одного каталога изменяются файлы в нём. При указании двух
каталогов файлы читаются из первого каталога и сохраняются во втором.
Остальные каталоги отбрасываются.

Режим CK2Lite
Действия: -n|-t|-g.
Кодировки: cp1251, cp1252cyr.
Требуется указание трёх каталогов:
  1) Каталог с оригинальной английской локализацией.
  2) Каталог с русской локализацией.
  3) Каталог для сохранения результирующей локализации.
Остальные каталоги отбрасываются.

Режим FNT
Действия: -с|-e. Указание кодировки означает обработку указанной
кодировки. Указывать кодировку CP1252CYR следует с суффиксом игры,
например: cp1252cyrck2.
При указании одного каталога изменяются файлы в нём. При указании двух
каталогов файлы читаются из первого каталога и сохраняются во втором.
Остальные каталоги отбрасываются.

Режим CNV
Кодировки: cp1251, cp1252cyr. Указание кодировки обязательно.
При указании одного каталога изменяются файлы в нём. При указании двух
каталогов файлы читаются из первого каталога и сохраняются во втором.
Остальные каталоги отбрасываются.

Режим PTX
Действия: -n|-d|-t. Транслитерация указания кодировки не требует.
Кодировки: cp1251, cp1252cyrck2, cp1252cyreu4.
При указании одного каталога изменяются файлы в нём. При указании двух
каталогов файлы читаются из первого каталога и сохраняются во втором.
Остальные каталоги отбрасываются.

Copyright (C) 2016-2017 terquez <gz0@ro.ru>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOT
}

sub version {
print <<"EOT";
Recodenc $VERSION
Copyright (C) 2016-2017 terquez <gz0\@ro.ru>
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOT
}

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
@ARGV = map {decode('console_in', $_)} @ARGV;

*PROGNAME = \'Recodenc';
*VERSION  = \'0.5.0';
*ACTION_ENCODE = \1;
*ACTION_DECODE = \2;
*ACTION_TRANSLIT = \3;
*ACTION_TAGS = \4;
*ACTION_CLEAN = \5;
*HV_HELP = \1;
*HV_VERSION = \2;

my $mode = 'eu4';
my $actn = $ACTION_ENCODE;
my $encoding = 'cp1252+cyr-eu4';
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
	# объявление локальных переменных
	my $fl;
	my $encoding_local;
	# разрешение кодировки
	if ($actn == $ACTION_ENCODE or $actn == $ACTION_DECODE) {
		if    (!defined($encoding)) {die 'Кодировка не задана!'}
		elsif ($encoding =~ m/^cp1252\+cyr/) {$encoding_local = 'cp1252pcyr'}
		elsif ($encoding eq 'cp1251')        {$encoding_local = 'cp1251'}
	}
	if ($actn == $ACTION_DECODE) {$encoding_local = "d_$encoding_local"}
	if ($actn == $ACTION_TRANSLIT) {$encoding_local = 'translit'}
	# запуск функции
	if (scalar(@dirs) > 1) {
		$fl = Recodenc::eu4_l10n($encoding_local, 1, $dirs[0], $dirs[1])
	}
	elsif (scalar(@dirs) == 1) {
		$fl = Recodenc::eu4_l10n($encoding_local, 0, $dirs[0], '')
	}
	else {
		die "Каталог для обработки не задан!"
	}
	# обработка ошибок
	if    ($fl == $Recodenc::FL_EU4_SRC_DIR_NOT_FOUND) {die 'Каталог с исходными данными не найден!'}
	elsif ($fl == $Recodenc::FL_EU4_DST_DIR_NOT_FOUND) {die 'Каталог для сохранения не найден!'}
	elsif ($fl == $Recodenc::FL_SRC_AND_DST_DIR_ARE_THE_SAME) {die 'Каталог с исходными данными и каталог назначения совпадают!'}
}
elsif ($mode eq 'c' or $mode eq 'ck2') {
	# объявление локальных переменных
	my $fl;
	my $encoding_local;
	# разрешение кодировки и запуск функции
	if ($actn == $ACTION_ENCODE or $actn == $ACTION_TRANSLIT) {
		if ($actn == $ACTION_ENCODE) {
			if ($encoding =~ m/^cp1252\+cyr/) {$encoding_local = 'cp1252pcyr'}
		}
		if ($actn == $ACTION_TRANSLIT) {$encoding_local = 'translit'}
		$fl = Recodenc::ck2_l10n($encoding_local, @dirs);
	}
	if ($actn == $ACTION_TAGS) {
		$fl = Recodenc::ck2_l10n_tags(@dirs);
	}
	# обработка ошибок
	if    ($fl == $Recodenc::FL_CK2_SRCEN_DIR_NOT_FOUND) {die 'Не найден каталог с английской локализацией!'}
	elsif ($fl == $Recodenc::FL_CK2_SRCRU_DIR_NOT_FOUND) {die 'Не найден каталог с русской локализацией!'}
	elsif ($fl == $Recodenc::FL_CK2_DSTRU_DIR_NOT_FOUND) {die 'Не найден каталог для сохранения локализации!'}
	elsif ($fl == $Recodenc::FL_SRC_AND_DST_DIR_ARE_THE_SAME) {die 'Каталог с исходными данными и каталог назначения совпадают!'}
}
elsif ($mode eq 'f' or $mode eq 'fnt') {
	# объявление локальных переменных
	my $fl;
	my $encoding_local;
	# разрешение кодировки
	if    ($actn == $ACTION_CLEAN) {$encoding_local = 0}
	elsif (defined($encoding)) {
		if    ($encoding eq 'cp1252+cyr-eu4') {$encoding_local = 'eu4'}
		elsif ($encoding eq 'cp1252+cyr-ck2') {$encoding_local = 'ck2'}
		elsif ($encoding eq 'cp1251') {$encoding_local = 'cp1251'}
	}
	# запуск функции
	if (scalar(@dirs) > 1) {
		$fl = Recodenc::eu4ck2_font($encoding_local, 1, $dirs[0], $dirs[1]);
	}
	elsif (scalar(@dirs) == 1) {
		$fl = Recodenc::eu4ck2_font($encoding_local, 0, $dirs[0], '');
	}
	else {
		die "Каталог для обработки не задан!"
	}
	# обработка ошибок
	if    ($fl == $Recodenc::FL_FNT_SRC_DIR_NOT_FOUND) {die 'Каталог с исходными данными не найден!'}
	elsif ($fl == $Recodenc::FL_FNT_DST_DIR_NOT_FOUND) {die 'Каталог для сохранения не найден!'}
	elsif ($fl == $Recodenc::FL_SRC_AND_DST_DIR_ARE_THE_SAME) {die 'Каталог с исходными данными и каталог назначения совпадают!'}
}
elsif ($mode eq 'm' or $mode eq 'cnv') {
	# объявление локальных переменных
	my $fl;
	my $encoding_local;
	# разрешение кодировки
	if    ($encoding =~ m/^cp1252\+cyr/) {$encoding_local = 'cp1252pcyr'}
	elsif ($encoding eq 'cp1251')        {$encoding_local = 'cp1251'}
	# запуск функции
	if (scalar(@dirs) > 1) {
		$fl = Recodenc::ck2_to_eu4_modsave($encoding_local, 1, $dirs[0], $dirs[1]);
	}
	elsif (scalar(@dirs) == 1) {
		$fl = Recodenc::ck2_to_eu4_modsave($encoding_local, 0, $dirs[0], '');
	}
	else {
		die "Каталог для обработки не задан!"
	}
	# обработка ошибок
	if    ($fl == $Recodenc::FL_CNV_SRC_DIR_NOT_FOUND) {die 'Каталог с исходными данными не найден!'}
	elsif ($fl == $Recodenc::FL_CNV_DST_DIR_NOT_FOUND) {die 'Каталог для сохранения не найден!'}
	elsif ($fl == $Recodenc::FL_SRC_AND_DST_DIR_ARE_THE_SAME) {die 'Каталог с исходными данными и каталог назначения совпадают!'}
}
elsif ($mode eq 't' or $mode eq 'ptx') {
	# объявление локальных переменных
	my $fl;
	# запуск функции
	if (scalar(@dirs) > 1) {
		$fl = Recodenc::plaintext(1, $dirs[0], $dirs[1]);
	}
	elsif (scalar(@dirs) == 1) {
		$fl = Recodenc::plaintext(0, $dirs[0], '');
	}
	else {
		die "Каталог для обработки не задан!"
	}
	# обработка ошибок
	if    ($fl == $Recodenc::FL_PTX_SRC_DIR_NOT_FOUND) {die 'Каталог с исходными данными не найден!'}
	elsif ($fl == $Recodenc::FL_PTX_DST_DIR_NOT_FOUND) {die 'Каталог для сохранения не найден!'}
	elsif ($fl == $Recodenc::FL_SRC_AND_DST_DIR_ARE_THE_SAME) {die 'Каталог с исходными данными и каталог назначения совпадают!'}
}
exit(0);
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

-m e|c|f|m|t
--mode=eu4|ck2|fnt|cnv|ptx
                   Устанавливает режим обработки файлов.
                   e eu4 EU4 (по умолчанию)
                   c ck2 CK2
                   f fnt FNT Шрифт
                   m cnv CNV Мод сохранения
                   t ptx PTX Простой текст
                   Короткие режимы можно указывать в длинном параметре
                   и наоборот.
-n, --encode       Кодировать. (по умолчанию)
-d, --decode       Декодировать.
-t, --translit     Транслитерировать.
-e, --encoding=cp1252+cyr|cp1252+cyr-eu4|cp1252+cyr-ck2|cp1251
                   Устанавливает кодировку.
                   По умолчанию cp1252+cyr-eu4.
-g, --tags         Тэгы.
-c, --clean        Очистить.
-h, --help         Показать этот текст и завершить выполнение.
-v, --version      Показать версию и завершить выполнение.

Указание суффикса игры в кодировке cp1252+cyr обязательно только для
режима преобразования шрифтов. В остальных режимах он не учитывается.
За один запуск обрабатывается только один исходный каталог (вложенные
не поддерживаются, как и отдельные файлы). 

Режим EU4
Действия: -n|-d|-t. Транслитерация указания кодировки не требует.
Кодировки: cp1251, cp1252+cyr.
При указании одного каталога изменяются файлы в нём. При указании двух
каталогов файлы читаются из первого каталога и сохраняются во втором.
Остальные каталоги отбрасываются.

Режим CK2
Действия: -n|-t|-g. Указание кодировки не требуется.
Требуется указание трёх каталогов:
  1) Каталог с оригинальной английской локализацией.
  2) Каталог с русской локализацией.
  3) Каталог для сохранения результирующей локализации.
Остальные каталоги отбрасываются.

Режим FNT
Действия: -с|-e. Указание кодировки означает обработку указанной
кодировки. Указывать кодировку CP1252+CYR следует с суффиксом игры,
например: cp1252+cyr-ck2.
При указании одного каталога изменяются файлы в нём. При указании двух
каталогов файлы читаются из первого каталога и сохраняются во втором.
Остальные каталоги отбрасываются.

Режим CNV
Указание кодировки обязательно.
При указании одного каталога изменяются файлы в нём. При указании двух
каталогов файлы читаются из первого каталога и сохраняются во втором.
Остальные каталоги отбрасываются.

Режим PTX
Указание ключей не требуется.
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

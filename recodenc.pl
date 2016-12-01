#!/usr/bin/perl
################################################################################
# Recodenc
# Copyright © 2015-2016 terqüéz <gz0@ro.ru>
#
# This program is free software: you can redistribute it and/or modify
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
# закрытие окна терминала в windows
BEGIN {
	if ($^O eq 'MSWin32') {
		require Win32::Console;
		Win32::Console::Free();
	}
}

use utf8;
use v5.18;
use warnings;
use Tkx;
use Encode qw(encode decode);
use Encode::Locale;
binmode(STDIN, ":encoding(console_in)");
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");

my $version = '0.4.1';
my $status = ''; # переменная для вывода статуса
# Опции конфигурационного файла:
#	page — идентификатор поднятой страницы 0..3
#	eu4_c2 — 0 = не сохранять в др. каталог; 1 = сохранять
#	eu4_cat1 — каталог №1
#	eu4_cat2 — каталог №2
#	ck2_origru — каталог с русской локализацией CK2 (Full)
#	ck2_origen — каталог с английской локализацией CK2
#	ck2_saveru — каталог для сохранения скомпилированной Lite-локализации
#	fnt_c2 — 0 = не сохранять в др. каталог; 1 = сохранять
#	fnt_cat1 — каталог шрифтов №1
#	fnt_cat2 — каталог шрифтов №2
#	cnv_c2 — 0 = не сохранять в др. каталог; 1 = сохранять
#	cnv_cat1 — каталог №1 для обработки конвертором мода сохранений
#	cnv_cat2 — каталог №2
## загрузка конфигурации
my $conf_path_dir; # имя каталога файла конфигурации
my $conf_path_dir_encoded; # имя каталога файла конфигурации в кодировке локальной машины
my $conf_path_file; # имя файла конфигурации
my $conf_path_file_encoded; # имя файла конфигурации в кодировке локальной машины
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
$conf_path_dir_encoded = encode('locale_fs', $conf_path_dir);
unless (-d $conf_path_dir_encoded) {
	mkdir $conf_path_dir_encoded or die "Не удалось создать каталог: $conf_path_dir\n";
}
$conf_path_file = "$conf_path_dir/recodenc.conf";
$conf_path_file_encoded = encode('locale_fs', $conf_path_file);
my %config = &config_read($conf_path_file_encoded);
# проверка загруженной конфигурации
for my $key (sort keys %config) {
	unless ($key eq 'page' or
	        $key eq 'eu4_c2' or
	        $key eq 'eu4_cat1' or
	        $key eq 'eu4_cat2' or
	        $key eq 'ck2_origru' or
	        $key eq 'ck2_origen' or
	        $key eq 'ck2_saveru' or
	        $key eq 'fnt_c2' or
	        $key eq 'fnt_cat1' or
	        $key eq 'fnt_cat2' or
	        $key eq 'cnv_c2' or
	        $key eq 'cnv_cat1' or
	        $key eq 'cnv_cat2') {
		delete($config{$key});
	}
	unless (defined($config{$key})) {$config{$key} = ''} # инициализация пустыми значениями
}
if (! defined($config{page})) {$config{page} = 0}
elsif ($config{page} < 0 and $config{page} > 3) {$config{page} = 0}
if (! defined($config{eu4_c2})) {$config{eu4_c2} = 0}
elsif ($config{eu4_c2} != 0 and $config{eu4_c2} != 1) {$config{eu4_c2} = 0}
if (! defined($config{fnt_c2})) {$config{fnt_c2} = 0}
elsif ($config{fnt_c2} != 0 and $config{fnt_c2} != 1) {$config{fnt_c2} = 0}
if (! defined($config{cnv_c2})) {$config{cnv_c2} = 0}
elsif ($config{cnv_c2} != 0 and $config{cnv_c2} != 1) {$config{cnv_c2} = 0}
## рисование интерфейса
# инициализация переменных для хранения указателей на элементы интерфейса
my $mw; # главное окно
my $menu; # панель меню
my $menu_file; # меню файл
my $menu_help; # меню помощи
my $frame_notebook; # фрейм, содержащий вкладки
my $page_eu4; # вкладка EU4
my $page_ck2; # вкладка CK2
my $page_fnt; # вкладка шрифт
my $page_cnv; # вкладка сохранений
my $frame_eu4_buttons; # фрейм с кнопками действий для перекодировки
my $frame_eu4_buttons2;
my $frame_ck2_buttons; # фрейм с кнопками
my $frame_fnt_buttons; # фрейм кнопки действия
my $frame_cnv_buttons; # фрейм кнопок
my $frame_buttons; # фрейм с кнопкой «закрыть»

# создание корневого окна
$mw = Tkx::widget -> new('.');
$mw -> g_wm_title("Recodenc v$version");
	# меню
	Tkx::option_add('*tearOff', 0);
	$menu = $mw -> new_menu();
	$mw -> m_configure(-menu => $menu);
		# меню «Файл»
		$menu_file = $menu -> new_menu();
		$menu -> m_add_cascade(-label => 'Файл', -menu => $menu_file);
		$menu_file -> m_add_command(-label => 'Выход', -command => sub{$mw -> g_destroy()}, -accelerator => 'Ctrl+Q');
		# меню «Справка»
		$menu_help = $menu -> new_menu();
		$menu -> m_add_cascade(-label => 'Справка', -menu => $menu_help);
		$menu_help -> m_add_command(-label => 'Краткая справка', -command => \&helpwindow);
		$menu_help -> m_add_command(-label => 'Таблица транслитерации', -command => \&translittable);
		$menu_help -> m_add_separator();
		$menu_help -> m_add_command(-label => 'О программе', -command => \&menu_about);
		$menu_help -> m_add_command(-label => 'Лицензия', -command => \&menu_license);
	# вкладки
	$frame_notebook = $mw -> new_ttk__notebook();
	$frame_notebook -> g_grid(-column => 0, -row => 0, -sticky => 'nsew');
	# вкладка EU4
	$page_eu4 = $mw -> new_ttk__frame();
	$frame_notebook -> m_add($page_eu4, -text => 'EU4', -sticky => 'nsew');
		# каталог №1
		$page_eu4 -> new_ttk__label(-text => 'Для обработки:') -> g_grid(-column => 0, -row => 0, -sticky => 'w');
		$page_eu4 -> new_ttk__entry(-width => 50, -textvariable => \$config{eu4_cat1}) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$page_eu4 -> new_ttk__button(-text => 'Выбрать каталог', -command => [\&seldir, \$config{eu4_cat1}]) -> g_grid(-column => 2, -row => 0, -sticky => 'e');
		# каталог №2
		$page_eu4 -> new_ttk__checkbutton(-text => 'Сохранить в:', -variable => \$config{eu4_c2}) -> g_grid(-column => 0, -row => 1, -sticky => 'w');
		$page_eu4 -> new_ttk__entry(-width => 50, -textvariable => \$config{eu4_cat2}) -> g_grid(-column => 1, -row => 1, -sticky => 'ew');
		$page_eu4 -> new_ttk__button(-text => 'Выбрать каталог', -command => [\&seldir, \$config{eu4_cat2}]) -> g_grid(-column => 2, -row => 1, -sticky => 'e');
		# кнопки
		$frame_eu4_buttons = $page_eu4 -> new_ttk__frame();
		$frame_eu4_buttons -> g_grid(-column => 0, -columnspan => 3, -row => 2, -sticky => 'ew');
		$frame_eu4_buttons -> new_ttk__button(-text => 'Кодировать (CP1251)', -command => [\&encodelocalisation_eu4, 'cp1251']) -> g_grid(-column => 0, -row => 0, -sticky => 'ew');
		$frame_eu4_buttons -> new_ttk__button(-text => 'Кодировать (CP1252+CYR)', -command => [\&encodelocalisation_eu4, 'cp1252pcyr']) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$frame_eu4_buttons -> new_ttk__button(-text => 'Транслитерировать', -command => [\&encodelocalisation_eu4, 'translit']) -> g_grid(-column => 2, -row => 0, -sticky => 'ew');
		$frame_eu4_buttons -> g_grid_columnconfigure(0, -weight => 1);
		$frame_eu4_buttons -> g_grid_columnconfigure(1, -weight => 1);
		$frame_eu4_buttons -> g_grid_columnconfigure(2, -weight => 1);
		$frame_eu4_buttons2 = $page_eu4 -> new_ttk__frame();
		$frame_eu4_buttons2 -> g_grid(-column => 0, -columnspan => 3, -row => 3, -sticky => 'ew');
		$frame_eu4_buttons2 -> new_ttk__button(-text => 'Декодировать (CP1251)', -command => [\&encodelocalisation_eu4, 'd_cp1251']) -> g_grid(-column => 0, -row => 0, -sticky => 'ew');
		$frame_eu4_buttons2 -> new_ttk__button(-text => 'Декодировать (CP1252+CYR)', -command => [\&encodelocalisation_eu4, 'd_cp1252pcyr']) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$frame_eu4_buttons2 -> g_grid_columnconfigure(0, -weight => 1);
		$frame_eu4_buttons2 -> g_grid_columnconfigure(1, -weight => 1);
	$page_eu4 -> g_grid_columnconfigure(1, -weight => 1);
	# вкладка CK2
	$page_ck2 = $mw -> new_ttk__frame();
	$frame_notebook -> m_add($page_ck2, -text => 'CK2', -sticky => 'nsew');
		# каталог с русской локализацией
		$page_ck2 -> new_ttk__label(-text => 'Рус. лок.:') -> g_grid(-column => 0, -row => 0, -sticky => 'w');
		$page_ck2 -> new_ttk__entry(-textvariable => \$config{ck2_origru}) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$page_ck2 -> new_ttk__button(-text => 'Выбрать каталог', -command => [\&seldir, \$config{ck2_origru}]) -> g_grid(-column => 2, -row => 0, -sticky => 'e');
		# каталог с английской локализацией
		$page_ck2 -> new_ttk__label(-text => 'Анг. лок.:') -> g_grid(-column => 0, -row => 1, -sticky => 'w');
		$page_ck2 -> new_ttk__entry(-textvariable => \$config{ck2_origen}) -> g_grid(-column => 1, -row => 1, -sticky => 'ew');
		$page_ck2 -> new_ttk__button(-text => 'Выбрать каталог', -command => [\&seldir, \$config{ck2_origen}]) -> g_grid(-column => 2, -row => 1, -sticky => 'e');
		# каталог сохранения
		$page_ck2 -> new_ttk__label(-text => 'Сохранить в:') -> g_grid(-column => 0, -row => 2, -sticky => 'w');
		$page_ck2 -> new_ttk__entry(-textvariable => \$config{ck2_saveru}) -> g_grid(-column => 1, -row => 2, -sticky => 'ew');
		$page_ck2 -> new_ttk__button(-text => 'Выбрать каталог', -command => [\&seldir, \$config{ck2_saveru}]) -> g_grid(-column => 2, -row => 2, -sticky => 'e');
		# кнопки
		$frame_ck2_buttons = $page_ck2 -> new_ttk__frame();
		$frame_ck2_buttons -> g_grid(-column => 0, -columnspan => 3, -row => 3, -sticky => 'ew');
		$frame_ck2_buttons -> new_ttk__button(-text => 'Кодировать (CP1252+CYR)', -command => [\&encodelocalisation_ck2, 'cp1252pcyr']) -> g_grid(-column => 0, -row => 0, -sticky => 'ew');
		$frame_ck2_buttons -> new_ttk__button(-text => 'Транслитерировать', -command => [\&encodelocalisation_ck2, 'translit']) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$frame_ck2_buttons -> new_ttk__button(-text => 'Только тэгы', -command => \&ck2_tags) -> g_grid(-column => 2, -row => 0, -sticky => 'ew');
		$frame_ck2_buttons -> g_grid_columnconfigure(0, -weight => 1);
		$frame_ck2_buttons -> g_grid_columnconfigure(1, -weight => 1);
		$frame_ck2_buttons -> g_grid_columnconfigure(2, -weight => 1);
	$page_ck2 -> g_grid_columnconfigure(1, -weight => 1);
	# вкладка FNT
	$page_fnt = $mw -> new_ttk__frame();
	$frame_notebook -> m_add($page_fnt, -text => 'Шрифт', -sticky => 'nsew');
		# каталог №1
		$page_fnt -> new_ttk__label(-text => 'Для обработки:') -> g_grid(-column => 0, -row => 0, -sticky => 'w');
		$page_fnt -> new_ttk__entry(-width => 50, -textvariable => \$config{fnt_cat1}) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$page_fnt -> new_ttk__button(-text => 'Выбрать каталог', -command => [\&seldir, \$config{fnt_cat1}]) -> g_grid(-column => 2, -row => 0, -sticky => 'e');
		# каталог №2
		$page_fnt -> new_ttk__checkbutton(-text => 'Сохранить в:', -variable => \$config{fnt_c2}) -> g_grid(-column => 0, -row => 1, -sticky => 'w');
		$page_fnt -> new_ttk__entry(-width => 50, -textvariable => \$config{fnt_cat2}) -> g_grid(-column => 1, -row => 1, -sticky => 'ew');
		$page_fnt -> new_ttk__button(-text => 'Выбрать каталог', -command => [\&seldir, \$config{fnt_cat2}]) -> g_grid(-column => 2, -row => 1, -sticky => 'e');
		# кнопки
		$frame_fnt_buttons = $page_fnt -> new_ttk__frame();
		$frame_fnt_buttons -> g_grid(-column => 0, -columnspan => 3, -row => 2, -sticky => 'ew');
		$frame_fnt_buttons -> new_ttk__button(-text => 'Кодировать', -command => [\&font, '0']) -> g_grid(-column => 0, -row => 0, -sticky => 'ew');
		$frame_fnt_buttons -> new_ttk__button(-text => 'Кодировать (CP1252+CYR-EU4)', -command => [\&font, 'eu4']) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$frame_fnt_buttons -> new_ttk__button(-text => 'Кодировать (CP1252+CYR-CK2)', -command => [\&font, 'ck2']) -> g_grid(-column => 2, -row => 0, -sticky => 'ew');
		$frame_fnt_buttons -> g_grid_columnconfigure(0, -weight => 1);
		$frame_fnt_buttons -> g_grid_columnconfigure(1, -weight => 1);
		$frame_fnt_buttons -> g_grid_columnconfigure(2, -weight => 1);
	$page_fnt -> g_grid_columnconfigure(1, -weight => 1);
	# вкладка CNV
	$page_cnv = $mw -> new_ttk__frame();
	$frame_notebook -> m_add($page_cnv, -text => 'Мод сохранения', -sticky => 'nsew');
		# каталог №1
		$page_cnv -> new_ttk__label(-text => 'Для обработки:') -> g_grid(-column => 0, -row => 0, -sticky => 'w');
		$page_cnv -> new_ttk__entry(-width => 50, -textvariable => \$config{cnv_cat1}) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$page_cnv -> new_ttk__button(-text => 'Выбрать каталог', -command => [\&seldir, \$config{cnv_cat1}]) -> g_grid(-column => 2, -row => 0, -sticky => 'e');
		# каталог №2
		$page_cnv -> new_ttk__checkbutton(-text => 'Сохранить в:', -variable => \$config{cnv_c2}) -> g_grid(-column => 0, -row => 1, -sticky => 'w');
		$page_cnv -> new_ttk__entry(-width => 50, -textvariable => \$config{cnv_cat2}) -> g_grid(-column => 1, -row => 1, -sticky => 'ew');
		$page_cnv -> new_ttk__button(-text => 'Выбрать каталог', -command => [\&seldir, \$config{cnv_cat2}]) -> g_grid(-column => 2, -row => 1, -sticky => 'e');
		# кнопки
		$frame_cnv_buttons = $page_cnv -> new_ttk__frame();
		$frame_cnv_buttons -> g_grid(-column => 0, -columnspan => 3, -row => 2, -sticky => 'ew');
		$frame_cnv_buttons -> new_ttk__button(-text => 'Конвертировать (CP1251)', -command => [\&mod_save_conv, 'cp1251']) -> g_grid(-column => 0, -row => 0, -sticky => 'ew');
		$frame_cnv_buttons -> new_ttk__button(-text => 'Конвертировать (CP1252+CYR)', -command => [\&mod_save_conv, 'cp1252pcyr']) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$frame_cnv_buttons -> g_grid_columnconfigure(0, -weight => 1);
		$frame_cnv_buttons -> g_grid_columnconfigure(1, -weight => 1);
		# предупреждение
		$page_cnv -> new_ttk__label(-text => 'Представленные здесь инструменты, скорее всего, не работаю, т. к. мне не на чем их отлаживать. Ждём релиза полных переводов CK2 и EU4.', -foreground => 'red', -justify => 'left', -wraplength => 600) -> g_grid(-column => 0, -columnspan => 3, -row => 3, -sticky => 'ew');
	$page_cnv -> g_grid_columnconfigure(1, -weight => 1);
	# статусная строка и кнопка закрытия
	$frame_buttons = $mw -> new_ttk__frame();
	$frame_buttons -> g_grid(-column => 0, -row => 1, -sticky => 'sew');
	$frame_buttons -> new_ttk__label(-textvariable => \$status) -> g_pack(-expand => 1, -fill => 'x', -side => 'left');
	$frame_buttons -> new_ttk__button(-text => 'Закрыть', -command => sub{$mw -> g_destroy()}) -> g_pack(-side => 'right');
# фреймы верхнего уровня
$mw -> g_grid_columnconfigure(0, -weight => 1);
$mw -> g_wm_resizable(1, 0);
# упреждающее применение настроек
$frame_notebook -> m_select($config{page});
# привязки сочетаний клавиш
$mw -> g_bind('<Control-q>' => sub{$mw -> g_destroy()});
$mw -> g_bind('<F1>' => \&helpwindow);
$mw -> g_bind('<<NotebookTabChanged>>' => \&save_page_raised);
Tkx::MainLoop();
# запись конфигурации
&config_write($conf_path_file_encoded, %config);

################
# ПОДПРОГРАММЫ #
################
# Конвертор файлов локализации EU4
# ПРОЦЕДУРА
sub encodelocalisation_eu4 {
	my $cpfl = shift; # cp1251 — CP1251; cp1252pcyr — CP1252+CYR; translit — транслит; d_cp1251 — декодировать CP1251; d_cp1252pcyr — декодировать CP1252+CYR
	my $c2fl = $config{eu4_c2}; # 0 — перезаписать; 1 — сохранить в другое место
	my $dir1 = $config{eu4_cat1}; # каталог №1
	my $dir2 = $config{eu4_cat2}; # каталог №2
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {$status = 'Каталог с исходными данными не найден!'; return 1};
	if ($c2fl == 1) {unless (-d encode('locale_fs', $dir2)) {$status = 'Каталог для сохранения не найден!'; return 1}};
	# работа
	&win_busy();
	opendir(my $ch, encode('locale_fs', $dir1));
	my @files = grep { m/\.yml$/ } map {decode('locale_fs', $_)} readdir $ch;
	closedir($ch);
	for (my $i = 0; $i < scalar(@files); $i++) {
		open(my $file, '<:unix:perlio:utf8', encode('locale_fs', "$dir1/$files[$i]"));
		my $fl = 0; # флаг нужности/ненужности обработки строк
		my @strs; # объявление хранилища строк
		push(@strs, "\x{FEFF}"); # добавление BOM в начало файла
		while (my $str = <$file>) {
			chomp $str;
			if ($str =~ m/\r$/) {$str =~ s/\r$//} # защита от дебилов, подающих на вход CRLF
			if ($str =~ m/^\x{FEFF}/) {$str =~ s/^\x{FEFF}//} # удаление BOM из обрабатываемых строк
			if ($str =~ m/^\#/ or $str =~ m/^ \#/ or $str =~ m/^$/ or $str =~ m/^ $/) {push(@strs, "$str\n"); next} # запоминание и пропуск необрабатываемых строк
			if ($str =~ m/^l_/) {
				push(@strs, "$str\n");
				if   ($str =~ m/^l_russian/) {$fl = 1}
				else                         {$fl = 0}
				next;
			}
			if ($fl eq 0) {push(@strs, "$str\n"); next}
			# деление строки
			my ($tag, $num, $txt, $cmm) = &yml_string($str);
			# обработка строки
			if    ($cpfl eq 'cp1251') {
				$txt = &cyr_to_cp1251($txt);
			}
			elsif ($cpfl eq 'cp1252pcyr') {
				$txt = &cyr_to_cp1252pcyr($txt, 'eu4');
			}
			elsif ($cpfl eq 'translit') {
				$txt = &cyr_to_translit($txt);
			}
			elsif ($cpfl eq 'd_cp1251') {
				$txt = &cp1251_to_cyr($txt);
			}
			elsif ($cpfl eq 'd_cp1252pcyr') {
				$txt = &cp1252pcyr_to_cyr($txt, 'eu4');
			}
			# сохранение строки
			if (length($cmm) > 0) {
				push(@strs, " $tag:$num \"$txt\" #$cmm\n");
				next;
			}
			push(@strs, " $tag:$num \"$txt\"\n");
		}
		close($file);
		if ($c2fl == 0) {
			open(my $out, '>:unix:perlio:utf8', encode('locale_fs', "$dir1/$files[$i]"));
			print $out @strs;
			close $out;
		}
		elsif ($c2fl == 1) {
			open(my $out, '>:unix:perlio:utf8', encode('locale_fs', "$dir2/$files[$i]"));
			print $out @strs;
			close $out;
		}
	}
	&win_unbusy();
}

# Конвертор файлов локализации CK2
# ПРОЦЕДУРА
sub encodelocalisation_ck2 {
	my $cpfl = shift; # cp1252pcyr — CP1252+CYR; translit — транслит
	my $dir_orig_en = $config{'ck2_origen'};
	my $dir_orig_ru = $config{'ck2_origru'};
	my $dir_save_ru = $config{'ck2_saveru'};
	unless (-d encode('locale_fs', $dir_orig_en)) {$status = 'Не найден каталог с английской локализацией!'; return 1}
	unless (-d encode('locale_fs', $dir_orig_ru)) {$status = 'Не найден каталог с русской локализацией!'; return 1}
	unless (-d encode('locale_fs', $dir_save_ru)) {$status = 'Не найден каталог для сохранения локализации!'; return 1}
	&win_busy();
	my %loc_ru;
	opendir(my $corh, encode('locale_fs', $dir_orig_ru));
	my @files_or = grep { m/\.csv$/ } map {decode('locale_fs', $_)} readdir $corh;
	closedir($corh);
	for (my $i = 0; $i < scalar(@files_or); $i++) {
		open(my $fh, '<:raw', encode('locale_fs', "$dir_orig_ru/$files_or[$i]"));
		while (my $str = <$fh>) {
			$str = decode('cp1252', $str); # декодировка строки из CP1252
			$str =~ s/\x{FFFD}//g; # удаление символа-заполнителя при перекодировке неправильно сформированных символов
			$str =~ s/\r$//; # удаление CR в конце строки
			chomp($str); # удаление LF
			if ($str =~ m/^$/) {next} # пропуск пустых строк
			if ($str =~ m/^\#/) {next} # пропуск строк с комментариями
			if ($str =~ m/^;/) {next} # пропуск строк без тегов
			my $tag = $str;
			$tag =~ s/;.*$//;
			my $trns = $str;
			$trns =~ s/^[^;]*//;
			$trns =~ s/^;//;
			$trns =~ s/;.*$//;
			$trns = &cp1251_to_cyr($trns); # эта конструкция ломает расширенную латиницу из CP1252, если она там была
			$loc_ru{$tag} = $trns;
		}
		close($fh);
	}
	opendir(my $coeh, encode('locale_fs', $dir_orig_en));
	my @files_oe = grep { m/\.csv$/ } map {decode('locale_fs', $_)} readdir $coeh;
	closedir($coeh);
	for (my $i = 0; $i < scalar(@files_oe); $i++) {
		open(my $fh, '<:raw', encode('locale_fs', "$dir_orig_en/$files_oe[$i]"));
		my $ff; # флаг содержания файла
		my @strs; # хранилище строк
		push(@strs, "#CODE;RUSSIAN;x\n");
#		push(@strs, "#CODE;ENGLISH;x\n");
		while (my $str = <$fh>) {
			$str = decode('cp1252', $str);
			$str =~ s/\x{FFFD}//g;
			$str =~ s/\r$//;
			chomp($str);
			if ($str =~ m/^$/) {next}
			if ($str =~ m/^\#/) {next}
			if ($str =~ m/^;/) {next}
			my $tag = $str;
			$tag =~ s/;.*$//;
			my $trns = $str;
			$trns =~ s/^[^;]*//;
			$trns =~ s/^;//;
			$trns =~ s/;.*$//;
			my $st;
			if ($tag =~ m/^PROV[1-9]/ or
			    $tag =~ m/^b_/ or
			    $tag =~ m/^c_/ or
			    $tag =~ m/^d_/ or
			    $tag =~ m/^e_/ or
			    $tag =~ m/^k_/ or
			    $tag =~ m/^W_L_[1-9]/) {
				$st = "$tag;$trns;x\n";
			}
			elsif (defined($loc_ru{$tag})) {
				my $trru = $loc_ru{$tag};
				if ($cpfl eq 'cp1252pcyr') {
					$trru = &cyr_to_cp1252pcyr($trru, 'ck2');
				}
				elsif ($cpfl eq 'translit') {
					$trru = &cyr_to_translit($trru);
				}
				$st = "$tag;$trru;x\n";
			}
			if (defined($st)) {
				push(@strs, $st);
			}
			$ff = 1; # установка флага содержания
		}
		close($fh);
		unless (defined($ff)) {next}
		open(my $ffh, '>:unix:crlf:encoding(cp1252)', encode('locale_fs', "$dir_save_ru/$files_oe[$i]"));
		print $ffh @strs;
		close($ffh);
	}
	&win_unbusy();
}

# Вывод тэгов локализации CK2
# ПРОЦЕДУРА
sub ck2_tags {
	my $dir_orig_en = $config{'ck2_origen'};
	my $dir_orig_ru = $config{'ck2_origru'};
	my $dir_save_ru = $config{'ck2_saveru'};
	unless (-d encode('locale_fs', $dir_orig_en)) {$status = 'Не найден каталог с английской локализацией!'; return 1}
	unless (-d encode('locale_fs', $dir_orig_ru)) {$status = 'Не найден каталог с русской локализацией!'; return 1}
	unless (-d encode('locale_fs', $dir_save_ru)) {$status = 'Не найден каталог для сохранения локализации!'; return 1}
	&win_busy();
	opendir(my $corh, encode('locale_fs', $dir_orig_ru));
	my @files_or = grep { m/\.csv$/ } map {decode('locale_fs', $_)} readdir $corh;
	closedir($corh);
	mkdir(encode('locale_fs', "$dir_save_ru/ru"));
	for (my $i = 0; $i < scalar(@files_or); $i++) {
		open(my $fh, '<:raw', encode('locale_fs', "$dir_orig_ru/$files_or[$i]"));
		my $ff;
		my @strs;
		push(@strs, "\x{FEFF}#CODE\n");
		while (my $str = <$fh>) {
			$str = decode('cp1252', $str);
			$str =~ s/\x{FFFD}//g;
			$str =~ s/\r$//;
			chomp($str);
			if ($str =~ m/^$/) {next}
			if ($str =~ m/^\#/) {next}
			if ($str =~ m/^;/) {next}
			my $tag = $str;
			$tag =~ s/;.*$//;
			push(@strs, "$tag\n");
			$ff = 1;
		}
		close($fh);
		unless (defined($ff)) {next}
		open(my $ffh, '>:unix:perlio:utf8', encode('locale_fs', "$dir_save_ru/ru/$files_or[$i]"));
		print $ffh @strs;
		close($ffh);
	}
	opendir(my $coeh, encode('locale_fs', $dir_orig_en));
	my @files_oe = grep { m/\.csv$/ } map {decode('locale_fs', $_)} readdir $coeh;
	closedir($coeh);
	mkdir(encode('locale_fs', "$dir_save_ru/en"));
	for (my $i = 0; $i < scalar(@files_oe); $i++) {
		open(my $fh, '<:raw', encode('locale_fs', "$dir_orig_en/$files_oe[$i]"));
		my $ff;
		my @strs;
		push(@strs, "\x{FEFF}#CODE\n");
		while (my $str = <$fh>) {
			$str = decode('cp1252', $str);
			$str =~ s/\x{FFFD}//g;
			$str =~ s/\r$//;
			chomp($str);
			if ($str =~ m/^$/) {next}
			if ($str =~ m/^\#/) {next}
			if ($str =~ m/^;/) {next}
			my $tag = $str;
			$tag =~ s/;.*$//;
			push(@strs, "$tag\n");
			$ff = 1;
		}
		close($fh);
		unless (defined($ff)) {next}
		open(my $ffh, '>:unix:perlio:utf8', encode('locale_fs', "$dir_save_ru/en/$files_oe[$i]"));
		print $ffh @strs;
		close($ffh);
	}
	&win_unbusy();
}

# Очистка и модификация карт шрифтов
# ПРОЦЕДУРА
sub font { # изменяет fnt-карты шрифтов
	my $cpfl = shift;#0 — не трогать; eu4 — обработка CP1252+CYR-EU4; ck2 — обработка CP1252+CYR-CK2
	my $c2fl = $config{'fnt_c2'};#0 — перезаписать; 1 — сохранить в другое место
	my $dir1 = $config{'fnt_cat1'};#каталог №1
	my $dir2 = $config{'fnt_cat2'};#каталог №2
	unless (-d encode('locale_fs', $dir1)) {$status = 'Каталог с исходными данными не найден!'; return 1}
	if ($c2fl == 1) {unless (-d encode('locale_fs', $dir2)) {$status = 'Каталог для сохранения не найден!'; return 1}}
	&win_busy();
	opendir(my $ch, encode('locale_fs', $dir1));
	my @files = grep { m/\.fnt$/ } map {decode('locale_fs', $_)} readdir $ch;
	closedir($ch);
	for (my $i = 0; $i < scalar(@files); $i++) {
		open(my $file_in, '<:unix:crlf', encode('locale_fs', "$dir1/$files[$i]"));
		my @strs;
		while (my $str = <$file_in>) {
			chomp($str);
			if ($str =~ m/^kernings/) {
				push(@strs, "$str\n"); next;
			}
			if ($str =~ m/^info/) {
				$str =~ s/size=-/size=/;
				$str =~ s/ charset=""/ charset="ANSI"/;
				$str =~ s/ unicode=\w+//;
				$str =~ s/ outline=\w+//;
				push(@strs, "$str\n"); next;
			}
			if ($str =~ m/^common/) {
				$str =~ s/ packed=\w+ alphaChnl=\w+ redChnl=\w+ greenChnl=\w+ blueChnl=\w+//;
				push(@strs, "$str\n"); next;
			}
			if ($str =~ m/^page/) {
				next;
			}
			if ($str =~ m/^chars/) {
				next;
			}
			if ($str =~ m/^char/) {
				my @str_id = split(" ", $str);
				if ($cpfl eq 'eu4' or $cpfl eq 'ck2') {#если CP1252+CYR, то заменить номера символов
					$str_id[1] = &id_to_cp1252pcyr($str_id[1], $cpfl);
				}
				delete $str_id[10];
				push(@strs, "@str_id\n"); next;
			}
			if ($str =~ m/^kerning/) {
				my @str_kerning = split(" ", $str);
				if ($cpfl eq 'eu4' or $cpfl eq 'ck2') {#если CP1252+CYR, то заменить номера символов
					$str_kerning[1] = &id_to_cp1252pcyr($str_kerning[1], $cpfl);
					$str_kerning[2] = &id_to_cp1252pcyr($str_kerning[2], $cpfl);
				}
				push(@strs, "@str_kerning\n"); next;
			}
		}
		close($file_in);
		# сортировка
		if ($cpfl eq 'eu4' or $cpfl eq 'ck2') {#если CP1252+CYR, то сортировать
			my $kr;
			for (my $i = 2; $i < scalar(@strs); $i++) {
				if ($strs[$i] =~ m/^kernings/) {$kr = $i - 1; last}
			}
			unless (defined $kr) {$kr = scalar(@strs) - 1}
			# участок массива от третьей строки до последней строки перед m/^kernings/ или концом файла сортируется по числам столбца id=
			@strs[2..$kr] = sort {&srt($a, $b)} @strs[2..$kr];
		}
		# /сортировка
		if ($c2fl == 0) {
			open(my $file_out, '>:unix:crlf', encode('locale_fs', "$dir1/$files[$i]"));
			print $file_out @strs;
			close($file_out);
		}
		elsif ($c2fl == 1) {
			open(my $file_out, '>:unix:crlf', encode('locale_fs', "$dir2/$files[$i]"));
			print $file_out @strs;
			close($file_out);
		}
	}
	&win_unbusy();
}

# Конвертирование файлов локализации мода-сейва из CK2 в EU4
# ПРОЦЕДУРА
sub mod_save_conv {
	my $cpfl = shift; # cp1251 — CP1251; cp1252pcyr — CP1252+CYR
	my $c2fl = $config{cnv_c2}; # 0 — произвести изменения в исходном каталоге; 1 — сохранить в каталог №2
	my $dir1 = $config{cnv_cat1}; # исходный каталог
	my $dir2 = $config{cnv_cat2}; # каталог сохранения
	unless (-d encode('locale_fs', $dir1)) {$status = 'Каталог с исходными данными не найден!'; return 1}
	if ($c2fl == 1) {unless (-d encode('locale_fs', $dir2)) {$status = 'Каталог для сохранения не найден!'; return 1}};
	&win_busy();
	opendir(my $ch, encode('locale_fs', $dir1));
	my @files = grep { m/\.yml$/ } map {decode('locale_fs', $_)} readdir $ch;
	closedir($ch);
	for (my $i = 0; $i < scalar(@files); $i++) {
		# удаление файлов локализации других языков
		if ($files[$i] =~ m/_l_french\.yml$/ or
		    $files[$i] =~ m/_l_german\.yml$/ or
		    $files[$i] =~ m/_l_spanish\.yml$/) {
			if ($c2fl == 0) {
				unlink encode('locale_fs', "$dir1/$files[$i]");
			}
			next;
		}
		# удаление лишних файлов
#		if ($files[$i] =~ m/converted_custom_countries/ or
#		    $files[$i] =~ m/converted_custom_ideas/ or
#		    $files[$i] =~ m/converted_heresies/ or
#		    $files[$i] =~ m/converted_misc/ or
#		    $files[$i] =~ m/converted_religions/ or
#		    $files[$i] =~ m/new_converted_texts/ or
#		    $files[$i] =~ m/sunset_invasion_custom_countries/ or
#		    $files[$i] =~ m/sunset_invasion_custom_ideas/) {
#			if ($c2fl == 0) {
#				unlink encode('locale_fs', "$dir1/$files[$i]");
#			}
#			next;
#		}
		open(my $file, '<:unix:perlio:utf8', encode('locale_fs', "$dir1/$files[$i]"));
		my @strs;
		push(@strs, "\x{FEFF}");
		while (my $str = <$file>) {
			chomp($str);
			if ($str =~ m/\r$/) {$str =~ s/\r$//}
			if ($str =~ m/^\x{FEFF}/) {$str =~ s/^\x{FEFF}//}
			if ($str =~ m/^\#/ or $str =~ m/^ \#/ or $str =~ m/^$/ or $str =~ m/^ $/) {push(@strs, "$str\n"); next}
			if ($str =~ m/^l_english/) {$str =~ s/l_english/l_russian/; push(@strs, "$str\n"); next}
			# деление строки
			my ($tag, $num, $txt, $cmm) = &yml_string($str);
			# обработка строки
			$txt =~ y/Ђѓ€ЉЊЋљњћџЎўЈҐЁЄЇІіґё№єјЅѕїАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя/€ƒˆŠŒŽšœžŸ¡¢£¥¨ª¯²³´¸¹º¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ/;
			if ($cpfl eq 'cp1251') {
				if ($files[$i] =~ m/converted_cultures/) {
					$txt =~ s/\x7f\x11$/àÿ/;
				}
				if ($tag =~ m/^..._ADJ$/) {
					$txt .= 'ñê';
				}
			}
			elsif ($cpfl eq 'cp1252pcyr') {
				$txt =~ y/^/€/;
				if ($files[$i] =~ m/converted_cultures/) {
					$txt =~ s/\x7f\x11$/a÷/;
				}
			}
			# сохранение строки
			push(@strs, " $tag:$num \"$txt\"\n");
		}
		close($file);
		my $new_name = $files[$i];
		$new_name =~ s/_l_english\.yml$/_l_russian\.yml/;
		if ($c2fl == 0) {
			rename encode('locale_fs', "$dir1/$files[$i]"), encode('locale_fs', "$dir1/$new_name");
		}
		if ($c2fl == 0) {
			open(my $out, '>:unix:perlio:utf8', encode('locale_fs', "$dir1/$new_name"));
			print $out @strs;
			close $out;
		}
		elsif ($c2fl == 1) {
			open(my $out, '>:unix:perlio:utf8', encode('locale_fs', "$dir2/$new_name"));
			print $out @strs;
			close $out;
		}
	}
	&win_unbusy();
}

# функция разбора правильной YAML-подобной строки файла локализации EU4
sub yml_string {
	my $str = shift;
	$str =~ s/^\h//; # удаление начального пробела
	$str =~ m/^[^:]+:[0-9]*/p; # нахождение тэга и номера
	$str = ${^POSTMATCH}; # выбрасывание из строки найденной информации
	my ($tag, $num) = split (/:/, ${^MATCH}); # приравнивание тэга и номера соответствующим переменным
	$str =~ s/^\h+//; # удаление пробела между номером и текстом
	$str =~ s/\\\"/\0/g; # замена экранированных кавычек на нулевые символы
	$str =~ m/^"[^"]*"/p; # нахождение текста //в некоторых строках нет локализации
	$str = ${^POSTMATCH}; # выбрасывание из строки найденной информации
	my $txt = ${^MATCH}; # приравнивание текста соответствующей переменной
	$txt =~ s/^"//; # удаление кавычки в начале текста
	$txt =~ s/"$//; # удаление кавычки в конце текста
	$txt =~ s/\0/\\\"/g; # замена нулевых символов на экранированные кавычки в тексте
	$str =~ s/\0/\\\"/g; # замена нулевых символов на экранированные кавычки в исходной строке
	my $cmm = $str; # приравнивание остатков строки комментарию
	$cmm =~ s/ #//; # удаление обозначения комментария в начале комментария //в оригинальной локализации комментарий в строке всегда начинается последовательностью « #»
	return $tag, $num, $txt, $cmm;
}

# функция чтения конфигурационного файла
sub config_read {
	my $file = shift;
	my %ch;
	open(my $cfh, '<:unix:perlio:utf8', $file);
	while (my $cstr = <$cfh>) {
		chomp $cstr;
		if ($cstr =~ m/^$/) {next}
		my @cstr = split m/:/, $cstr, 2;
		$ch{$cstr[0]} = $cstr[1];
	}
	close $cfh;
	return %ch;
}

# функция записи конфигурационного файла
sub config_write {
	my $file = shift;
	my $cnhs = shift;
	open(my $cfh, '>:unix:perlio:utf8', $file);
	for my $key (sort keys %config) {print $cfh "$key:$config{$key}\n"}
	close $cfh;
}

# функция помощи сортировки для функции модификации карт шрифтов
sub srt {
	my $a = shift;
	my $b = shift;
	my @a = split(" ", $a);
	@a = split("=", $a[1]);
	$a = $a[1];
	my @b = split(" ", $b);
	@b = split("=", $b[1]);
	$b = $b[1];
	if ($a > $b) {return 1}
	elsif ($a < $b) {return -1}
	elsif ($a == $b) {return 0}
}

# функция для преобразования кириллицы из UTF-8 в CP1251
sub cyr_to_cp1251 {
	my $str = shift;
	$str =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ/;
	return $str;
}

# функция для преобразования кириллицы из CP1251 в UTF-8
sub cp1251_to_cyr {
	my $str = shift;
	$str =~ y/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/;
	return $str;
}

# функция для преобразования кириллицы из UTF-8 в CP1252+CYR
sub cyr_to_cp1252pcyr {
	my $str = shift; # строка для преобразования
	my $reg = shift; # eu4 — CP1252+CYR-EU4; ck2 — CP1252+CYR-CK2
	$str =~ s/…/.../g;
	if ($reg eq 'eu4') {
		$str =~ s/„/\\\"/g;
		$str =~ s/“/\\\"/g;
		$str =~ s/”/\\\"/g;
		$str =~ s/«/\\\"/g;
		$str =~ s/»/\\\"/g;
		$str =~ y/‚‹‘’–—› €ƒ†‡ˆ‰•˜™¢¥¦¨©ª¬®¯°±²³´µ¶·¸¹º¼½¾×÷/''''\-\-' /d;
		$str =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/A€B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷/;
	}
	elsif ($reg eq 'ck2') {
		$str =~ y/‚„‹‘’“”–—› «»^€ƒ†‡ˆ‰•˜™¢¥¦¨©ª¬®¯°±²³´µ¶·¸¹º¼½¾×÷/'"'''""\-\-' ""/d;
		$str =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/A^B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷/;
	}
	return $str;
}

# функция для преобразования кириллицы из CP1252+CYR в UTF-8
sub cp1252pcyr_to_cyr {
=pod
Данная функция не выполняет преобразование из CP1252+CYR, т. к. преобразование в CP1252+CYR необратимо; она лишь позволяет прочитать закодированный ранее текст.
=cut
	my $str = shift; # строка для преобразования
	my $reg = shift; # eu4 — CP1252+CYR-EU4; ck2 — CP1252+CYR-CK2
	if ($reg eq 'eu4') {
		$str =~ y/€‚ƒ„…†‡ˆ‰‹‘’“”•–—˜™›× ¢¥¦¨©ª«¬®¯°±²³´µ¶·¸¹º»¼¾÷/БГДЖЗИЙЛПУФЦЧШЩЪЫЬЭЮЯбвгджзийклмнптуфцчшщъыьэюя/;
	}
	elsif ($reg eq 'ck2') {
		$str =~ y/^‚ƒ„…†‡ˆ‰‹‘’“”•–—˜™›× ¢¥¦¨©ª«¬®¯°±²³´µ¶·¸¹º»¼¾÷/БГДЖЗИЙЛПУФЦЧШЩЪЫЬЭЮЯбвгджзийклмнптуфцчшщъыьэюя/;
	}
	return $str;
}

# функция для транслитерирования кириллицы
sub cyr_to_translit {
	my $str = shift;
	$str =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/ABVGDEËJZIYKLMNOPRSTUFHQCXÇ’ÎYÊÜÄabvgdeëjziyklmnoprstufhqcxç’îyêüä/;
	return $str;
}

# функция для замены номеров символов в кодировке юникод на номера для CP1252+CYR
sub id_to_cp1252pcyr {
	my $str = shift; # строка для преобразования
	my $reg = shift; # 0 — CP1252+CYR-EU4; 1 — CP1252+CYR-CK2
	$str =~ s/352/138/;
	$str =~ s/353/154/;
	$str =~ s/338/140/;
	$str =~ s/339/156/;
	$str =~ s/381/142/;
	$str =~ s/382/158/;
	$str =~ s/376/159/;
	if    ($reg eq 'eu4') {$str =~ s/1041/128/}
	elsif ($reg eq 'ck2') {$str =~ s/1041/94/}
	$str =~ s/1043/130/;
	$str =~ s/1044/131/;
	$str =~ s/1046/132/;
	$str =~ s/1047/133/;
	$str =~ s/1048/134/;
	$str =~ s/1049/135/;
	$str =~ s/1051/136/;
	$str =~ s/1055/137/;
	$str =~ s/1059/139/;
	$str =~ s/1060/145/;
	$str =~ s/1062/146/;
	$str =~ s/1063/147/;
	$str =~ s/1064/148/;
	$str =~ s/1065/149/;
	$str =~ s/1066/150/;
	$str =~ s/1067/151/;
	$str =~ s/1068/152/;
	$str =~ s/1069/153/;
	$str =~ s/1070/155/;
	$str =~ s/1073/160/;
	$str =~ s/1074/162/;
	$str =~ s/1075/165/;
	$str =~ s/1076/166/;
	$str =~ s/1078/168/;
	$str =~ s/1079/169/;
	$str =~ s/1080/170/;
	$str =~ s/1081/171/;
	$str =~ s/1082/172/;
	$str =~ s/1083/174/;
	$str =~ s/1084/175/;
	$str =~ s/1085/176/;
	$str =~ s/1087/177/;
	$str =~ s/1090/178/;
	$str =~ s/1091/179/;
	$str =~ s/1092/180/;
	$str =~ s/1094/181/;
	$str =~ s/1095/182/;
	$str =~ s/1096/183/;
	$str =~ s/1097/184/;
	$str =~ s/1098/185/;
	$str =~ s/1099/186/;
	$str =~ s/1100/187/;
	$str =~ s/1101/188/;
	$str =~ s/1102/190/;
	$str =~ s/1071/215/;
	$str =~ s/1103/247/;
	return $str;
}

################################################################################
# Подпрограммы поддержки графического интерфейса
#

sub helpwindow {
	my $d = $mw -> new_toplevel();
	$d -> g_wm_title('Краткая справка');
	$d -> g_wm_resizable(0, 0);
	$d -> new_ttk__label(-justify => 'left', -text =>
"Структура интерфейса программы:
	вкладки определяют формат, с которым работаем
	виджеты на вкладках — что с ними можно сделать
Форматы:
	EU4 — каталог /localisation/*.yml
	CK2 — каталог /localisation/*.csv
	Шрифт — каталог с файлами *.fnt
	Мод сохранения — каталог /localisation/*.yml
Кодировать — перевести в указанную кодировку из исходной для данного формата.
Декодировать — перевести из указанной кодировки в исходную для данного формата.
Исходные кодировки:
	EU4 — UTF-8
	CK2 — CP1252 (CP1251)"
) -> g_pack();
	$d -> new_ttk__button(-text => 'Ок', -command => sub{$d -> g_destroy}) -> g_pack(-expand => 1, -fill => 'x');
	$d -> g_focus;
}

sub translittable {
=pod
Показывает таблицу транслитерации
=cut
	my $d = $mw -> new_toplevel();
	$d -> g_wm_title('Таблица транслитерации');
	$d -> g_wm_resizable(0, 0);
	$d -> new_ttk__label(-justify => 'left', -text =>
"а — Aa	я — Ää
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
ь — Yy") -> g_pack();
	$d -> new_ttk__button(-text => 'Ок', -command => sub{$d -> g_destroy}) -> g_pack(-expand => 1, -fill => 'x');
	$d -> g_focus;
}

sub seldir {
=pod
Вызывает диалог выбора каталога и записывает выбранное значение в переменную с именем каталога
параметр: ссылка на переменную, в которую записывать значение
=cut
	my $dir = shift;
	my $sdir = Tkx::tk___chooseDirectory();
	if (defined $sdir and $sdir ne '') {
		$$dir = "$sdir";
	}
}

sub save_page_raised {
=pod
Сохраняет в переменную текущую открытую вкладку
=cut
	$config{page} = $frame_notebook -> m_index('current');
}

sub win_busy {
=pod
Занять окно
=cut
	$status = 'Обработка ...';
	Tkx::update();
}

sub win_unbusy {
=pod
Вернуть управление окном пользователю
=cut
	$status = 'Готово!';
	Tkx::update();
}

sub menu_license {
=pod
Вывести текст лицензии
=cut
	my $d; # окно
	my $tl; # текст лицензии
	my $vs; # vertical scrollbar
	$d = $mw -> new_toplevel();
	$d -> g_wm_title('Лицензия');
	$d -> g_wm_resizable(0, 1);
	$tl = $d -> new_text(-font => 'TkFixedFont');
	$tl -> m_insert('0.0', '                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers\' and authors\' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users\' and
authors\' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users\' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work\'s
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users\' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work\'s
users, your or third parties\' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program\'s source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation\'s users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party\'s predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor\'s "contributor version".

  A contributor\'s "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor\'s essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient\'s use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others\' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy\'s
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    {one line to give the program\'s name and a brief idea of what it does.}
    Copyright (C) {year}  {name of author}

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    {project}  Copyright (C) {year}  {fullname}
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w\'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c\' for details.

The hypothetical commands `show w\' and `show c\' should show the appropriate
parts of the General Public License.  Of course, your program\'s commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.');
	$tl -> g_grid(-column => 0, -row => 0, -sticky => 'nsew');
	$vs = $d -> new_ttk__scrollbar(-orient => 'vertical', -command => "$tl yview");
	$vs -> g_grid(-column => 1, -row => 0, -sticky => 'ns');
	$tl -> m_configure(-yscrollcommand => "$vs set");
	$tl -> m_configure(-state => 'disabled');
	$d -> new_ttk__button(-text => 'Ок', -command => sub{$d -> g_destroy}) -> g_grid(-column => 0, -columnspan => 2, -row => 1, -sticky => 'ew');
	$d -> g_grid_rowconfigure(0, -weight => 1);
	$d -> g_focus;
}

sub menu_about {
=pod
Вывести сообщение о программе
=cut
	my $d = $mw -> new_toplevel();
	$d -> g_wm_title('О программе');
	$d -> g_wm_resizable(0, 0);
	$d -> new_ttk__label(-justify => 'left', -wraplength => '400', -text => "Recodenc\nВерсия: $version\nCopyright © 2015-2016 terqüéz <gz0\@ro.ru>\nРесурсы для разработчиков и справка:\nhttps://github.com/chomobi/recodenc") -> g_pack(-side => 'left');
	$d -> new_ttk__button(-text => 'Ок', -command => sub{$d -> g_destroy()}) -> g_pack(-side => 'left');
	$d -> g_focus;
}

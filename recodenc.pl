#!/usr/bin/perl
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
use FindBin;
use Config::General;
use Encode qw(encode decode);
use Encode::Locale;
binmode(STDIN, ":encoding(console_in)");
binmode(STDOUT, ":encoding(console_out)");
binmode(STDERR, ":encoding(console_out)");

my $version = '0.4.0';
my $status = ''; # переменная для вывода статуса
# инициализация конфигурации
my %config;
#page — идентификатор поднятой страницы
#eu4_c2 — 0 = не сохранять в др. каталог; 1 = сохранять
#eu4_cat1 — каталог 1
#eu4_cat2 — каталог 2
#fnt_c2 — 0 = не сохранять в др. каталог; 1 = сохранять
#fnt_cat1 — каталог шрифтов 1
#fnt_cat2 — каталог шрифтов 2
#ck2_origru — каталог с русской локализацией CK2 (Full)
#ck2_origen — каталог с английской локализацией CK2
#ck2_saveru — каталог для сохранения скомпилированной Lite-локализации
#cnv_cat — каталог для обработки конвертором мода сохранений
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
unless (-e $conf_path_file_encoded) { # если файл не создан, создать
	open(TMPFH, '>:utf8', $conf_path_file_encoded);
	close TMPFH;
}
my $cf = Config::General -> new(
	-ConfigFile => "$conf_path_file_encoded",
	-AllowMultiOptions => 'no',
	-UseApacheInclude => 'no',
	-AutoTrue => '1',
	-SplitPolicy => 'custom',
	-SplitDelimiter => ':',
	-StoreDelimiter => ':',
	-UTF8 => '1',
	-SaveSorted => '1');
%config = $cf -> getall();
# проверка загруженной конфигурации
if (! defined($config{page})) {$config{page} = 0}
elsif ($config{page} < 0 and $config{page} > 3) {$config{page} = 0}
if (! defined($config{eu4_c2})) {$config{eu4_c2} = 0}
elsif ($config{eu4_c2} != 0 and $config{eu4_c2} != 1) {$config{eu4_c2} = 0}
if (! defined($config{fnt_c2})) {$config{fnt_c2} = 0}
elsif ($config{fnt_c2} != 0 and $config{fnt_c2} != 1) {$config{fnt_c2} = 0}
# инициализация пустыми значениями
for my $key (sort keys %config) {
	unless (defined($config{$key})) {$config{$key} = ''}
#	print "$key\t$config{$key}\n";
};
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
		$menu_help -> m_add_command(-label => 'Таблица транслитерации', -command => \&translittable);
		$menu_help -> m_add_command(-label => 'Лицензия', -command => \&menu_license);
		$menu_help -> m_add_command(-label => 'О программе', -command => \&menu_about);
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
		$frame_eu4_buttons -> new_ttk__button(-text => 'Декодировать (CP1251)', -command => [\&encodelocalisation_eu4, 'd_cp1251']) -> g_grid(-column => 0, -columnspan => 3, -row => 1, -sticky => 'ew');
		$frame_eu4_buttons -> g_grid_columnconfigure(0, -weight => 1);
		$frame_eu4_buttons -> g_grid_columnconfigure(1, -weight => 1);
		$frame_eu4_buttons -> g_grid_columnconfigure(2, -weight => 1);
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
		$page_cnv -> new_ttk__entry(-width => 50, -textvariable => \$config{cnv_cat}) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$page_cnv -> new_ttk__button(-text => 'Выбрать каталог', -command => [\&seldir, \$config{cnv_cat}]) -> g_grid(-column => 2, -row => 0, -sticky => 'e');
		# кнопки
		$frame_cnv_buttons = $page_cnv -> new_ttk__frame();
		$frame_cnv_buttons -> g_grid(-column => 0, -columnspan => 3, -row => 2, -sticky => 'ew');
		$frame_cnv_buttons -> new_ttk__button(-text => 'Конвертировать (CP1251)', -command => [\&mod_save_conv, 'cp1251']) -> g_grid(-column => 0, -row => 0, -sticky => 'ew');
		$frame_cnv_buttons -> new_ttk__button(-text => 'Конвертировать (CP1252+CYR)', -command => [\&mod_save_conv, 'cp1252pcyr']) -> g_grid(-column => 1, -row => 0, -sticky => 'ew');
		$frame_cnv_buttons -> g_grid_columnconfigure(0, -weight => 1);
		$frame_cnv_buttons -> g_grid_columnconfigure(1, -weight => 1);
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
$mw -> g_bind('<<NotebookTabChanged>>' => \&save_page_raised);
Tkx::MainLoop();
# запись конфигурации
$cf -> save_file($conf_path_file_encoded, \%config);

################
# ПОДПРОГРАММЫ #
################
# Конвертор файлов локализации EU4
# ПРОЦЕДУРА
sub encodelocalisation_eu4 {
	my $cpfl = shift; # cp1251 — CP1251; cp1252pcyr — CP1252+CYR; translit — транслит; d_cp1251 — декодировать cp1251
	my $c2fl = $config{eu4_c2}; # 0 — перезаписать; 1 — сохранить в другое место
	my $dir1 = $config{eu4_cat1}; # каталог №1
	my $dir2 = $config{eu4_cat2}; # каталог №2
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {$status = 'Каталог с исходными данными не найден!'; return 1};
	if ($c2fl == 1) {unless (-d encode('locale_fs', $dir2)) {$status = 'Каталог для сохранения не найден!'; return 1}};
	# работа
	&win_busy();
	opendir(my $ch, encode('locale_fs', $dir1));
	my @files = grep { ! /^\.\.?\z/ } map {decode('locale_fs', $_)} readdir $ch;
	closedir($ch);
	for (my $i = 0; $i < scalar(@files); $i++) {
#		unless (-T encode('locale_fs', "$dir1/$files[$i]")) {next}
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
			$str =~ s/^ //; # удаление начального пробела
			$str =~ m/^[^:]+:[0-9]*/p; # нахождение тэга и номера
			$str = ${^POSTMATCH}; # выбрасывание из строки найденной информации
			my ($tag, $num) = split (/:/, ${^MATCH}); # приравнивание тэга и номера соответствующим переменным
			$str =~ s/^ //; # удаление пробела между номером и текстом
			$str =~ s/\\\"/\0/g; # замена экранированных кавычек на нулевые символы
			$str =~ m/^"[^"]*"/p; # нахождение текста //в некоторых строках нет локализации
			$str = ${^POSTMATCH}; # выбрасывание из строки найденной информации
			my $txt = ${^MATCH}; # приравнивание текста соответствующей переменной
			$txt =~ s/^"//; # удаление кавычки в начале текста
			$txt =~ s/"$//; # удаление кавычки в конце текста
			$txt =~ s/\0/\\\"/g; # замена нулевых символов на экранированные кавычки в тексте
			$str =~ s/\0/\\\"/g; # замена нулевых символов на экранированные кавычки в исходной строке
			my $cmm = $str; # приравнивание остатков строки комментарию
			$cmm =~ s/ #//; # удаление обозначения комментария в начале комментария
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
	my @files_or = grep { ! /^\.\.?\z/ } map {decode('locale_fs', $_)} readdir $corh;
	closedir($corh);
	for (my $i = 0; $i < scalar(@files_or); $i++) {
#		unless (-T encode('locale_fs', "$dir_orig_ru/$files_or[$i]")) {next}
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
	my @files_oe = grep { ! /^\.\.?\z/ } map {decode('locale_fs', $_)} readdir $coeh;
	closedir($coeh);
	for (my $i = 0; $i < scalar(@files_oe); $i++) {
#		unless (-T encode('locale_fs', "$dir_orig_en/$files_oe[$i]")) {next}
		open(my $fh, '<:raw', encode('locale_fs', "$dir_orig_en/$files_oe[$i]"));
		my $ff; # флаг содержания файла
		my @strs; # хранилище строк
		push(@strs, "#CODE;RUSSIAN;x\n");
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
	my @files_or = grep { ! /^\.\.?\z/ } map {decode('locale_fs', $_)} readdir $corh;
	closedir($corh);
	mkdir(encode('locale_fs', "$dir_save_ru/ru"));
	for (my $i = 0; $i < scalar(@files_or); $i++) {
#		unless (-T encode('locale_fs', "$dir_orig_ru/$files_or[$i]")) {next}
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
	my @files_oe = grep { ! /^\.\.?\z/ } map {decode('locale_fs', $_)} readdir $coeh;
	closedir($coeh);
	mkdir(encode('locale_fs', "$dir_save_ru/en"));
	for (my $i = 0; $i < scalar(@files_oe); $i++) {
#		unless (-T encode('locale_fs', "$dir_orig_en/$files_oe[$i]")) {next}
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
	my @files = grep { ! /^\.\.?\z/ } map {decode('locale_fs', $_)} readdir $ch;
	closedir($ch);
	for (my $i = 0; $i < scalar(@files); $i++) {
		unless (-T encode('locale_fs', "$dir1/$files[$i]")) {next}
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

# Конвертирование файлов локализации мода-сейва из CK2
# ПРОЦЕДУРА
sub mod_save_conv {
	my $cpfl = shift;
	my $ldir = $config{cnv_cat};
	unless (-d encode('locale_fs', $ldir)) {$status = 'Каталог с исходными данными не найден!'; return 1}
	&win_busy();
	my @files = glob encode('locale_fs', "$ldir/*_l_english.yml");
	@files = map {decode('locale_fs', $_)} @files;
	for (my $i = 0; $i < scalar(@files); $i++) {
		my $new_name = $files[$i];
		$new_name =~ s/_l_english\.yml$/_l_russian\.yml/;
		rename $files[$i], $new_name;
		open(my $file, '<:unix:perlio:utf8', encode('locale_fs', $new_name));
		my @strs;
		push(@strs, "\x{FEFF}");
		while (my $str = <$file>) {
			chomp($str);
			if ($str =~ m/\r$/) {$str =~ s/\r$//}
			if ($str =~ m/^\x{FEFF}/) {$str =~ s/^\x{FEFF}//}
			if ($str =~ m/^\#/ or $str =~ m/^ \#/ or $str =~ m/^$/ or $str =~ m/^ $/) {push(@strs, "$str\n"); next}
			if ($str =~ m/^l_english/) {$str =~ s/l_english/l_russian/; push(@strs, "$str\n"); next}
			# деление строки
			$str =~ s/^ //; # удаление начального пробела
			$str =~ m/^[^:]+:[0-9]*/p; # нахождение тэга и номера
			$str = ${^POSTMATCH}; # выбрасывание из строки найденной информации
			my ($tag, $num) = split (/:/, ${^MATCH}); # приравнивание тэга и номера соответствующим переменным
			$str =~ s/^ +//; # удаление пробела между номером и текстом
			$str =~ s/\\\"/\0/g; # замена экранированных кавычек на нулевые символы
			$str =~ m/^"[^"]*"/p; # нахождение текста //в некоторых строках нет локализации
			$str = ${^POSTMATCH}; # выбрасывание из строки найденной информации
			my $txt = ${^MATCH}; # приравнивание текста соответствующей переменной
			$txt =~ s/^"//; # удаление кавычки в начале текста
			$txt =~ s/"$//; # удаление кавычки в конце текста
			$txt =~ s/\0/\\\"/g; # замена нулевых символов на экранированные кавычки в тексте
			$str =~ s/\0/\\\"/g; # замена нулевых символов на экранированные кавычки в исходной строке
			# обработка строки
			$txt =~ y/Ђѓ€ЉЊЋљњћџЎўЈҐЁЄЇІіґё№єјЅѕїАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя/€ƒˆŠŒŽšœžŸ¡¢£¥¨ª¯²³´¸¹º¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ/;
			if ($cpfl eq 'cp1251') {
				if ($new_name =~ m/converted_cultures_l_russian\.yml/) {
					$txt =~ s/\x7f\x11$/àÿ/;
				}
			}
			elsif ($cpfl eq 'cp1252pcyr') {
				$txt =~ y/^/€/;
				if ($new_name =~ m/converted_cultures_l_russian\.yml/) {
					$txt =~ s/\x7f\x11$/a÷/;
				}
			}
			# сохранение строки
			push(@strs, " $tag:$num \"$txt\"\n");
		}
		close($file);
		open(my $out, '>:unix:perlio:utf8', encode('locale_fs', $new_name));
		print $out @strs;
		close $out;
	}
	&win_unbusy();
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
	my $d = $mw -> new_toplevel();
	$d -> g_wm_title('Лицензия');
	$d -> g_wm_resizable(0, 0);
	$d -> new_ttk__label(-justify => 'left', -wraplength => '400', -text => 'The MIT License (MIT)

Copyright © 2015-2016 terqüéz <gz0@ro.ru>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.') -> g_pack();
	$d -> new_ttk__button(-text => 'Ок', -command => sub{$d -> g_destroy}) -> g_pack(-expand => 1, -fill => 'x');
	$d -> g_focus;
}

sub menu_about {
=pod
Вывести сообщение о программе
=cut
	my $d = $mw -> new_toplevel();
	$d -> g_wm_title('О программе');
	$d -> g_wm_resizable(0, 0);
	$d -> new_ttk__label(-justify => 'left', -wraplength => '400', -text => "Recodenc\nВерсия: $version") -> g_pack(-side => 'left');
	$d -> new_ttk__button(-text => 'Ок', -command => sub{$d -> g_destroy()}) -> g_pack(-side => 'left');
	$d -> g_focus;
}

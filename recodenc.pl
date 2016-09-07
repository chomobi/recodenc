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
use Tk;
use Tk::NoteBook;
use Cwd;
use Encode qw(encode decode);
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $version = '0.3.1';
my $status = ''; # переменная для вывода статуса
# инициализация конфигурации
my $page_raised = 'eu4'; # идентификатор поднятой страницы
my $c2flag = '0'; # 0 = не сохранять в др. каталог; 1 = сохранять
my $catalogue1 = ''; # каталог 1
my $catalogue2 = ''; # каталог 2
my $cf2flag = '0'; # 0 = не сохранять в др. каталог; 1 = сохранять
my $cataloguef1 = ''; # каталог шрифтов 1
my $cataloguef2 = ''; # каталог шрифтов 2
my $catalogue_ck2_origru = ''; # каталог с русской локализацией CK2 (Full)
my $catalogue_ck2_origen = ''; # каталог с английской локализацией CK2
my $catalogue_ck2_saveru = ''; # каталог для сохранения скомпилированной Lite-локализации
# загрузка конфигурации
my $path = Cwd::realpath($0);
$path =~ s/.pl$/.conf/;
if (open(my $file_conf, '<:unix:perlio:utf8', $path)) {
	$page_raised = <$file_conf>; chomp($page_raised);
	$c2flag = <$file_conf>; chomp($c2flag);
	$catalogue1 = <$file_conf>; chomp($catalogue1);
	$catalogue2 = <$file_conf>; chomp($catalogue2);
	$cf2flag = <$file_conf>; chomp($cf2flag);
	$cataloguef1 = <$file_conf>; chomp($cataloguef1);
	$cataloguef2 = <$file_conf>; chomp($cataloguef2);
	$catalogue_ck2_origru = <$file_conf>; chomp($catalogue_ck2_origru);
	$catalogue_ck2_origen = <$file_conf>; chomp($catalogue_ck2_origen);
	$catalogue_ck2_saveru = <$file_conf>; chomp($catalogue_ck2_saveru);
	close($file_conf);
}
# проверка загруженной конфигурации
unless ($page_raised eq 'eu4' or $page_raised eq 'ck2' or $page_raised eq 'fnt') {$page_raised = 'eu4'}
unless ($c2flag == 0 or $c2flag == 1) {$c2flag = 0}
## рисование интерфейса
# инициализация переменных для хранения указателей на элементы интерфейса
my $mw; # главное окно
my $menu; # панель меню
my $menu_file; # меню файл
my $menu_help; # меню помощи
my $frame_notebook; # фрейм, содержащий вкладки
my $page_eu4; # вкладка EU4
my $page_ck2; # вкладка CK2
my $page_font; # вкладка шрифт
my $frame_eu4_buttons; # фрейм с кнопками действий для перекодировки
my $button_eu4_decode; # кнопка «декодировать»
my $frame_font_buttons; # фрейм кнопки действия
my $frame_ck2_buttons; # фрейм с кнопками
my $frame_buttons; # фрейм с кнопкой «закрыть»

# создание основного окна
$mw = MainWindow -> new(-class => 'Recodenc', -title => "Recodenc v$version");
	# меню
	$menu = $mw -> Menu(-type => 'menubar');
	$mw -> configure(-menu => $menu);
		# меню Файл
		$menu_file = $menu -> cascade(-label => 'Файл', -tearoff => 0);
		$menu_file -> command(-label => 'Выход', -command => [$mw => 'destroy'], -accelerator => 'Ctrl-Q');
		# меню Справка
		$menu_help = $menu -> cascade(-label => 'Справка', -compound => 'left', -tearoff => 0);
		$menu_help -> command(-label => 'Таблица транслитерации', -command => \&translittable);
		$menu_help -> command(-label => 'Лицензия', -command => \&menu_license, -accelerator => 'Ctrl-Shift-L');
		$menu_help -> command(-label => 'О программе', -command => \&menu_about, -accelerator => 'Ctrl-Shift-A');
	# панель со вкладками
	$frame_notebook = $mw -> NoteBook();
	# вкладка EU4
	$page_eu4 = $frame_notebook -> add( 'eu4', -label => 'EU4', -raisecmd => [\&save_page_raised => 'eu4']);
		# фрейм каталога №1
		$page_eu4 -> Label(-text => 'Для обработки:') -> grid(-column => '0', -row => '0', -sticky => 'w');
		$page_eu4 -> Entry(-width => '50', -textvariable => \$catalogue1) -> grid(-column => '1', -row => '0', -sticky => 'ew');
		$page_eu4 -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue1]) -> grid(-column => '2', -row => '0', -sticky => 'e');
		# фрейм каталога №2
		$page_eu4 -> Checkbutton(-text => 'Сохранить в:', -variable => \$c2flag) -> grid(-column => '0', -row => '1', -sticky => 'w');
		$page_eu4 -> Entry(-width => '50', -textvariable => \$catalogue2) -> grid(-column => '1', -row => '1', -sticky => 'ew');
		$page_eu4 -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue2]) -> grid(-column => '2', -row => '1', -sticky => 'e');
		# фрейм кнопок
		$frame_eu4_buttons = $page_eu4 -> Frame -> grid(-column => '0', -columnspan => '3', -row => '2', -sticky => 'ew');
		$frame_eu4_buttons -> Button(-text => 'Кодировать (CP1251)', -command => [\&encodelocalisation_eu4 => 'cp1251']) -> form(-left => '%0', -right => '%33');
		$frame_eu4_buttons -> Button(-text => 'Кодировать (CP1252+CYR)', -command => [\&encodelocalisation_eu4 => 'cp1252pcyr']) -> form(-left => '%33', -right => '%66');
		$frame_eu4_buttons -> Button(-text => 'Транслитерировать', -command => [\&encodelocalisation_eu4 => 'translit']) -> form(-left => '%66', -right => '%100');
	$page_eu4 -> gridColumnconfigure('1', -weight => '1');
	# вкладка CK2
	$page_ck2 = $frame_notebook -> add( 'ck2', -label => 'CK2', -raisecmd => [\&save_page_raised => 'ck2']);
		# фрейм каталога с русской локализацией (исходной)
		$page_ck2 -> Label(-text => 'Рус. лок.:') -> grid(-column => '0', -row => '0', -sticky => 'w');
		$page_ck2 -> Entry(-textvariable => \$catalogue_ck2_origru) -> grid(-column => '1', -row => '0', -sticky => 'ew');
		$page_ck2 -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue_ck2_origru]) -> grid(-column => '2', -row => '0', -sticky => 'e');
		# фрейм каталога с английской локализацией (исходной)
		$page_ck2 -> Label(-text => 'Анг. лок.:') -> grid(-column => '0', -row => '1', -sticky => 'w');
		$page_ck2 -> Entry(-textvariable => \$catalogue_ck2_origen) -> grid(-column => '1', -row => '1', -sticky => 'ew');
		$page_ck2 -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue_ck2_origen]) -> grid(-column => '2', -row => '1', -sticky => 'e');
		# фрейм каталога сохранения
		$page_ck2 -> Label(-text => 'Сохранить в:') -> grid(-column => '0', -row => '2', -sticky => 'w');
		$page_ck2 -> Entry(-textvariable => \$catalogue_ck2_saveru) -> grid(-column => '1', -row => '2', -sticky => 'ew');
		$page_ck2 -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue_ck2_saveru]) -> grid(-column => '2', -row => '2', -sticky => 'e');
		# фрейм кнопок
		$frame_ck2_buttons = $page_ck2 -> Frame -> grid(-column => '0', -columnspan => '3', -row => '3', -sticky => 'ew');
		$frame_ck2_buttons -> Button(-text => 'Кодировать (CP1252+CYR)', -command => [\&encodelocalisation_ck2 => 'cp1252pcyr']) -> form(-left => '%0', -right => '%33');
		$frame_ck2_buttons -> Button(-text => 'Транслитерировать', -command => [\&encodelocalisation_ck2 => 'translit']) -> form(-left => '%33', -right => '%66');
		$frame_ck2_buttons -> Button(-text => 'Только тэги', -command => \&ck2_tags) -> form(-left => '%66', -right => '%100');
	$page_ck2 -> gridColumnconfigure('1', -weight => '1');
	# вкладка fnt
	$page_font = $frame_notebook -> add( 'fnt', -label => 'Шрифт', -raisecmd => [\&save_page_raised => 'fnt']);
		# фрейм каталога №1
		$page_font -> Label(-text => 'Для обработки:') -> grid(-column => '0', -row => '0', -sticky => 'w');
		$page_font -> Entry(-width => '50', -textvariable => \$cataloguef1) -> grid(-column => '1', -row => '0', -sticky => 'ew');
		$page_font -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$cataloguef1]) -> grid(-column => '2', -row => '0', -sticky => 'e');
		# фрейм каталога №2
		$page_font -> Checkbutton(-text => 'Сохранить в:', -variable => \$cf2flag) -> grid(-column => '0', -row => '1', -sticky => 'w');
		$page_font -> Entry(-width => '50', -textvariable => \$cataloguef2) -> grid(-column => '1', -row => '1', -sticky => 'ew');
		$page_font -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$cataloguef2]) -> grid(-column => '2', -row => '1', -sticky => 'e');
		# фрейм кнопки
		$frame_font_buttons = $page_font -> Frame -> grid(-column => '0', -columnspan => '3', -row => '2', -sticky => 'ew');
		$frame_font_buttons -> Button(-text => 'Кодировать', -command => [\&font => '0']) -> form(-left => '%0', -right => '%33');
		$frame_font_buttons -> Button(-text => 'Кодировать (CP1252+CYR-EU4)', -command => [\&font => 'eu4']) -> form(-left => '%33', -right => '%66');
		$frame_font_buttons -> Button(-text => 'Кодировать (CP1252+CYR-CK2)', -command => [\&font => 'ck2']) -> form(-left => '%66', -right => '%100');
	$page_font -> gridColumnconfigure('1', -weight => '1');
	# статусная строка и кнопка закрытия
	$frame_buttons = $mw -> Frame;
	$frame_buttons -> Label(-anchor => 'w' ,-relief => 'flat', -textvariable => \$status) -> pack(-expand => '1', -fill => 'x', -side => 'left'); # строка статуса
	$frame_buttons -> Button(-text => 'Закрыть', -command => [$mw => 'destroy']) -> pack(-side => 'right');
# фреймы верхнего уровня
$frame_notebook -> grid(-column => '0', -row => '0', -sticky => 'nsew');
$frame_buttons -> grid(-column => '0', -row => '1', -sticky => 'sew');
$mw -> gridColumnconfigure(0, -weight => 1);
$mw -> gridRowconfigure(0, -weight => 1);
$mw -> resizable(1,0);
# упреждающее применение настроек
$frame_notebook -> raise("$page_raised");
# привязки к горячим клавишам
$mw -> bind('<Control-q>' => [$mw => 'destroy']);

MainLoop;

# запись конфигурации
open(my $file_conf_o, '>:unix:perlio:utf8', $path);
my @strscf;
push(@strscf, "$page_raised\n");
push(@strscf, "$c2flag\n");
push(@strscf, "$catalogue1\n");
push(@strscf, "$catalogue2\n");
push(@strscf, "$cf2flag\n");
push(@strscf, "$cataloguef1\n");
push(@strscf, "$cataloguef2\n");
push(@strscf, "$catalogue_ck2_origru\n");
push(@strscf, "$catalogue_ck2_origen\n");
push(@strscf, "$catalogue_ck2_saveru\n");
print $file_conf_o @strscf;
close $file_conf_o;

################
# ПОДПРОГРАММЫ #
################
# Конвертор файлов локализации EU4
# ПРОЦЕДУРА
sub encodelocalisation_eu4 {
	my $cpfl = shift; # cp1251 — CP1251; cp1252pcyr — CP1252+CYR; translit — транслит
	my $c2fl = $c2flag; # 0 — перезаписать; 1 — сохранить в другое место
	my $dir1 = $catalogue1; # каталог №1
	my $dir2 = $catalogue2; # каталог №2
	# проверка параметров
	unless (-d $dir1) {$status = 'Каталог с исходными данными не найден!'; return 1};
	if ($c2fl == 1) {unless (-d $dir2) {$status = 'Каталог для сохранения не найден!'; return 1}};
	# работа
	&win_busy();
	opendir(my $ch, $dir1);
	my @files = grep { ! /^\.\.?\z/ } readdir $ch;
	closedir($ch);
	for (my $i = 0; $i < scalar(@files); $i++) {
		unless (-T "$dir1/$files[$i]") {next}
		open(my $file, '<:unix:perlio:utf8', "$dir1/$files[$i]");
		my $fl = 0; # флаг нужности/ненужности обработки строк
		my @strs; # объявление хранилища строк
		push(@strs, "\x{FEFF}"); # добавление BOM в начало файла
		while (my $str = <$file>) {
			chomp $str;
			if ($str =~ m/\r$/) {$str =~ s/\r$//} # защита от идиотов, подающих на вход CRLF
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
			# сохранение строки
			if (length($cmm) > 0) {
				push(@strs, " $tag:$num \"$txt\" #$cmm\n");
				next;
			}
			push(@strs, " $tag:$num \"$txt\"\n");
		}
		close($file);
		if ($c2fl == 0) {
			open(my $out, '>:unix:perlio:utf8', "$dir1/$files[$i]");
			print $out @strs;
			close $out;
		}
		elsif ($c2fl == 1) {
			open(my $out, '>:unix:perlio:utf8', "$dir2/$files[$i]");
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
	my $dir_orig_en = $catalogue_ck2_origen;
	my $dir_orig_ru = $catalogue_ck2_origru;
	my $dir_save_ru = $catalogue_ck2_saveru;
	unless (-d $dir_orig_en) {$status = 'Не найден каталог с английской локализацией!'; return 1}
	unless (-d $dir_orig_ru) {$status = 'Не найден каталог с русской локализацией!'; return 1}
	unless (-d $dir_save_ru) {$status = 'Не найден каталог для сохранения локализации!'; return 1}
	&win_busy();
	my %loc_ru;
	opendir(my $corh, $dir_orig_ru);
	my @files_or = grep { ! /^\.\.?\z/ } readdir $corh;
	closedir($corh);
	for (my $i = 0; $i < scalar(@files_or); $i++) {
		unless (-T "$dir_orig_ru/$files_or[$i]") {next}
		open(my $fh, '<:raw', "$dir_orig_ru/$files_or[$i]");
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
	opendir(my $coeh, $dir_orig_en);
	my @files_oe = grep { ! /^\.\.?\z/ } readdir $coeh;
	closedir($coeh);
	for (my $i = 0; $i < scalar(@files_oe); $i++) {
		unless (-T "$dir_orig_en/$files_oe[$i]") {next}
		open(my $fh, '<:raw', "$dir_orig_en/$files_oe[$i]");
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
		open(my $ffh, '>:unix:crlf:encoding(cp1252)', "$dir_save_ru/$files_oe[$i]");
		print $ffh @strs;
		close($ffh);
	}
	&win_unbusy();
}

# Вывод тэгов локализации CK2
# ПРОЦЕДУРА
sub ck2_tags {
	my $dir_orig_en = $catalogue_ck2_origen;
	my $dir_orig_ru = $catalogue_ck2_origru;
	my $dir_save_ru = $catalogue_ck2_saveru;
	unless (-d $dir_orig_en) {$status = 'Не найден каталог с английской локализацией!'; return 1}
	unless (-d $dir_orig_ru) {$status = 'Не найден каталог с русской локализацией!'; return 1}
	unless (-d $dir_save_ru) {$status = 'Не найден каталог для сохранения локализации!'; return 1}
	&win_busy();
	opendir(my $corh, $dir_orig_ru);
	my @files_or = grep { ! /^\.\.?\z/ } readdir $corh;
	closedir($corh);
	mkdir("$dir_save_ru/ru");
	for (my $i = 0; $i < scalar(@files_or); $i++) {
		unless (-T "$dir_orig_ru/$files_or[$i]") {next}
		open(my $fh, '<:raw', "$dir_orig_ru/$files_or[$i]");
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
		open(my $ffh, '>:unix:perlio:utf8', "$dir_save_ru/ru/$files_or[$i]");
		print $ffh @strs;
		close($ffh);
	}
	opendir(my $coeh, $dir_orig_en);
	my @files_oe = grep { ! /^\.\.?\z/ } readdir $coeh;
	closedir($coeh);
	mkdir("$dir_save_ru/en");
	for (my $i = 0; $i < scalar(@files_oe); $i++) {
		unless (-T "$dir_orig_en/$files_oe[$i]") {next}
		open(my $fh, '<:raw', "$dir_orig_en/$files_oe[$i]");
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
		open(my $ffh, '>:unix:perlio:utf8', "$dir_save_ru/en/$files_oe[$i]");
		print $ffh @strs;
		close($ffh);
	}
	&win_unbusy();
}

# Очистка и модификация карт шрифтов
# ПРОЦЕДУРА
sub font { # изменяет fnt-карты шрифтов
	my $cpfl = shift;#0 — не трогать; eu4 — обработка CP1252+CYR-EU4; ck2 — обработка CP1252+CYR-CK2
	my $c2fl = $cf2flag;#0 — перезаписать; 1 — сохранить в другое место
	my $dir1 = $cataloguef1;#каталог №1
	my $dir2 = $cataloguef2;#каталог №2
	unless (-d $dir1) {$status = 'Каталог с исходными данными не найден!'; return 1}
	if ($c2fl == 1) {unless (-d $dir2) {$status = 'Каталог для сохранения не найден!'; return 1}}
	&win_busy();
	opendir(my $ch, $dir1);
	my @files = grep { ! /^\.\.?\z/ } readdir $ch;
	closedir($ch);
	for (my $i = 0; $i < scalar(@files); $i++) {
		unless (-T "$dir1/$files[$i]") {next}
		open(my $file_in, '<:unix:crlf', "$dir1/$files[$i]");
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
			@strs[2..$kr] = sort {&srt($a, $b)} @strs[2..$kr];# участок массива от третьей строки до последней строки перед m/^kernings/ или концом файла сортируется по числам столбца id=
		}
		# /сортировка
		if ($c2fl == 0) {
			open(my $file_out, '>:unix:crlf', "$dir1/$files[$i]");
			print $file_out @strs;
			close($file_out);
		}
		elsif ($c2fl == 1) {
			open(my $file_out, '>:unix:crlf', "$dir2/$files[$i]");
			print $file_out @strs;
			close($file_out);
		}
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
		$str =~ y/‚‹‘’–—› €ƒ†‡ˆ‰•˜™¢¥¦¨©ª¬®¯°±²³´µ¶·¸¹º¼½¾×÷/''''\-\-' /d;
		$str =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/A€B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷/;
	}
	elsif ($reg eq 'ck2') {
		$str =~ y/‚„‹‘’“”–—› «»^€ƒ†‡ˆ‰•˜™¢¥¦¨©ª¬®¯°±²³´µ¶·¸¹º¼½¾×÷/'"'''""\-\-' ""/d;
		$str =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/A^B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷/;
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

#
# Подпрограммы поддержки графического интерфейса
#

sub translittable {
=pod
Показывает таблицу транслитерации
=cut
	my $d = $mw -> Toplevel(-title => 'Таблица транслитерации');
	$d -> resizable(0,0);
	$d -> Label(-justify => 'left', -text =>
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
ь — Yy") -> pack();
	$d -> Button(-text => 'Ок', -command => [$d => 'destroy']) -> pack(-expand => 1, -fill => 'x');
	$d -> focus;
}

sub seldir {
=pod
Вызывает диалог выбора каталога и записывает выбранное значение в переменную с именем каталога
параметр: ссылка на переменную, в которую записывать значение
=cut
	my $dir = shift;
	my $sdir = $mw -> chooseDirectory;
	if (defined $sdir and $sdir ne '') {
		$$dir = $sdir;
	}
}

sub save_page_raised {
=pod
Сохраняет в переменную текущую открытую вкладку
=cut
	my $rp = shift;
	$page_raised = $rp;
}

sub win_busy {
=pod
Занять окно
=cut
	$status = 'Обработка ...';
	$mw -> Busy(-recurse => 1);
}

sub win_unbusy {
=pod
Вернуть управление окном пользователю
=cut
	$mw -> Unbusy;
	$status = 'Готово!';
}

sub menu_license {
=pod
Вывести текст лицензии
=cut
	my $d = $mw -> Toplevel(-title => 'Лицензия');
	$d -> resizable(0,0);
	$d -> Label(-justify => 'left', -wraplength => '400', -text => 'The MIT License (MIT)

Copyright © 2015-2016 terqüéz <gz0@ro.ru>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.') -> pack();
	$d -> Button(-text => 'Ок', -command => [$d => 'destroy']) -> pack(-expand => 1, -fill => 'x');
	$d -> focus;
}

sub menu_about {
=pod
Вывести сообщение о программе
=cut
	my $d = $mw -> Toplevel(-title => 'О программе');
	$d -> resizable(0,0);
	$d -> Label(-justify => 'left', -wraplength => '400', -text => "Recodenc\nВерсия: $version") -> pack(-side => 'left');
	$d -> Button(-text => 'Ок', -command => [$d => 'destroy']) -> pack(-side => 'left');
	$d -> focus;
}

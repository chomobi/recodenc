#!/usr/bin/perl
################################################################################
# ******************************************************************************
# * 
# ******************************************************************************
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
use Tk;
use Tk::LabFrame;
use Tk::MsgBox;
use Tk::NoteBook;
use Cwd;
use Encode qw(encode decode);
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

my $version = 'v0.2.5';
my $status = ''; # переменная для вывода статуса
# инициализация конфигурации
my $cpflag = '1';
my $c2flag = '0';
my $catalogue1 = '';
my $catalogue2 = '';
my $cf2flag = '0';
my $cataloguef1 = '';
my $cataloguef2 = '';
my $catalogue_ck2_origru = ''; # каталог с русской локализацией CK2 (Full)
my $catalogue_ck2_origen = ''; # каталог с английской локализацией CK2
my $catalogue_ck2_saveru = ''; # каталог для сохранения скомпилированной Lite-локализации
# загрузка конфигурации
my $path = Cwd::realpath($0);
$path =~ s/.pl$/.conf/;
if (open(my $file_conf, '<:unix:perlio:utf8', $path)) {
	$cpflag = <$file_conf>; chomp($cpflag); # 1 = CP1251; 2 = CP1252+CYR
	$c2flag = <$file_conf>; chomp($c2flag); # 0 = не сохранять в др. каталог; 1 = сохранять
	$catalogue1 = <$file_conf>; chomp($catalogue1); # каталог 1
	$catalogue2 = <$file_conf>; chomp($catalogue2); # каталог 2
	$cf2flag = <$file_conf>; chomp($cf2flag); # 0 = не сохранять в др. каталог; 1 = сохранять
	$cataloguef1 = <$file_conf>; chomp($cataloguef1); # каталог шрифтов 1
	$cataloguef2 = <$file_conf>; chomp($cataloguef2); # каталог шрифтов 2
	$catalogue_ck2_origru = <$file_conf>; chomp($catalogue_ck2_origru);
	$catalogue_ck2_origen = <$file_conf>; chomp($catalogue_ck2_origen);
	$catalogue_ck2_saveru = <$file_conf>; chomp($catalogue_ck2_saveru);
	close($file_conf);
}
# проверка загруженной конфигурации
unless ($cpflag == 1 or $cpflag == 2 or $cpflag == 3) {$cpflag = 1}
unless ($c2flag == 0 or $c2flag == 1) {$c2flag = 0}
## рисование интерфейса
# инициализация переменных для хранения указателей на элементы интерфейса
my $mw; # главное окно
my $frame_notebook; # фрейм, содержащий вкладки
my $page_eu4; # вкладка EU4
my $page_eu4font; # вкладка EU4 шрифт
my $page_ck2; # вкладка CK2
my $frame_eu4_selcp; # фрейм с выбором кодировки
my $frame_eu4_entry; # фрейм для текстового поля с первым каталогом
my $frame_eu4_entrysave; # фрейм для тектового поля со вторым каталогом
my $frame_eu4_buttons; # фрейм с кнопками действий для перекодировки
my $eu4_decode_button; # кнопка «декодировать»
my $frame_eu4font_entry; # фрейм для текстового поля с первым каталогом
my $frame_eu4font_entrysave; # фрейм для тектового поля со вторым каталогом
my $frame_eu4font_button; # фрейм кнопки действия
my $frame_ck2_entry_origru;
my $frame_ck2_entry_origen;
my $frame_ck2_entry_saveru;
my $frame_ck2_buttons;
my $frame_buttons; # фрейм с кнопкой «закрыть»

# создание основного окна
$mw = MainWindow -> new(-class => 'Recodenc', -title => "Recodenc $version");
	$frame_notebook = $mw -> NoteBook();
	# вкладка EU4
	$page_eu4 = $frame_notebook -> add( 'eu4', -label => 'EU4');
		# фрейм выбора кодировки
		$frame_eu4_selcp = $page_eu4 -> Frame;
		$frame_eu4_selcp -> Radiobutton(-text => 'CP1251', -variable => \$cpflag, -value => '1', -command => \&eu4_valcp) -> pack(-side => 'left');
		$frame_eu4_selcp -> Radiobutton(-text => 'CP1252+CYR', -variable => \$cpflag, -value => '2', -command => \&eu4_invcp) -> pack(-side => 'left');
		$frame_eu4_selcp -> Radiobutton(-text => 'транслит', -variable => \$cpflag, -value => '3', -command => \&eu4_invcp) -> pack(-side => 'left');
		$frame_eu4_selcp -> Button(-text => 'Таблица транслитерации', -command => \&translittable) -> pack(-side => 'right');
		# фрейм каталога №1
		$frame_eu4_entry = $page_eu4 -> Frame;
		$frame_eu4_entry -> Entry(-width => '50', -textvariable => \$catalogue1) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4_entry -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue1]) -> pack(-side => 'right');
		# фрейм каталога №2
		$frame_eu4_entrysave = $page_eu4 -> Frame;
		$frame_eu4_entrysave -> Checkbutton(-text => 'Сохранить в:', -variable => \$c2flag) -> pack(-side => 'left');
		$frame_eu4_entrysave -> Entry(-width => '50', -textvariable => \$catalogue2) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4_entrysave -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue2]) -> pack(-side => 'right');
		# фрейм кнопок
		$frame_eu4_buttons = $page_eu4 -> Frame;
		$frame_eu4_buttons -> Button(-text => 'Кодировать', -command => [\&encodelocalisation => 0]) -> form(-left => '%0', -right => '%50');
		$eu4_decode_button = $frame_eu4_buttons -> Button(-text => 'Декодировать', -command => [\&encodelocalisation => 1]) -> form(-left => '%50', -right => '%100');
	# вкладка CK2
	$page_ck2 = $frame_notebook -> add( 'ck2', -label => 'CK2');
		# фрейм каталога с русской локализацией (исходной)
		$frame_ck2_entry_origru = $page_ck2 -> Frame;
		$frame_ck2_entry_origru -> Label(-text => 'Рус. лок.:') -> pack(-side => 'left');
		$frame_ck2_entry_origru -> Entry(-textvariable => \$catalogue_ck2_origru) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_ck2_entry_origru -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue_ck2_origru]) -> pack(-side => 'right');
		# фрейм каталога с английской локализацией (исходной)
		$frame_ck2_entry_origen = $page_ck2 -> Frame;
		$frame_ck2_entry_origen -> Label(-text => 'Анг. лок.:') -> pack(-side => 'left');
		$frame_ck2_entry_origen -> Entry(-textvariable => \$catalogue_ck2_origen) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_ck2_entry_origen -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue_ck2_origen]) -> pack(-side => 'right');
		# фрейм каталога сохранения
		$frame_ck2_entry_saveru = $page_ck2 -> Frame;
		$frame_ck2_entry_saveru -> Label(-text => 'Сохранить в:') -> pack(-side => 'left');
		$frame_ck2_entry_saveru -> Entry(-textvariable => \$catalogue_ck2_saveru) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_ck2_entry_saveru -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue_ck2_saveru]) -> pack(-side => 'right');
		# фрейм кнопок
		$frame_ck2_buttons = $page_ck2 -> Frame;
		$frame_ck2_buttons -> Button(-text => 'Кодировать', -command => [\&encodelocalisation_ck2 => '0', $catalogue_ck2_origen, $catalogue_ck2_origru, $catalogue_ck2_saveru]) -> form(-left => '%0', -right => '%50');
		$frame_ck2_buttons -> Button(-text => 'Транслитерировать', -command => [\&encodelocalisation_ck2 => '1', $catalogue_ck2_origen, $catalogue_ck2_origru, $catalogue_ck2_saveru]) -> form(-left => '%50', -right => '%100');
	# вкладка EU4 fnt
	$page_eu4font = $frame_notebook -> add( 'eu4_script', -label => 'Шрифт');
		# фрейм каталога №1
		$frame_eu4font_entry = $page_eu4font -> Frame;
		$frame_eu4font_entry -> Entry(-width => '50', -textvariable => \$cataloguef1) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4font_entry -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$cataloguef1]) -> pack(-side => 'right');
		# фрейм каталога №2
		$frame_eu4font_entrysave = $page_eu4font ->Frame;
		$frame_eu4font_entrysave -> Checkbutton(-text => 'Сохранить в:', -variable => \$cf2flag) -> pack(-side => 'left');
		$frame_eu4font_entrysave -> Entry(-width => '50', -textvariable => \$cataloguef2) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4font_entrysave -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$cataloguef2]) -> pack(-side => 'right');
		# фрейм кнопки
		$frame_eu4font_button = $page_eu4font -> Frame;
		$frame_eu4font_button -> Button(-text => 'Кодировать', -command => [\&font => '1']) -> form(-left => '%0', -right => '%33');
		$frame_eu4font_button -> Button(-text => 'Кодировать (CP1252+CYR-EU4)', -command => [\&font => '2']) -> form(-left => '%33', -right => '%66');
		$frame_eu4font_button -> Button(-text => 'Кодировать (CP1252+CYR-CK2)', -command => [\&font => '3']) -> form(-left => '%66', -right => '%100');
	$frame_buttons = $mw -> Frame;
	$frame_buttons -> Label(-anchor => 'w' ,-relief => 'flat', -textvariable => \$status) -> pack(-expand => '1', -fill => 'x', -side => 'left'); # строка статуса
	$frame_buttons -> Button(-text => 'Закрыть', -command => [$mw => 'destroy']) -> pack(-side => 'right');
# фреймы верхнего уровня
$frame_notebook -> form(-top => '%0', -left => '%0', -right => '%100');
$frame_buttons -> form(-top => $frame_notebook, -left => '%1', -right => '%99');
# фреймы EU4
$frame_eu4_selcp -> form(-top => '%0', -left => '%0', -right => '%100');
$frame_eu4_entry -> form(-top => $frame_eu4_selcp, -left => '%0', -right => '%100');
$frame_eu4_entrysave -> form(-top => $frame_eu4_entry, -left => '%0', -right => '%100');
$frame_eu4_buttons -> form(-top => $frame_eu4_entrysave, -left => '%0', -right => '%100');
# фреймы EU4-fnt
$frame_eu4font_entry -> form(-top => '%0', -left => '%0', -right => '%100');
$frame_eu4font_entrysave -> form(-top => $frame_eu4font_entry, -left => '%0', -right => '%100');
$frame_eu4font_button -> form(-top => $frame_eu4font_entrysave, -left => '%0', -right => '%100');
# фреймы CK2
$frame_ck2_entry_origru -> form(-top => '%0', -left => '%0', -right => '%100');
$frame_ck2_entry_origen -> form(-top => $frame_ck2_entry_origru, -left => '%0', -right => '%100');
$frame_ck2_entry_saveru -> form(-top => $frame_ck2_entry_origen, -left => '%0', -right => '%100');
$frame_ck2_buttons -> form(-top => $frame_ck2_entry_saveru, -left => '%0', -right => '%100');

if ($cpflag == 2 or $cpflag == 3) {&eu4_invcp()};

MainLoop;

# запись конфигурации
open(my $file_conf_o, '>:unix:perlio:utf8', $path);
my @strscf;
push(@strscf, "$cpflag\n");
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
sub encodelocalisation { # перекодировка файлов
	my $opfl = shift;#0 — кодировка; 1 — декодировка
	my $c2fl = $c2flag;#0 — перезаписать; 1 — сохранить в другое место
	my $cpfl = $cpflag;#1 — CP1251; 2 — CP1252+CYR; 3 — транслит
	my $dir1 = $catalogue1;#каталог №1
	my $dir2 = $catalogue2;#каталог №2
	# проверка параметров
	unless (-d $dir1) {$status = 'Каталог с исходными данными не найден!'; return 1};
	if ($c2fl == 1) {unless (-d $dir2) {$status = 'Каталог для сохранения не найден!'; return 1}};
	# работа
	$status = 'Обработка ...';
	$mw -> Busy(-recurse => 1);
	opendir(my $ch, $dir1);
	my @files = grep { ! /^\.\.?\z/ } readdir $ch;
	closedir($ch);
	for (my $i = 0; $i < scalar(@files); $i++) {
		unless (-T "$dir1/$files[$i]") {next}
		open(my $file, '<:unix:perlio:utf8', "$dir1/$files[$i]");
		my @strs; # объявление хранилища строк
		push(@strs, "\x{FEFF}"); # добавление BOM в начало файла
		while (my $str = <$file>) {
			chomp $str;
			if ($str =~ m/\r$/) {$str =~ s/\r$//} # защита от идиотов, подающих на вход CRLF
			if ($str =~ m/^\x{FEFF}/) {$str =~ s/^\x{FEFF}//} # удаление BOM из обрабатываемых строк
			if ($str =~ m/^\#/) {push(@strs, "$str\n"); next}
			if ($str =~ m/^ \#/) {push(@strs, "$str\n"); next}
			if ($str =~ m/^$/) {push(@strs, "$str\n"); next}
			if ($str =~ m/^ $/) {push(@strs, "$str\n"); next}
			my @sps = split(/:/, $str, '2');
			if    ($cpfl == 1 and $opfl == 0) {
				$sps[1] =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ/;
			}
			elsif ($cpfl == 2 and $opfl == 0) {
				$sps[1] =~ s/„/\\\"/g;
				$sps[1] =~ s/…/.../g;
				$sps[1] =~ s/“/\\\"/g;
				$sps[1] =~ s/”/\\\"/g;
				$sps[1] =~ s/™/(tm)/g;
				$sps[1] =~ s/©/(c)/g;
				$sps[1] =~ s/«/\\\"/g;
				$sps[1] =~ s/®/(r)/g;
				$sps[1] =~ s/±/+-/g;
				$sps[1] =~ s/»/\\\"/g;
				$sps[1] =~ tr/‚ƒ†‡‰‹‘’•–—˜› ¦ª°²³´µ·¹º€ˆ¢¥¨¬¯¶¸¼½¾×÷/'f++%'''*\-\-~' lao23'm.1o/d;
				$sps[1] =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/A€B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷/;
			}
			elsif ($cpfl == 3 and $opfl == 0) {
				$sps[1] =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/ABVGDEËJZIYKLMNOPRSTUFHQCXÇ’ÎYÊÜÄabvgdeëjziyklmnoprstufhqcxç’îyêüä/;
			}
			elsif ($cpfl == 1 and $opfl == 1) {
				$sps[1] =~ y/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/;
			}
			push(@strs, "$sps[0]:$sps[1]\n");
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
	$mw -> Unbusy;
	$status = 'Готово!';
}

sub encodelocalisation_ck2 {
	my $cpfl = shift;#0 — CP1252+CYR; 1 — транслит
	my $dir_orig_en = shift;
	my $dir_orig_ru = shift;
	my $dir_save_ru = shift;
	unless (-d $dir_orig_en) {$status = 'Не найден каталог с английской локализацией!'; return 1}
	unless (-d $dir_orig_ru) {$status = 'Не найден каталог с русской локализацией!'; return 1}
	unless (-d $dir_save_ru) {$status = 'Не найден каталог для сохранения локализации!'; return 1}
	$status = 'Обработка ...';
	$mw -> Busy(-recurse => 1);
	my %loc_ru;
	opendir(my $corh, $dir_orig_ru);
	my @files_or = grep { ! /^\.\.?\z/ } readdir $corh;
	closedir($corh);
	for (my $i = 0; $i < scalar(@files_or); $i++) {
		open(my $fh, '<:raw', "$dir_orig_ru/$files_or[$i]");
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
			$trns =~ tr/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/;
			$loc_ru{$tag} = $trns;
		}
		close($fh);
	}
	opendir(my $coeh, $dir_orig_en);
	my @files_oe = grep { ! /^\.\.?\z/ } readdir $coeh;
	closedir($coeh);
	for (my $i = 0; $i < scalar(@files_oe); $i++) {
		open(my $fh, '<:raw', "$dir_orig_en/$files_oe[$i]");
		my $ff; # флаг содержания файла
		my @strs;
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
			if ($tag =~ m/^PROV[1-9]/ or $tag =~ m/^b_/ or $tag =~ m/^c_/ or $tag =~ m/^d_/ or $tag =~ m/^e_/ or $tag =~ m/^k_/ or $tag =~ m/^W_L_[1-9]/) {
				$st = "$tag;$trns;x\n";
			}
			elsif (defined($loc_ru{$tag})) {
				my $trru = $loc_ru{$tag};
				if ($cpfl eq '0') {
					$trru =~ tr/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/A^B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷/;
				}
				elsif ($cpfl eq '1') {
					$trru =~ tr/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/ABVGDEËJZIYKLMNOPRSTUFHQCXÇ’ÎYÊÜÄabvgdeëjziyklmnoprstufhqcxç’îyêüä/;
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
	$mw -> Unbusy;
	$status = 'Готово!';
}

sub font { # изменяет fnt-карты шрифтов
	my $cpfl = shift;#1 — не трогать; 2 — обработка CP1252+CYR-EU4; 3 — обработка CP1252+CYR-CK2
	my $c2fl = $cf2flag;#0 — перезаписать; 1 — сохранить в другое место
	my $dir1 = $cataloguef1;#каталог №1
	my $dir2 = $cataloguef2;#каталог №2
	unless (-d $dir1) {$status = 'Каталог с исходными данными не найден!'; return 1}
	if ($c2fl == 1) {unless (-d $dir2) {$status = 'Каталог для сохранения не найден!'; return 1}}
	$status = 'Обработка ...';
	$mw -> Busy(-recurse => 1);
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
				if ($cpfl eq 2 or $cpfl eq 3) {#если CP1252+CYR, то заменить номера символов
					$str_id[1] =~ s/352/138/;
					$str_id[1] =~ s/353/154/;
					$str_id[1] =~ s/338/140/;
					$str_id[1] =~ s/339/156/;
					$str_id[1] =~ s/381/142/;
					$str_id[1] =~ s/382/158/;
					$str_id[1] =~ s/376/159/;
					if ($cpfl eq 2) {
						$str_id[1] =~ s/1041/128/;
					}
					elsif ($cpfl eq 3) {
						$str_id[1] =~ s/1041/94/;
					}
					$str_id[1] =~ s/1043/130/;
					$str_id[1] =~ s/1044/131/;
					$str_id[1] =~ s/1046/132/;
					$str_id[1] =~ s/1047/133/;
					$str_id[1] =~ s/1048/134/;
					$str_id[1] =~ s/1049/135/;
					$str_id[1] =~ s/1051/136/;
					$str_id[1] =~ s/1055/137/;
					$str_id[1] =~ s/1059/139/;
					$str_id[1] =~ s/1060/145/;
					$str_id[1] =~ s/1062/146/;
					$str_id[1] =~ s/1063/147/;
					$str_id[1] =~ s/1064/148/;
					$str_id[1] =~ s/1065/149/;
					$str_id[1] =~ s/1066/150/;
					$str_id[1] =~ s/1067/151/;
					$str_id[1] =~ s/1068/152/;
					$str_id[1] =~ s/1069/153/;
					$str_id[1] =~ s/1070/155/;
					$str_id[1] =~ s/1073/160/;
					$str_id[1] =~ s/1074/162/;
					$str_id[1] =~ s/1075/165/;
					$str_id[1] =~ s/1076/166/;
					$str_id[1] =~ s/1078/168/;
					$str_id[1] =~ s/1079/169/;
					$str_id[1] =~ s/1080/170/;
					$str_id[1] =~ s/1081/171/;
					$str_id[1] =~ s/1082/172/;
					$str_id[1] =~ s/1083/174/;
					$str_id[1] =~ s/1084/175/;
					$str_id[1] =~ s/1085/176/;
					$str_id[1] =~ s/1087/177/;
					$str_id[1] =~ s/1090/178/;
					$str_id[1] =~ s/1091/179/;
					$str_id[1] =~ s/1092/180/;
					$str_id[1] =~ s/1094/181/;
					$str_id[1] =~ s/1095/182/;
					$str_id[1] =~ s/1096/183/;
					$str_id[1] =~ s/1097/184/;
					$str_id[1] =~ s/1098/185/;
					$str_id[1] =~ s/1099/186/;
					$str_id[1] =~ s/1100/187/;
					$str_id[1] =~ s/1101/188/;
					$str_id[1] =~ s/1102/190/;
					$str_id[1] =~ s/1071/215/;
					$str_id[1] =~ s/1103/247/;
				}
				delete $str_id[10];
				push(@strs, "@str_id\n"); next;
			}
			if ($str =~ m/^kerning/) {
				my @str_kerning = split(" ", $str);
				if ($cpfl eq 2 or $cpfl eq 3) {#если CP1252+CYR, то заменить номера сомволов
					for my $i (1, 2) {
						# заменяет номера во втором и третьем столбце
						$str_kerning[$i] =~ s/352/138/;
						$str_kerning[$i] =~ s/353/154/;
						$str_kerning[$i] =~ s/338/140/;
						$str_kerning[$i] =~ s/339/156/;
						$str_kerning[$i] =~ s/381/142/;
						$str_kerning[$i] =~ s/382/158/;
						$str_kerning[$i] =~ s/376/159/;
						if ($cpfl eq 2) {
							$str_kerning[$i] =~ s/1041/128/;
						}
						elsif ($cpfl eq 3) {
							$str_kerning[$i] =~ s/1041/94/;
						}
						$str_kerning[$i] =~ s/1043/130/;
						$str_kerning[$i] =~ s/1044/131/;
						$str_kerning[$i] =~ s/1046/132/;
						$str_kerning[$i] =~ s/1047/133/;
						$str_kerning[$i] =~ s/1048/134/;
						$str_kerning[$i] =~ s/1049/135/;
						$str_kerning[$i] =~ s/1051/136/;
						$str_kerning[$i] =~ s/1055/137/;
						$str_kerning[$i] =~ s/1059/139/;
						$str_kerning[$i] =~ s/1060/145/;
						$str_kerning[$i] =~ s/1062/146/;
						$str_kerning[$i] =~ s/1063/147/;
						$str_kerning[$i] =~ s/1064/148/;
						$str_kerning[$i] =~ s/1065/149/;
						$str_kerning[$i] =~ s/1066/150/;
						$str_kerning[$i] =~ s/1067/151/;
						$str_kerning[$i] =~ s/1068/152/;
						$str_kerning[$i] =~ s/1069/153/;
						$str_kerning[$i] =~ s/1070/155/;
						$str_kerning[$i] =~ s/1073/160/;
						$str_kerning[$i] =~ s/1074/162/;
						$str_kerning[$i] =~ s/1075/165/;
						$str_kerning[$i] =~ s/1076/166/;
						$str_kerning[$i] =~ s/1078/168/;
						$str_kerning[$i] =~ s/1079/169/;
						$str_kerning[$i] =~ s/1080/170/;
						$str_kerning[$i] =~ s/1081/171/;
						$str_kerning[$i] =~ s/1082/172/;
						$str_kerning[$i] =~ s/1083/174/;
						$str_kerning[$i] =~ s/1084/175/;
						$str_kerning[$i] =~ s/1085/176/;
						$str_kerning[$i] =~ s/1087/177/;
						$str_kerning[$i] =~ s/1090/178/;
						$str_kerning[$i] =~ s/1091/179/;
						$str_kerning[$i] =~ s/1092/180/;
						$str_kerning[$i] =~ s/1094/181/;
						$str_kerning[$i] =~ s/1095/182/;
						$str_kerning[$i] =~ s/1096/183/;
						$str_kerning[$i] =~ s/1097/184/;
						$str_kerning[$i] =~ s/1098/185/;
						$str_kerning[$i] =~ s/1099/186/;
						$str_kerning[$i] =~ s/1100/187/;
						$str_kerning[$i] =~ s/1101/188/;
						$str_kerning[$i] =~ s/1102/190/;
						$str_kerning[$i] =~ s/1071/215/;
						$str_kerning[$i] =~ s/1103/247/;
					}
				}
				push(@strs, "@str_kerning\n"); next;
			}
		}
		close($file_in);
		# сортировка
		if ($cpfl eq 2 or $cpfl eq 3) {#если CP1252+CYR, то сортировать
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
	$mw -> Unbusy;
	$status = 'Готово!';
}

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

#
# Подпрограммы поддержки графического интерфейса
#

sub eu4_invcp {
	$eu4_decode_button -> configure(-state => 'disabled');
}

sub eu4_valcp {
	$eu4_decode_button -> configure(-state => 'normal');
}

sub translittable {
=pod
Показывает таблицу транслитерации
=cut
	my $d = $mw -> MsgBox(
	-type => 'ok',
	-title => 'Таблица транслитерации',
	-message =>
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
ь — Yy");
	$d -> Show();
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

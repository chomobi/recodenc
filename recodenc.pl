#!/usr/bin/perl
################################################################################
# ******************************************************************************
# * 
# ******************************************************************************
################################################################################
use utf8;
use v5.18;
use warnings;
use Tk;
use Tk::LabFrame;
use Tk::MsgBox;
use Cwd;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
BEGIN {
	if ($^O eq 'MSWin32') {
		require Win32::Console;
		Win32::Console::Free();
	}
}

my $version = 'v0.2.2';
my $status = ''; # переменная для вывода статуса
# инициализация конфигурации
my $cpflag = '1';
my $c2flag = '0';
my $catalogue1 = '';
my $catalogue2 = '';
my $cf2flag = '0';
my $cataloguef1 = '';
my $cataloguef2 = '';
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
	close($file_conf);
}
# проверка загруженной конфигурации
unless ($cpflag == 1 or $cpflag == 2 or $cpflag == 3) {$cpflag = 1}
unless ($c2flag == 0 or $c2flag == 1) {$c2flag = 0}
## рисование интерфейса
# инициализация переменных для хранения указателей на элементы интерфейса

my $mw; # главное окно
my $frame_eu4; # рамка EU4
my $frame_eu4_selcp; # фрейм с выбором кодировки
my $frame_eu4_entry; # фрейм для текстового поля с первым каталогом
my $frame_eu4_entrysave; # фрейм для тектового поля со вторым каталогом
my $frame_eu4_buttons; # фрейм с кнопками действий для перекодировки
my $eu4_decode_button; # кнопка «декодировать»
my $frame_eu4font; # рамка EU4 fnt
my $frame_eu4font_entry; # фрейм для текстового поля с первым каталогом
my $frame_eu4font_entrysave; # фрейм для тектового поля со вторым каталогом
my $frame_eu4font_button; # фрейм кнопки действия
my $frame_ck2; # рамка CK2
my $frame_buttons; # фрейм с кнопкой «закрыть»

# создание основного окна
$mw = MainWindow -> new(-class => 'Recodenc', -title => "Recodenc $version");
	# рамка EU4
	$frame_eu4 = $mw -> LabFrame(-label => 'EU4');
		# фрейм выбора кодировки
		$frame_eu4_selcp = $frame_eu4 -> Frame;
		$frame_eu4_selcp -> Radiobutton(-text => 'CP1251', -variable => \$cpflag, -value => '1', -command => \&eu4_valcp) -> pack(-side => 'left');
		$frame_eu4_selcp -> Radiobutton(-text => 'CP1252+CYR', -variable => \$cpflag, -value => '2', -command => \&eu4_invcp) -> pack(-side => 'left');
		$frame_eu4_selcp -> Radiobutton(-text => 'транслит', -variable => \$cpflag, -value => '3', -command => \&eu4_invcp) -> pack(-side => 'left');
		$frame_eu4_selcp -> Button(-text => 'Таблица транслитерации', -command => \&translittable) -> pack(-side => 'right');
		# фрейм каталога №1
		$frame_eu4_entry = $frame_eu4 -> Frame;
		$frame_eu4_entry -> Entry(-width => '50', -textvariable => \$catalogue1) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4_entry -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue1]) -> pack(-side => 'right');
		# фрейм каталога №2
		$frame_eu4_entrysave = $frame_eu4 -> Frame;
		$frame_eu4_entrysave -> Checkbutton(-text => 'Сохранить в:', -variable => \$c2flag) -> pack(-side => 'left');
		$frame_eu4_entrysave -> Entry(-width => '50', -textvariable => \$catalogue2) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4_entrysave -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$catalogue2]) -> pack(-side => 'right');
		# фрейм кнопок
		$frame_eu4_buttons = $frame_eu4 -> Frame;
		$frame_eu4_buttons -> Button(-text => 'Кодировать', -command => [\&code => 0]) -> form(-left => '%0', -right => '%50');
		$eu4_decode_button = $frame_eu4_buttons -> Button(-text => 'Декодировать', -command => [\&code => 1]) -> form(-left => '%50', -right => '%100');
	# рамка EU4 fnt
	$frame_eu4font = $mw -> LabFrame(-label => 'EU4 шрифты (fnt) для кодировки CP1252+CYR');
		# фрейм каталога №1
		$frame_eu4font_entry = $frame_eu4font -> Frame;
		$frame_eu4font_entry -> Entry(-width => '50', -textvariable => \$cataloguef1) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4font_entry -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$cataloguef1]) -> pack(-side => 'right');
		# фрейм каталога №2
		$frame_eu4font_entrysave = $frame_eu4font ->Frame;
		$frame_eu4font_entrysave -> Checkbutton(-text => 'Сохранить в:', -variable => \$cf2flag) -> pack(-side => 'left');
		$frame_eu4font_entrysave -> Entry(-width => '50', -textvariable => \$cataloguef2) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4font_entrysave -> Button(-text => 'Выбрать каталог', -command => [\&seldir => \$cataloguef2]) -> pack(-side => 'right');
		# фрейм кнопки
		$frame_eu4font_button = $frame_eu4font -> Frame;
		$frame_eu4font_button -> Button(-text => 'Кодировать', -command => \&font) -> pack(-expand => '1', -fill => 'x', -side => 'left');
	$frame_ck2 = $mw -> LabFrame(-label => 'CK2');
	$frame_ck2 -> Label(-text => 'Поддержка CK2 запланирована.') -> pack(-side => 'left');
	$frame_buttons = $mw -> Frame;
	$frame_buttons -> Label(-anchor => 'w' ,-relief => 'flat', -textvariable => \$status) -> pack(-expand => '1', -fill => 'x', -side => 'left'); # строка статуса
	$frame_buttons -> Button(-text => 'Закрыть', -command => [$mw => 'destroy']) -> pack(-side => 'right');
# фреймы верхнего уровня
$frame_eu4 -> form(-top => '%0', -left => '%0', -right => '%100');
$frame_eu4font -> form(-top => $frame_eu4, -left => '%0', -right => '%100');
$frame_ck2 -> form(-top => $frame_eu4font, -left => '%0', -right => '%100');
$frame_buttons -> form(-top => $frame_ck2, -left => '%0', -right => '%100');
# фреймы EU4
$frame_eu4_selcp -> form(-top => '%0', -left => '%0', -right => '%100');
$frame_eu4_entry -> form(-top => $frame_eu4_selcp, -left => '%0', -right => '%100');
$frame_eu4_entrysave -> form(-top => $frame_eu4_entry, -left => '%0', -right => '%100');
$frame_eu4_buttons -> form(-top => $frame_eu4_entrysave, -left => '%0', -right => '%100');
# фреймы EU4-fnt
$frame_eu4font_entry -> form(-top => '%0', -left => '%0', -right => '%100');
$frame_eu4font_entrysave -> form(-top => $frame_eu4font_entry, -left => '%0', -right => '%100');
$frame_eu4font_button -> form(-top => $frame_eu4font_entrysave, -left => '%0', -right => '%100');

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
print $file_conf_o @strscf;
close $file_conf_o;

################
# ПОДПРОГРАММЫ #
################
sub code { # перекодировка файлов
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
		my @strs;
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
			if    ($cpfl == 1 and $opfl == 0) {$sps[1] =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ/}
			elsif ($cpfl == 2 and $opfl == 0) {
				$sps[1] =~ s/€//g;
				$sps[1] =~ s/‚/,/g;
				$sps[1] =~ s/ƒ/f/g;
				$sps[1] =~ s/„/\\\"/g;
				$sps[1] =~ s/…/.../g;
				$sps[1] =~ s/†//g;
				$sps[1] =~ s/‡//g;
				$sps[1] =~ s/‰//g;
				$sps[1] =~ s/ˆ//g;
				$sps[1] =~ s/‹//g;
				$sps[1] =~ s/‘/'/g;
				$sps[1] =~ s/’/'/g;
				$sps[1] =~ s/“/\\\"/g;
				$sps[1] =~ s/”/\\\"/g;
				$sps[1] =~ s/•//g;
				$sps[1] =~ s/–/-/g;
				$sps[1] =~ s/—/-/g;
				$sps[1] =~ s/˜//g;
				$sps[1] =~ s/™//g;
				$sps[1] =~ s/›//g;
				$sps[1] =~ s/ / /g;
				$sps[1] =~ s/¢//g;
				$sps[1] =~ s/¥//g;
				$sps[1] =~ s/¦//g;
				$sps[1] =~ s/¨//g;
				$sps[1] =~ s/©//g;
				$sps[1] =~ s/ª/a/g;
				$sps[1] =~ s/«/\\\"/g;
				$sps[1] =~ s/¬//g;
				$sps[1] =~ s/®//g;
				$sps[1] =~ s/¯//g;
				$sps[1] =~ s/°//g;
				$sps[1] =~ s/±//g;
				$sps[1] =~ s/²//g;
				$sps[1] =~ s/³//g;
				$sps[1] =~ s/´/'/g;
				$sps[1] =~ s/µ//g;
				$sps[1] =~ s/¶//g;
				$sps[1] =~ s/·//g;
				$sps[1] =~ s/¸//g;
				$sps[1] =~ s/¹//g;
				$sps[1] =~ s/º/o/g;
				$sps[1] =~ s/»/\\\"/g;
				$sps[1] =~ s/¼//g;
				$sps[1] =~ s/½//g;
				$sps[1] =~ s/¾//g;
				$sps[1] =~ s/×//g;
				$sps[1] =~ s/÷//g;
				$sps[1] =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/A€B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷/;
			}
			elsif ($cpfl == 3 and $opfl == 0) {$sps[1] =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/ABVGDEËJZIYKLMNOPRSTUFHQCXÇ’ÎYÊÜÄabvgdeëjziyklmnoprstufhqcxç’îyêüä/}
			elsif ($cpfl == 1 and $opfl == 1) {$sps[1] =~ y/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/}
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

sub font { # изменяет fnt-карты шрифтов
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
				$str =~ s/ unicode=.//;
				$str =~ s/ outline=.//;
				push(@strs, "$str\n"); next;
			}
			if ($str =~ m/^common/) {
				$str =~ s/ packed=. alphaChnl=. redChnl=. greenChnl=. blueChnl=.//;
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
				$str_id[1] =~ s/352/138/;
				$str_id[1] =~ s/353/154/;
				$str_id[1] =~ s/338/140/;
				$str_id[1] =~ s/339/156/;
				$str_id[1] =~ s/381/142/;
				$str_id[1] =~ s/382/158/;
				$str_id[1] =~ s/376/159/;
				$str_id[1] =~ s/1041/128/;
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
				delete $str_id[10];
				push(@strs, "@str_id\n"); next;
			}
			if ($str =~ m/^kerning/) {
				my @str_kerning = split(" ", $str);
				for my $i (1, 2) {
					# заменяет номера во втором и третьем столбце
					$str_kerning[$i] =~ s/352/138/;
					$str_kerning[$i] =~ s/353/154/;
					$str_kerning[$i] =~ s/338/140/;
					$str_kerning[$i] =~ s/339/156/;
					$str_kerning[$i] =~ s/381/142/;
					$str_kerning[$i] =~ s/382/158/;
					$str_kerning[$i] =~ s/376/159/;
					$str_kerning[$i] =~ s/1041/128/;
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
				push(@strs, "@str_kerning\n"); next;
			}
		}
		close($file_in);
		# сортировка
		my $kr;
		for (my $i = 2; $i < scalar(@strs); $i++) {
			if ($strs[$i] =~ m/^kernings/) {$kr = $i - 1; last}
		}
		unless (defined $kr) {$kr = scalar(@strs) - 1}
		@strs[2..$kr] = sort {&srt($a, $b)} @strs[2..$kr];# участок массива от третьей строки до последней строки перед m/^kernings/ или концом файла сортируется по числам столбца id=
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
	my $d = $mw -> MsgBox(-type => 'ok', -message => "а — Aa	я — Ää\nо — Oo	ё — Ëë\nу — Uu	ю — Üü\nэ — Êê	е — Ee\nы — Îî	и — Ii\nб — Bb	р — Rr\nв — Vv	с — Ss\nг — Gg	т — Tt\nд — Dd	ф — Ff\nж — Jj	х — Hh\nз — Zz	ц — Qq\nй — Yy	ч — Cc\nк — Kk	ш — Xx\nл — Ll	щ — Çç\nм — Mm	ъ — ’\nн — Nn	ь — Yy\nп — Pp", -title => 'Таблица транслитерации');
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

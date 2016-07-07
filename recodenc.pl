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

my $version = 'v0.1.1';
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
unless ($cpflag == 1 or $cpflag == 2) {$cpflag = 1}
unless ($c2flag == 0 or $c2flag == 1) {$c2flag = 0}
## рисование интерфейса
# инициализация переменных для хранения указателей на элементы интерфейса

my $mw; # главное окно
my $frame_eu4; # рамка EU4
my $frame_eu4_selcp; # фрейм с выбором кодировки
my $frame_eu4_entry; # фрейм для текстового поля с первым каталогом
my $te1; # текстовое поле с первым каталогом
my $frame_eu4_entrysave; # фрейм для тектового поля со вторым каталогом
my $te2; # текстовое поле со вторым каталогом
my $frame_eu4_buttons; # фрейм с кнопками действий для перекодировки
my $frame_eu4font; # рамка EU4 fnt
my $frame_eu4font_entry; # фрейм для текстового поля с первым каталогом
my $tef1; # текстовое поле с первым каталогом
my $frame_eu4font_entrysave; # фрейм для тектового поля со вторым каталогом
my $tef2; # текстовое поле со вторым каталогом
my $frame_eu4font_button; # фрейм кнопки действия
my $frame_ck2; # рамка CK2
my $frame_buttons; # фрейм с кнопкой «закрыть»

# создание основного окна
$mw = MainWindow -> new(-class => 'Recodenc', -title => "Recodenc $version");
	# рамка EU4
	$frame_eu4 = $mw -> LabFrame(-label => 'EU4');
		# фрейм выбора кодировки
		$frame_eu4_selcp = $frame_eu4 -> Frame;
		$frame_eu4_selcp -> Radiobutton(-text => 'CP1251', -variable => \$cpflag, -value => '1') -> pack(-side => 'left');
		$frame_eu4_selcp -> Radiobutton(-text => 'CP1252+CYR', -variable => \$cpflag, -value => '2') -> pack(-side => 'left');
		# фрейм каталога №1
		$frame_eu4_entry = $frame_eu4 -> Frame;
		$te1 = $frame_eu4_entry -> Entry(-width => '50', -validate => 'focus', -validatecommand => \&cval1) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4_entry -> Button(-text => 'Выбрать каталог', -command => \&seldir) -> pack(-side => 'right');
		# фрейм каталога №2
		$frame_eu4_entrysave = $frame_eu4 -> Frame;
		$frame_eu4_entrysave -> Checkbutton(-text => 'Сохранить в:', -variable => \$c2flag) -> pack(-side => 'left');
		$te2 = $frame_eu4_entrysave -> Entry(-width => '50', -validate => 'focus', -validatecommand => \&cval2) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4_entrysave -> Button(-text => 'Выбрать каталог', -command => \&seldir2) -> pack(-side => 'right');
		# фрейм кнопок
		$frame_eu4_buttons = $frame_eu4 -> Frame;
		$frame_eu4_buttons -> Button(-text => 'Кодировать', -command => sub {code(0)}) -> form(-left => '%0', -right => '%50');
		$frame_eu4_buttons -> Button(-text => 'Декодировать', -command => sub {code(1)}) -> form(-left => '%50', -right => '%100');
	# рамка EU4 fnt
	$frame_eu4font = $mw -> LabFrame(-label => 'EU4 шрифты (fnt) для кодировки CP1252+CYR');
		# фрейм каталога №1
		$frame_eu4font_entry = $frame_eu4font -> Frame;
		$tef1 = $frame_eu4font_entry -> Entry(-width => '50', -validate => 'focus', -validatecommand => \&cvalf1) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4font_entry -> Button(-text => 'Выбрать каталог', -command => \&seldirf1) -> pack(-side => 'right');
		# фрейм каталога №2
		$frame_eu4font_entrysave = $frame_eu4font ->Frame;
		$frame_eu4font_entrysave -> Checkbutton(-text => 'Сохранить в:', -variable => \$cf2flag) -> pack(-side => 'left');
		$tef2 = $frame_eu4font_entrysave -> Entry(-width => '50', -validate => 'focus', -validatecommand => \&cvalf2) -> pack(-expand => '1', -fill => 'x', -side => 'left');
		$frame_eu4font_entrysave -> Button(-text => 'Выбрать каталог', -command => \&seldirf2) -> pack(-side => 'right');
		# фрейм кнопки
		$frame_eu4font_button = $frame_eu4font -> Frame;
		$frame_eu4font_button -> Button(-text => 'Кодировать', -command => \&font) -> pack(-expand => '1', -fill => 'x', -side => 'left');
	$frame_ck2 = $mw -> LabFrame(-label => 'CK2');
	$frame_ck2 -> Label(-text => 'Поддержка CK2 запланирована.') -> pack(-side => 'left');
	$frame_buttons = $mw -> Frame;
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

$te1 -> insert('0', $catalogue1);
$te2 -> insert('0', $catalogue2);
$tef1 -> insert('0', $cataloguef1);
$tef2 -> insert('0', $cataloguef2);

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
	my $opfl = shift;
	opendir(my $ch, $catalogue1) or invalid_dir(1);
	my @files = grep { ! /^\.\.?\z/ } readdir $ch;
	closedir($ch);
	for (my $i = 0; $i < scalar(@files); $i++) {
		open(my $file, '<:unix:perlio:utf8', "$catalogue1/$files[$i]");
		my @strs;
		push(@strs, "\x{FEFF}"); # добавление BOM в начало файла
		while (my $str = <$file>) {
			chomp $str;
			if ($str =~ m/^\x{FEFF}/) {$str =~ s/^\x{FEFF}//} # удаление BOM из обрабатываемых строк
			if ($str =~ m/^\#/) {push(@strs, "$str\n"); next}
			if ($str =~ m/^ \#/) {push(@strs, "$str\n"); next}
			if ($str =~ m/^$/) {push(@strs, "$str\n"); next}
			if ($str =~ m/^ $/) {push(@strs, "$str\n"); next}
			my @sps = split(/:/, $str, '2');
			if    ($cpflag == 1 and $opfl == 0) {$sps[1] =~ y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ/}
			elsif ($cpflag == 2 and $opfl == 0) {
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
			elsif ($cpflag == 1 and $opfl == 1) {$sps[1] =~ y/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/}
			elsif ($cpflag == 2 and $opfl == 1) {$sps[1] =~ y/A€B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/}
			push(@strs, "$sps[0]:$sps[1]\n");
		}
		close($file);
		if ($c2flag == 0) {
			open(my $out, '>:unix:perlio:utf8', "$catalogue1/$files[$i]");
			print $out @strs;
			close $out;
		}
		elsif ($c2flag == 1) {
			open(my $out, '>:unix:perlio:utf8', "$catalogue2/$files[$i]") or invalid_dir(2);
			print $out @strs;
			close $out;
		}
	}
}

sub font { # изменяет fnt-карты шрифтов
#print "$cf2flag\n$cataloguef1\n$cataloguef2\n";
	opendir(my $ch, $cataloguef1) or invalid_dir(3);
	my @files = grep { ! /^\.\.?\z/ } readdir $ch;
	closedir($ch);
	for (my $i = 0; $i < scalar(@files); $i++) {
		open(my $file_in, '<:unix:crlf', "$cataloguef1/$files[$i]");
		my @strs;
		while (my $str = <$file_in>) {
			chomp($str);
			if ($str =~ m/^kernings/) {
				push(@strs, "$str\n"); next;
			}
			if ($str =~ m/^info/) {
				$str =~ s/size=-/size=/;
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
				$str =~ s/id=352/id=138/;
				$str =~ s/id=353/id=154/;
				$str =~ s/id=338/id=140/;
				$str =~ s/id=339/id=156/;
				$str =~ s/id=381/id=142/;
				$str =~ s/id=382/id=158/;
				$str =~ s/id=376/id=159/;
				$str =~ s/id=1041/id=128/;
				$str =~ s/id=1043/id=130/;
				$str =~ s/id=1044/id=131/;
				$str =~ s/id=1046/id=132/;
				$str =~ s/id=1047/id=133/;
				$str =~ s/id=1048/id=134/;
				$str =~ s/id=1049/id=135/;
				$str =~ s/id=1051/id=136/;
				$str =~ s/id=1055/id=137/;
				$str =~ s/id=1059/id=139/;
				$str =~ s/id=1060/id=145/;
				$str =~ s/id=1062/id=146/;
				$str =~ s/id=1063/id=147/;
				$str =~ s/id=1064/id=148/;
				$str =~ s/id=1065/id=149/;
				$str =~ s/id=1066/id=150/;
				$str =~ s/id=1067/id=151/;
				$str =~ s/id=1068/id=152/;
				$str =~ s/id=1069/id=153/;
				$str =~ s/id=1070/id=155/;
				$str =~ s/id=1073/id=160/;
				$str =~ s/id=1074/id=162/;
				$str =~ s/id=1075/id=165/;
				$str =~ s/id=1076/id=166/;
				$str =~ s/id=1078/id=168/;
				$str =~ s/id=1079/id=169/;
				$str =~ s/id=1080/id=170/;
				$str =~ s/id=1081/id=171/;
				$str =~ s/id=1082/id=172/;
				$str =~ s/id=1083/id=174/;
				$str =~ s/id=1084/id=175/;
				$str =~ s/id=1085/id=176/;
				$str =~ s/id=1087/id=177/;
				$str =~ s/id=1090/id=178/;
				$str =~ s/id=1091/id=179/;
				$str =~ s/id=1092/id=180/;
				$str =~ s/id=1094/id=181/;
				$str =~ s/id=1095/id=182/;
				$str =~ s/id=1096/id=183/;
				$str =~ s/id=1097/id=184/;
				$str =~ s/id=1098/id=185/;
				$str =~ s/id=1099/id=186/;
				$str =~ s/id=1100/id=187/;
				$str =~ s/id=1101/id=188/;
				$str =~ s/id=1102/id=190/;
				$str =~ s/id=1071/id=215/;
				$str =~ s/id=1103/id=247/;
				$str =~ s/  chnl=15//;
				push(@strs, "$str\n"); next;
			}
			if ($str =~ m/^kerning/) {
				my @strs_kerning = split(" ", $str);
				$strs_kerning[1] =~ s/352/138/;
				$strs_kerning[1] =~ s/353/154/;
				$strs_kerning[1] =~ s/338/140/;
				$strs_kerning[1] =~ s/339/156/;
				$strs_kerning[1] =~ s/381/142/;
				$strs_kerning[1] =~ s/382/158/;
				$strs_kerning[1] =~ s/376/159/;
				$strs_kerning[1] =~ s/1041/128/;
				$strs_kerning[1] =~ s/1043/130/;
				$strs_kerning[1] =~ s/1044/131/;
				$strs_kerning[1] =~ s/1046/132/;
				$strs_kerning[1] =~ s/1047/133/;
				$strs_kerning[1] =~ s/1048/134/;
				$strs_kerning[1] =~ s/1049/135/;
				$strs_kerning[1] =~ s/1051/136/;
				$strs_kerning[1] =~ s/1055/137/;
				$strs_kerning[1] =~ s/1059/139/;
				$strs_kerning[1] =~ s/1060/145/;
				$strs_kerning[1] =~ s/1062/146/;
				$strs_kerning[1] =~ s/1063/147/;
				$strs_kerning[1] =~ s/1064/148/;
				$strs_kerning[1] =~ s/1065/149/;
				$strs_kerning[1] =~ s/1066/150/;
				$strs_kerning[1] =~ s/1067/151/;
				$strs_kerning[1] =~ s/1068/152/;
				$strs_kerning[1] =~ s/1069/153/;
				$strs_kerning[1] =~ s/1070/155/;
				$strs_kerning[1] =~ s/1073/160/;
				$strs_kerning[1] =~ s/1074/162/;
				$strs_kerning[1] =~ s/1075/165/;
				$strs_kerning[1] =~ s/1076/166/;
				$strs_kerning[1] =~ s/1078/168/;
				$strs_kerning[1] =~ s/1079/169/;
				$strs_kerning[1] =~ s/1080/170/;
				$strs_kerning[1] =~ s/1081/171/;
				$strs_kerning[1] =~ s/1082/172/;
				$strs_kerning[1] =~ s/1083/174/;
				$strs_kerning[1] =~ s/1084/175/;
				$strs_kerning[1] =~ s/1085/176/;
				$strs_kerning[1] =~ s/1087/177/;
				$strs_kerning[1] =~ s/1090/178/;
				$strs_kerning[1] =~ s/1091/179/;
				$strs_kerning[1] =~ s/1092/180/;
				$strs_kerning[1] =~ s/1094/181/;
				$strs_kerning[1] =~ s/1095/182/;
				$strs_kerning[1] =~ s/1096/183/;
				$strs_kerning[1] =~ s/1097/184/;
				$strs_kerning[1] =~ s/1098/185/;
				$strs_kerning[1] =~ s/1099/186/;
				$strs_kerning[1] =~ s/1100/187/;
				$strs_kerning[1] =~ s/1101/188/;
				$strs_kerning[1] =~ s/1102/190/;
				$strs_kerning[1] =~ s/1071/215/;
				$strs_kerning[1] =~ s/1103/247/;
				$strs_kerning[2] =~ s/352/138/;
				$strs_kerning[2] =~ s/353/154/;
				$strs_kerning[2] =~ s/338/140/;
				$strs_kerning[2] =~ s/339/156/;
				$strs_kerning[2] =~ s/381/142/;
				$strs_kerning[2] =~ s/382/158/;
				$strs_kerning[2] =~ s/376/159/;
				$strs_kerning[2] =~ s/1041/128/;
				$strs_kerning[2] =~ s/1043/130/;
				$strs_kerning[2] =~ s/1044/131/;
				$strs_kerning[2] =~ s/1046/132/;
				$strs_kerning[2] =~ s/1047/133/;
				$strs_kerning[2] =~ s/1048/134/;
				$strs_kerning[2] =~ s/1049/135/;
				$strs_kerning[2] =~ s/1051/136/;
				$strs_kerning[2] =~ s/1055/137/;
				$strs_kerning[2] =~ s/1059/139/;
				$strs_kerning[2] =~ s/1060/145/;
				$strs_kerning[2] =~ s/1062/146/;
				$strs_kerning[2] =~ s/1063/147/;
				$strs_kerning[2] =~ s/1064/148/;
				$strs_kerning[2] =~ s/1065/149/;
				$strs_kerning[2] =~ s/1066/150/;
				$strs_kerning[2] =~ s/1067/151/;
				$strs_kerning[2] =~ s/1068/152/;
				$strs_kerning[2] =~ s/1069/153/;
				$strs_kerning[2] =~ s/1070/155/;
				$strs_kerning[2] =~ s/1073/160/;
				$strs_kerning[2] =~ s/1074/162/;
				$strs_kerning[2] =~ s/1075/165/;
				$strs_kerning[2] =~ s/1076/166/;
				$strs_kerning[2] =~ s/1078/168/;
				$strs_kerning[2] =~ s/1079/169/;
				$strs_kerning[2] =~ s/1080/170/;
				$strs_kerning[2] =~ s/1081/171/;
				$strs_kerning[2] =~ s/1082/172/;
				$strs_kerning[2] =~ s/1083/174/;
				$strs_kerning[2] =~ s/1084/175/;
				$strs_kerning[2] =~ s/1085/176/;
				$strs_kerning[2] =~ s/1087/177/;
				$strs_kerning[2] =~ s/1090/178/;
				$strs_kerning[2] =~ s/1091/179/;
				$strs_kerning[2] =~ s/1092/180/;
				$strs_kerning[2] =~ s/1094/181/;
				$strs_kerning[2] =~ s/1095/182/;
				$strs_kerning[2] =~ s/1096/183/;
				$strs_kerning[2] =~ s/1097/184/;
				$strs_kerning[2] =~ s/1098/185/;
				$strs_kerning[2] =~ s/1099/186/;
				$strs_kerning[2] =~ s/1100/187/;
				$strs_kerning[2] =~ s/1101/188/;
				$strs_kerning[2] =~ s/1102/190/;
				$strs_kerning[2] =~ s/1071/215/;
				$strs_kerning[2] =~ s/1103/247/;
				push(@strs, "@strs_kerning\n"); next;
			}
		}
		close($file_in);
		if ($cf2flag == 0) {
			open(my $file_out, '>:unix:crlf', "$cataloguef1/$files[$i]");
			print $file_out @strs;
			close($file_out);
		}
		elsif ($cf2flag == 1) {
			open(my $file_out, '>:unix:crlf', "$cataloguef2/$files[$i]") or invalid_dir(4);
			print $file_out @strs;
			close($file_out);
		}
	}
}

sub invalid_dir {
	my $dir = shift;
	if ($dir == 1) {
		$catalogue1 = '';
		$te1 -> delete('0', 'end');
	}
	elsif ($dir == 2) {
		$catalogue2 = '';
		$te2 -> delete('0', 'end');
	}
	elsif ($dir == 3) {
		$cataloguef1 = '';
		$tef1 -> delete('0', 'end');
	}
	elsif ($dir == 4) {
		$cataloguef2 = '';
		$tef2 -> delete('0', 'end');
	}
}

sub seldir {
	my $sdir = $mw -> chooseDirectory;
	if (defined $sdir and $sdir ne '') {
		$catalogue1 = $sdir;
		$te1 -> delete('0', 'end');
		$te1 -> insert('0', $sdir);
	}
}

sub seldir2 {
	my $sdir = $mw -> chooseDirectory;
	if (defined $sdir and $sdir ne '') {
		$catalogue2 = $sdir;
		$te2 -> delete('0', 'end');
		$te2 -> insert('0', $sdir);
	}
}

sub seldirf1 {
	my $sdir = $mw -> chooseDirectory;
	if (defined $sdir and $sdir ne '') {
		$cataloguef1 = $sdir;
		$tef1 -> delete('0', 'end');
		$tef1 -> insert('0', $sdir);
	}
}

sub seldirf2 {
	my $sdir = $mw -> chooseDirectory;
	if (defined $sdir and $sdir ne '') {
		$cataloguef2 = $sdir;
		$tef2 -> delete('0', 'end');
		$tef2 -> insert('0', $sdir);
	}
}

sub cval1 {
	$catalogue1 = $te1 -> get;
}

sub cval2 {
	$catalogue2 = $te2 -> get;
}

sub cvalf1 {
	$cataloguef1 = $tef1 -> get;
}

sub cvalf2 {
	$cataloguef2 = $tef2 -> get;
}

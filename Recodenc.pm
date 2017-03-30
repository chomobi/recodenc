package Recodenc;
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
# SRC — исходник
# DST — назначение
use utf8;
use v5.18;
use warnings;
use integer;
use vars qw(
	@EXPORT_OK
	$FL_EU4_SRC_DIR_NOT_FOUND
	$FL_EU4_DST_DIR_NOT_FOUND
	$FL_CK2_SRCEN_DIR_NOT_FOUND
	$FL_CK2_SRCRU_DIR_NOT_FOUND
	$FL_CK2_DSTRU_DIR_NOT_FOUND
	$FL_FNT_SRC_DIR_NOT_FOUND
	$FL_FNT_DST_DIR_NOT_FOUND
	$FL_CNV_SRC_DIR_NOT_FOUND
	$FL_CNV_DST_DIR_NOT_FOUND
	$FL_PTX_SRC_DIR_NOT_FOUND
	$FL_PTX_DST_DIR_NOT_FOUND
	$FL_SRC_AND_DST_DIR_ARE_THE_SAME
	);
use parent qw(Exporter);
use File::Copy;
use Cwd qw(abs_path);
use Encode qw(encode decode);
use Encode::Locale;
@EXPORT_OK = qw(eu4_l10n ck2_l10n ck2_l10n_tags eu4ck2_font ck2_to_eu4_modsave plaintext);

*FL_EU4_SRC_DIR_NOT_FOUND = \1;
*FL_EU4_DST_DIR_NOT_FOUND = \2;
*FL_CK2_SRCEN_DIR_NOT_FOUND = \1;
*FL_CK2_SRCRU_DIR_NOT_FOUND = \2;
*FL_CK2_DSTRU_DIR_NOT_FOUND = \3;
*FL_FNT_SRC_DIR_NOT_FOUND = \1;
*FL_FNT_DST_DIR_NOT_FOUND = \2;
*FL_CNV_SRC_DIR_NOT_FOUND = \1;
*FL_CNV_DST_DIR_NOT_FOUND = \2;
*FL_PTX_SRC_DIR_NOT_FOUND = \1;
*FL_PTX_DST_DIR_NOT_FOUND = \2;
*FL_SRC_AND_DST_DIR_ARE_THE_SAME = \4;

################################################################################
# КОД ДЛЯ ВЫПОЛНЕНИЯ ПЕРЕД ВЫЗОВАМИ ФУНКЦИЙ
################################################################################
# Объявление кодировок для FNT
my %cp_1252pcyr_eu4 = (
	352 => '138',
	353 => '154',
	338 => '140',
	339 => '156',
	381 => '142',
	382 => '158',
	376 => '159',
	1041 => '128',
	1043 => '130',
	1044 => '131',
	1046 => '132',
	1047 => '133',
	1048 => '134',
	1049 => '135',
	1051 => '136',
	1055 => '137',
	1059 => '139',
	1060 => '145',
	1062 => '146',
	1063 => '147',
	1064 => '148',
	1065 => '149',
	1066 => '150',
	1067 => '151',
	1068 => '152',
	1069 => '153',
	1070 => '155',
	1073 => '160',
	1074 => '162',
	1075 => '165',
	1076 => '166',
	1078 => '168',
	1079 => '169',
	1080 => '170',
	1081 => '171',
	1082 => '172',
	1083 => '174',
	1084 => '175',
	1085 => '176',
	1087 => '177',
	1090 => '178',
	1091 => '179',
	1092 => '180',
	1094 => '181',
	1095 => '182',
	1096 => '183',
	1097 => '184',
	1098 => '185',
	1099 => '186',
	1100 => '187',
	1101 => '188',
	1102 => '190',
	1071 => '215',
	1103 => '247'
);

my %cp_1252pcyr_ck2 = (
	352 => '138',
	353 => '154',
	338 => '140',
	339 => '156',
	381 => '142',
	382 => '158',
	376 => '159',
	1041 => '94',
	1043 => '130',
	1044 => '131',
	1046 => '132',
	1047 => '133',
	1048 => '134',
	1049 => '135',
	1051 => '136',
	1055 => '137',
	1059 => '139',
	1060 => '145',
	1062 => '146',
	1063 => '147',
	1064 => '148',
	1065 => '149',
	1066 => '150',
	1067 => '151',
	1068 => '152',
	1069 => '153',
	1070 => '155',
	1073 => '160',
	1074 => '162',
	1075 => '165',
	1076 => '166',
	1078 => '168',
	1079 => '169',
	1080 => '170',
	1081 => '171',
	1082 => '172',
	1083 => '174',
	1084 => '175',
	1085 => '176',
	1087 => '177',
	1090 => '178',
	1091 => '179',
	1092 => '180',
	1094 => '181',
	1095 => '182',
	1096 => '183',
	1097 => '184',
	1098 => '185',
	1099 => '186',
	1100 => '187',
	1101 => '188',
	1102 => '190',
	1071 => '215',
	1103 => '247'
);

my %cp_1251 = (
	8218 => '130',
	8222 => '132',
	8230 => '133',
	8249 => '139',
	8216 => '145',
	8217 => '146',
	8220 => '147',
	8221 => '148',
	8211 => '150',
	8212 => '151',
	8250 => '155',
	1040 => '192',
	1041 => '193',
	1042 => '194',
	1043 => '195',
	1044 => '196',
	1045 => '197',
	1025 => '168',
	1046 => '198',
	1047 => '199',
	1048 => '200',
	1049 => '201',
	1050 => '202',
	1051 => '203',
	1052 => '204',
	1053 => '205',
	1054 => '206',
	1055 => '207',
	1056 => '208',
	1057 => '209',
	1058 => '210',
	1059 => '211',
	1060 => '212',
	1061 => '213',
	1062 => '214',
	1063 => '215',
	1064 => '216',
	1065 => '217',
	1066 => '218',
	1067 => '219',
	1068 => '220',
	1069 => '221',
	1070 => '222',
	1071 => '223',
	1072 => '224',
	1073 => '225',
	1074 => '226',
	1075 => '227',
	1076 => '228',
	1077 => '229',
	1105 => '184',
	1078 => '230',
	1079 => '231',
	1080 => '232',
	1081 => '233',
	1082 => '234',
	1083 => '235',
	1084 => '236',
	1085 => '237',
	1086 => '238',
	1087 => '239',
	1088 => '240',
	1089 => '241',
	1090 => '242',
	1091 => '243',
	1092 => '244',
	1093 => '245',
	1094 => '246',
	1095 => '247',
	1096 => '248',
	1097 => '249',
	1098 => '250',
	1099 => '251',
	1100 => '252',
	1101 => '253',
	1102 => '254',
	1103 => '255'
);

################################################################################
# ЭКСПОРТИРУЕМЫЕ ФУНКЦИИ
################################################################################
# Encode Localisation for EU4
# Код оригинальной функции сравнить с этой и удалить ненужное, сохранить справочную информацию.
sub eu4_l10n {
	# чтение параметров
	my $cpfl = shift; # cp1251 — CP1251; cp1252pcyr — CP1252+CYR; translit — транслит; d_cp1251 — декодировать CP1251; d_cp1252pcyr — декодировать CP1252+CYR
	my $c2fl = shift; # 0 — перезаписать; 1 — сохранить в другое место
	my $dir1 = shift; # каталог №1
	my $dir2 = shift; # каталог №2
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {return $FL_EU4_SRC_DIR_NOT_FOUND};
	if ($c2fl == 1) {
		unless (-d encode('locale_fs', $dir2)) {return $FL_EU4_DST_DIR_NOT_FOUND}
		if (decode('locale_fs', abs_path(encode('locale_fs', $dir1))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir2)))) {
			return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
		}
	};
	# работа
	opendir(my $ch, encode('locale_fs', $dir1));
	my @filenames = grep { m/\.yml$/ } map {decode('locale_fs', $_)} readdir $ch;
	closedir($ch);
	foreach my $filename (@filenames) {
		open(my $filehandle, '<:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir1/$filename"));
		my $fl = 0; # флаг нужности/ненужности обработки строк
		my @strs; # объявление хранилища строк
		push(@strs, "\x{FEFF}"); # добавление BOM в начало файла
		while (my $str = <$filehandle>) {
			chomp $str;
			if ($str =~ m/\r$/) {$str =~ s/\r$//} # защита от дебилов, подающих на вход CRLF
			if ($str =~ m/^\x{FEFF}/) {$str =~ s/^\x{FEFF}//} # удаление BOM из обрабатываемых строк
			# запоминание и пропуск необрабатываемых строк
			if ($str =~ m/^\#/ or $str =~ m/^ \#/ or $str =~ m/^$/ or $str =~ m/^ $/) {push(@strs, "$str\n"); next}
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
				&cyr_to_cp1251(\$txt);
			}
			elsif ($cpfl eq 'cp1252pcyr') {
				&cyr_to_cp1252pcyr_eu4(\$txt);
			}
			elsif ($cpfl eq 'translit') {
				&cyr_to_translit(\$txt);
			}
			elsif ($cpfl eq 'd_cp1251') {
				&cp1251_to_cyr(\$txt);
			}
			elsif ($cpfl eq 'd_cp1252pcyr') {
				&cp1252pcyr_to_cyr_eu4(\$txt);
			}
			# сохранение строки
			if (length($cmm) > 0) {
				push(@strs, " $tag:$num \"$txt\" #$cmm\n");
				next;
			}
			push(@strs, " $tag:$num \"$txt\"\n");
		}
		close($filehandle);
		if ($c2fl == 0) {
			open(my $out, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir1/$filename"));
			print $out @strs;
			close $out;
		}
		elsif ($c2fl == 1) {
			open(my $out, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir2/$filename"));
			print $out @strs;
			close $out;
		}
	}
	return 0;
}
# Encode Localisation for CK2
sub ck2_l10n {
	# чтение параметров
	my $cpfl = shift; # cp1252pcyr — CP1252+CYR; translit — транслит
	my $dir_orig_en = shift;
	my $dir_orig_ru = shift;
	my $dir_save_ru = shift;
	# проверка параметров
	unless (-d encode('locale_fs', $dir_orig_en)) {return $FL_CK2_SRCEN_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_orig_ru)) {return $FL_CK2_SRCRU_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_save_ru)) {return $FL_CK2_DSTRU_DIR_NOT_FOUND}
	if (decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_en))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_ru))) or
	    decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_ru))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_save_ru))) or
	    decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_en))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_save_ru)))) {
		return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
	}
	# работа
	my %loc_ru;
	opendir(my $corh, encode('locale_fs', $dir_orig_ru));
	my @filenames_or = grep { m/\.csv$/ } map {decode('locale_fs', $_)} readdir $corh;
	closedir($corh);
	foreach my $filename (@filenames_or) {
		open(my $fh, '<:raw', encode('locale_fs', "$dir_orig_ru/$filename"));
		while (my $str = <$fh>) {
			$str = decode('cp1252', $str); # декодировка строки из CP1252
			$str =~ s/\x{FFFD}//g; # удаление символа-заполнителя при перекодировке неправильно сформированных символов
			$str =~ s/\r$//; # удаление CR в конце строки
			chomp($str); # удаление LF
			if ($str =~ m/^$/) {next} # пропуск пустых строк
			if ($str =~ m/^\#/) {next} # пропуск строк с комментариями
			if ($str =~ m/^;/) {next} # пропуск строк без тегов
			my $tag = $str;
			($tag, undef) = split(/;/, $tag, 2);
#			$tag =~ s/;.*$//; # TODO: найти, что быстрее в извлечении полей — split или регулярные выражения?
			my $trns = $str;
			(undef, $trns, undef) = split(/;/, $trns, 3);
#			$trns =~ s/^[^;]*//;
#			$trns =~ s/^;//;
#			$trns =~ s/;.*$//;
			&cp1251_to_cyr(\$trns); # эта конструкция ломает расширенную латиницу из CP1252, если она там была
			$loc_ru{$tag} = $trns;
		}
		close($fh);
	}
	opendir(my $coeh, encode('locale_fs', $dir_orig_en));
	my @filenames_oe = grep { m/\.csv$/ } map {decode('locale_fs', $_)} readdir $coeh;
	closedir($coeh);
	foreach my $filename (@filenames_oe) {
		open(my $fh, '<:raw', encode('locale_fs', "$dir_orig_en/$filename"));
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
			($tag, undef) = split(/;/, $tag, 2);
#			$tag =~ s/;.*$//;
			my $trns = $str;
			(undef, $trns, undef) = split(/;/, $trns, 3);
#			$trns =~ s/^[^;]*//;
#			$trns =~ s/^;//;
#			$trns =~ s/;.*$//;
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
					&cyr_to_cp1252pcyr_ck2(\$trru);
				}
				elsif ($cpfl eq 'translit') {
					&cyr_to_translit(\$trru);
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
		open(my $ffh, '>:unix:crlf:encoding(cp1252)', encode('locale_fs', "$dir_save_ru/$filename"));
		print $ffh @strs;
		close($ffh);
	}
	return 0;
}
# Print CK2 Tags
sub ck2_l10n_tags {
	# чтение параметров
	my $dir_orig_en = shift;
	my $dir_orig_ru = shift;
	my $dir_save_ru = shift;
	# проверка параметров
	unless (-d encode('locale_fs', $dir_orig_en)) {return $FL_CK2_SRCEN_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_orig_ru)) {return $FL_CK2_SRCRU_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_save_ru)) {return $FL_CK2_DSTRU_DIR_NOT_FOUND}
	if (decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_en))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_ru))) or
	    decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_ru))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_save_ru))) or
	    decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_en))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_save_ru)))) {
		return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
	}
	# работа
	opendir(my $corh, encode('locale_fs', $dir_orig_ru));
	my @filenames_or = grep { m/\.csv$/ } map {decode('locale_fs', $_)} readdir $corh;
	closedir($corh);
	mkdir(encode('locale_fs', "$dir_save_ru/ru"));
	foreach my $filename (@filenames_or) {
		open(my $fh, '<:raw', encode('locale_fs', "$dir_orig_ru/$filename"));
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
			($tag, undef) = split(/;/, $tag, 2);
#			$tag =~ s/;.*$//;
			push(@strs, "$tag\n");
			$ff = 1;
		}
		close($fh);
		unless (defined($ff)) {next}
		open(my $ffh, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/ru/$filename"));
		print $ffh @strs;
		close($ffh);
	}
	opendir(my $coeh, encode('locale_fs', $dir_orig_en));
	my @filenames_oe = grep { m/\.csv$/ } map {decode('locale_fs', $_)} readdir $coeh;
	closedir($coeh);
	mkdir(encode('locale_fs', "$dir_save_ru/en"));
	foreach my $filename (@filenames_oe) {
		open(my $fh, '<:raw', encode('locale_fs', "$dir_orig_en/$filename"));
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
			($tag, undef) = split(/;/, $tag, 2);
#			$tag =~ s/;.*$//;
			push(@strs, "$tag\n");
			$ff = 1;
		}
		close($fh);
		unless (defined($ff)) {next}
		open(my $ffh, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/en/$filename"));
		print $ffh @strs;
		close($ffh);
	}
	return 0;
}
# Очистка и модификация карт шрифтов
sub eu4ck2_font {
	# чтение параметров
	my $cpfl = shift; # 0 — не трогать; eu4 — обработка CP1252+CYR-EU4; ck2 — обработка CP1252+CYR-CK2; cp1251 — обработка CP1251
	my $c2fl = shift; # 0 — перезаписать; 1 — сохранить в другое место
	my $dir1 = shift; # каталог №1
	my $dir2 = shift; # каталог №2
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {return $FL_FNT_SRC_DIR_NOT_FOUND}
	if ($c2fl == 1) {
		unless (-d encode('locale_fs', $dir2)) {return $FL_FNT_DST_DIR_NOT_FOUND}
		if (decode('locale_fs', abs_path(encode('locale_fs', $dir1))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir2)))) {
			return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
		}
	}
	# работа
	opendir(my $ch, encode('locale_fs', $dir1));
	my @filenames = grep { m/(\.fnt|\.tga|\.dds)$/ } map {decode('locale_fs', $_)} readdir $ch;
	closedir($ch);
	foreach my $filename (@filenames) {
		if ($filename =~ m/\.fnt$/) {
			open(my $file_in, '<:unix:crlf', encode('locale_fs', "$dir1/$filename"));
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
					unless ($cpfl eq '0') {#если КОДИРОВКА, то заменить номера символов
						&id_to_cp1252pcyr(\$str_id[1], $cpfl);
					}
					delete($str_id[10]);
					push(@strs, "@str_id\n"); next;
				}
				if ($str =~ m/^kerning/) {
					my @str_kerning = split(" ", $str);
					unless ($cpfl eq '0') {#если КОДИРОВКА, то заменить номера символов
						&id_to_cp1252pcyr(\$str_kerning[1], $cpfl);
						&id_to_cp1252pcyr(\$str_kerning[2], $cpfl);
					}
					push(@strs, "@str_kerning\n"); next;
				}
			}
			close($file_in);
			# сортировка
			unless ($cpfl eq '0') {#если КОДИРОВКА, то сортировать
				my $kr;
				for (my $i = 2; $i < scalar(@strs); $i++) {
					if ($strs[$i] =~ m/^kernings/) {$kr = $i - 1; last}
				}
				unless (defined($kr)) {$kr = scalar(@strs) - 1}
				# участок массива от третьей строки до последней строки перед m/^kernings/ или концом файла сортируется по числам столбца id=
				@strs[2..$kr] = sort {&srt($a, $b)} @strs[2..$kr];
			}
			# /сортировка
			if ($c2fl == 0) {
				open(my $file_out, '>:unix:crlf', encode('locale_fs', "$dir1/$filename"));
				print $file_out @strs;
				close($file_out);
			}
			elsif ($c2fl == 1) {
				open(my $file_out, '>:unix:crlf', encode('locale_fs', "$dir2/$filename"));
				print $file_out @strs;
				close($file_out);
			}
		}
		elsif ($filename =~ m/\.(tga|dds)$/) {
			my $new_name = $filename;
			$new_name =~ s/_0\.tga$/\.tga/;
			$new_name =~ s/_0\.dds$/\.dds/;
			if ($c2fl == 0) {
				if ($filename eq $new_name) {next}
				rename(encode('locale_fs', "$dir1/$filename"), encode('locale_fs', "$dir1/$new_name"));
			}
			elsif ($c2fl == 1) {
				copy(encode('locale_fs', "$dir1/$filename"), encode('locale_fs', "$dir2/$new_name"));
			}
		}
	}
	return 0;
}
# Конвертирование файлов локализации мода-сейва из CK2 в EU4
sub ck2_to_eu4_modsave {
	# чтение параметров
	my $cpfl = shift; # cp1251 — CP1251; cp1252pcyr — CP1252+CYR
	my $c2fl = shift; # 0 — произвести изменения в исходном каталоге; 1 — сохранить в каталог №2
	my $dir1 = shift; # исходный каталог
	my $dir2 = shift; # каталог сохранения
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {return $FL_CNV_SRC_DIR_NOT_FOUND}
	if ($c2fl == 1) {
		unless (-d encode('locale_fs', $dir2)) {return $FL_CNV_DST_DIR_NOT_FOUND}
		if (decode('locale_fs', abs_path(encode('locale_fs', $dir1))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir2)))) {
			return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
		}
	};
	# работа
	opendir(my $ch, encode('locale_fs', $dir1));
	my @filenames = grep { m/\.yml$/ } map {decode('locale_fs', $_)} readdir $ch;
	closedir($ch);
	foreach my $filename (@filenames) {
		# удаление файлов локализации других языков
		if ($filename =~ m/_l_french\.yml$/ or
		    $filename =~ m/_l_german\.yml$/ or
		    $filename =~ m/_l_spanish\.yml$/) {
			if ($c2fl == 0) {
				unlink encode('locale_fs', "$dir1/$filename");
			}
			next;
		}
		# удаление лишних файлов
		if ($filename =~ m/converted_custom_countries/ or
		    $filename =~ m/converted_custom_deities/ or
		    $filename =~ m/converted_custom_ideas/ or
		    $filename =~ m/converted_heresies/ or
		    $filename =~ m/converted_misc/ or
		    $filename =~ m/converted_religions/ or
		    $filename =~ m/sunset_invasion_custom_countries/ or
		    $filename =~ m/sunset_invasion_custom_ideas/ or
		    $filename =~ m/sunset_invasion_custom_technology_groups/) {
			if ($c2fl == 0) {
				unlink encode('locale_fs', "$dir1/$filename");
			}
			next;
		}
		open(my $file, '<:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir1/$filename"));
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
			# обработка строки ##TODO: проверить конвертацию всех поддерживаемых символов через DLC-конвертор
			$txt =~ y(‚ѓ„…†‡€‰Љ‹ЊЋ‘’“”•–—™љ›њћџ ЎўҐ¦Ё©Є«¬®Ї°±Ііґµ¶·ё№є»јѕїАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя)
			         (‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ ¡¢¥¦¨©ª«¬®¯°±²³´µ¶·¸¹º»¼¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ);
			if ($cpfl eq 'cp1251') {
				if ($filename =~ m/converted_cultures/) {
					$txt =~ s/\x7f\x11$/àÿ/;
				}
				if ($tag =~ m/^..._ADJ$/) {
					$txt .= 'ñê';
				}
			}
			elsif ($cpfl eq 'cp1252pcyr') {
				$txt =~ y/^/€/;
				if ($filename =~ m/converted_cultures/) {
					$txt =~ s/\x7f\x11$/a÷/;
				}
			}
			# сохранение строки
			push(@strs, " $tag:$num \"$txt\"\n");
		}
		close($file);
		my $new_name = $filename;
		$new_name =~ s/_l_english\.yml$/_l_russian\.yml/;
		if ($c2fl == 0) {
			rename(encode('locale_fs', "$dir1/$filename"), encode('locale_fs', "$dir1/$new_name"));
		}
		if ($c2fl == 0) {
			open(my $out, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir1/$new_name"));
			print $out @strs;
			close $out;
		}
		elsif ($c2fl == 1) {
			open(my $out, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir2/$new_name"));
			print $out @strs;
			close $out;
		}
	}
	return 0;
}
# Конвертирование файлов простого текста из UTF8 в CP1252+CYR
sub plaintext {
	# чтение параметров
	my $c2fl = shift; # 0 — произвести изменения в исходном каталоге; 1 — сохранить в каталог №2
	my $dir1 = shift; # исходный каталог
	my $dir2 = shift; # каталог сохранения
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {return $FL_PTX_SRC_DIR_NOT_FOUND};
	if ($c2fl == 1) {
		unless (-d encode('locale_fs', $dir2)) {return $FL_PTX_DST_DIR_NOT_FOUND}
		if (decode('locale_fs', abs_path(encode('locale_fs', $dir1))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir2)))) {
			return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
		}
	};
	# работа
	opendir(my $ch, encode('locale_fs', $dir1));
	my @filenames = grep { !m/^\.\.?$/ } map {decode('locale_fs', $_)} readdir $ch;
	closedir($ch);
	foreach my $filename (@filenames) {
		unless (-f encode('locale_fs', "$dir1/$filename")) {next}
		open(my $file, '<:encoding(utf-8)', encode('locale_fs', "$dir1/$filename"));
		my @strs;
		while (my $str = <$file>) {
			chomp($str);
			if ($str =~ m/\r$/) {$str =~ s/\r$//} # защита от дебилов, подающих на вход CRLF
			if ($str =~ m/^\x{FEFF}/) {$str =~ s/^\x{FEFF}//} # удаление BOM из обрабатываемых строк
			&cyr_to_cp1252pcyr_eu4(\$str);
			$str = encode('cp1252', $str);
			push(@strs, "$str\n");
		}
		if ($c2fl == 0) {
			open(my $file_out, '>:encoding(utf-8)', encode('locale_fs', "$dir1/$filename"));
			print $file_out @strs;
			close($file_out);
		}
		elsif ($c2fl == 1) {
			open(my $file_out, '>:encoding(utf-8)', encode('locale_fs', "$dir2/$filename"));
			print $file_out @strs;
			close($file_out);
		}
	}
	return 0;
}
################################################################################
# СЕРВИСНЫЕ ФУНКЦИИ
################################################################################
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
	$cmm =~ s/ #//; # удаление обозначения комментария в начале комментария
	#//в оригинальной локализации комментарий в строке всегда начинается последовательностью « #»
	return $tag, $num, $txt, $cmm;
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

# ФУНКЦИИ ПРЕОБРАЗОВАНИЯ КОДИРОВОК
# функция для преобразования кириллицы из UTF-8 в CP1251
sub cyr_to_cp1251 {
	my $str = shift; # ссылка на строку для преобразования
	$$str =~ y(АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя)
	          (ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ);
}

# функция для преобразования кириллицы из UTF-8 в CP1252+CYR
sub cyr_to_cp1252pcyr_eu4 {
	my $str = shift; # ссылка на строку для преобразования
	$$str =~ s/…/.../g;
	$$str =~ s/„/\\\"/g;
	$$str =~ s/“/\\\"/g;
	$$str =~ s/”/\\\"/g;
	$$str =~ s/«/\\\"/g;
	$$str =~ s/»/\\\"/g;
	$$str =~ y/‚‹‘’–—› €ƒ†‡ˆ‰•˜™¢¥¦¨©ª¬®¯°±²³´µ¶·¸¹º¼½¾×÷/''''\-\-' /d;
	$$str =~ y(АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя)
	          (A€B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷);
}
sub cyr_to_cp1252pcyr_ck2 {
	my $str = shift; # ссылка на строку для преобразования
	$$str =~ s/…/.../g;
	$$str =~ y/‚„‹‘’“”–—› «»^€ƒ†‡ˆ‰•˜™¢¥¦¨©ª¬®¯°±²³´µ¶·¸¹º¼½¾×÷/'"'''""\-\-' ""/d;
	$$str =~ y(АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя)
	          (A^B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷);
}

# функция для транслитерирования кириллицы
sub cyr_to_translit {
	my $str = shift; # ссылка на строку для преобразования
	$$str =~ y(АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя)
	          (ABVGDEËJZIYKLMNOPRSTUFHQCXÇ’ÎYÊÜÄabvgdeëjziyklmnoprstufhqcxç’îyêüä);
}

# функция для преобразования кириллицы из CP1251 в UTF-8
sub cp1251_to_cyr {
	my $str = shift; # ссылка на строку для преобразования
	$$str =~ y(ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ)
	          (АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя);
}

# функция для преобразования кириллицы из CP1252+CYR в UTF-8
#Данная функция не выполняет преобразование из CP1252+CYR, т. к. преобразование
#в CP1252+CYR необратимо; она лишь позволяет прочитать закодированный ранее
#текст.
sub cp1252pcyr_to_cyr_eu4 {
	my $str = shift; # ссылка на строку для преобразования
	$$str =~ y(€‚ƒ„…†‡ˆ‰‹‘’“”•–—˜™›× ¢¥¦¨©ª«¬®¯°±²³´µ¶·¸¹º»¼¾÷)
	          (БГДЖЗИЙЛПУФЦЧШЩЪЫЬЭЮЯбвгджзийклмнптуфцчшщъыьэюя);
}
sub cp1252pcyr_to_cyr_ck2 {
	my $str = shift; # ссылка на строку для преобразования
	$$str =~ y(^‚ƒ„…†‡ˆ‰‹‘’“”•–—˜™›× ¢¥¦¨©ª«¬®¯°±²³´µ¶·¸¹º»¼¾÷)
	          (БГДЖЗИЙЛПУФЦЧШЩЪЫЬЭЮЯбвгджзийклмнптуфцчшщъыьэюя);
}

# функция для замены номеров символов в кодировке юникод на номера для CP1252+CYR
sub id_to_cp1252pcyr {
	my $str = shift; # ссылка на строку для преобразования
	my $reg = shift; # eu4 — CP1252+CYR-EU4; ck2 — CP1252+CYR-CK2; cp1251 — CP1251
	my @str = split(/=/, $$str, 2);
	if    ($reg eq 'eu4') {
		if (defined($cp_1252pcyr_eu4{$str[1]})) {
			$str[1] = $cp_1252pcyr_eu4{$str[1]}
		}
	}
	elsif ($reg eq 'ck2') {
		if (defined($cp_1252pcyr_ck2{$str[1]})) {
			$str[1] = $cp_1252pcyr_ck2{$str[1]}
		}
	}
	elsif ($reg eq 'cp1251') {
		if (defined($cp_1251{$str[1]})) {
			$str[1] = $cp_1251{$str[1]}
		}
	}
	$$str = "$str[0]=$str[1]";
}
1;

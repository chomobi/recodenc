package Recodenc;
################################################################################
# Recodenc
# Copyright © 2016-2018 terqüéz <gz0@ro.ru>
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
=encoding utf8

=head1 НАЗВАНИЕ

Recodenc — преобразование текстовых файлов и файлов специального формата между UTF8 и кодировками Recodenc (CP1252A, CP1252B, CP1252C)

=head1 СИНТАКСИС

    my $flag = l10n_eu4($Recodenc::ENC_CP1252B, $dir1, $dir2);
    if    ($flag == $Recodenc::FL_SRC_DIR_NOT_FOUND) {die 'Каталог с исходными данными не найден!'}
    elsif ($flag == $Recodenc::FL_DST_DIR_NOT_FOUND) {die 'Каталог для сохранения не найден!'}
    elsif ($flag == $Recodenc::FL_SRC_AND_DST_DIR_ARE_THE_SAME) {die 'Каталог с исходными данными и каталог назначения совпадают!'}

=head1 ФУНКЦИИ

=cut
use utf8;
use v5.18;
use warnings;
use integer;
use vars qw(
	@EXPORT_OK
	$FL_SRC_DIR_NOT_FOUND
	$FL_DST_DIR_NOT_FOUND
	$FL_SRCEN_DIR_NOT_FOUND
	$FL_SRCRU_DIR_NOT_FOUND
	$FL_DSTRU_DIR_NOT_FOUND
	$FL_SRC_AND_DST_DIR_ARE_THE_SAME
	$ENC_NULL
	$ENC_CP1252A
	$ENC_CP1252B
	$ENC_CP1252C
	$ENC_TRANSLIT
	$DEC_CP1252A
	$DEC_CP1252B
	$DEC_CP1252C
	);
use parent qw(Exporter);
use File::Copy;
use File::Spec;
use Cwd qw(abs_path);
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Encode qw(encode decode);
use Encode::Locale;
use Encode::Recodenc;
@EXPORT_OK = qw(l10n_eu4 l10n_eu4_lite l10n_eu4_tags l10n_eu4_dlc l10n_ck2 l10n_ck2_lite l10n_ck2_tags font modexport plaintext encodelf decodelf);

*FL_SRC_DIR_NOT_FOUND = \1;
*FL_DST_DIR_NOT_FOUND = \2;
*FL_SRCEN_DIR_NOT_FOUND = \3;
*FL_SRCRU_DIR_NOT_FOUND = \4;
*FL_DSTRU_DIR_NOT_FOUND = \5;
*FL_SRC_AND_DST_DIR_ARE_THE_SAME = \6;
*ENC_NULL = \0;
*ENC_CP1252A = \1;
*ENC_CP1252B = \2;
*ENC_CP1252C = \3;
*ENC_TRANSLIT = \4;
*DEC_CP1252A = \5;
*DEC_CP1252B = \6;
*DEC_CP1252C = \7;

# Примечания к константам:
# - FL_* — одно пространство имён
# - ENC_* и DEC_* — одно пространтсво имён

################################################################################
# КОД ДЛЯ ВЫПОЛНЕНИЯ ПЕРЕД ВЫЗОВАМИ ФУНКЦИЙ
################################################################################
# Объявление кодировок для FNT
my %cp1252a = (
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

my %cp1252b = (
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

my %cp1252c = (
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

################################################################################
# ЭКСПОРТИРУЕМЫЕ ФУНКЦИИ
################################################################################
# Encode Localisation for EU4
sub l10n_eu4 { # r
=head2 l10n_eu4

Функция для кодировки и декодировки локализации EU4.

=head3 Параметры

=head4 Параметр №1

    $ENC_CP1252A # кодировать из UTF8 в CP1252A
    $ENC_CP1252B # кодировать из UTF8 в CP1252B
    $ENC_TRANSLIT # транслитерировать в рамках UTF8
    $DEC_CP1252A # декодировать из CP1252A в UTF8
    $DEC_CP1252B # декодировать из CP1252B в UTF8

=head4 Параметр №2

Каталог для обработки.

=head4 Параметр №3

Каталог сохранения.
(Необязателен. При указании обработанные данные сохраняются в структуру файлов в указанном каталоге)

=cut
	# чтение параметров
	my ($cpfl, $dir1, $dir2) = @_;
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {return $FL_SRC_DIR_NOT_FOUND};
	if (defined($dir2)) {
		unless (-d encode('locale_fs', $dir2)) {return $FL_DST_DIR_NOT_FOUND}
		if (decode('locale_fs', abs_path(encode('locale_fs', $dir1))) eq
		    decode('locale_fs', abs_path(encode('locale_fs', $dir2)))) {
			return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
		}
	}
	# работа
	my @filenames = grep { m/\.(?:yml|txt)$/ } flwc($dir1);
	foreach my $filename (@filenames) {
		if ($filename =~ m/\.yml$/) {
			open(my $filehandle, '<:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir1/$filename"));
			my $sof; # отбрасывание BOM, если он есть
			read($filehandle, $sof, 1);
			unless ($sof eq "\x{FEFF}") {seek($filehandle, 0, 0)}
			my $fl = 0; # флаг нужности/ненужности обработки строк
			my @strs; # объявление хранилища строк
			push(@strs, "\x{FEFF}"); # добавление BOM в начало файла
			while (my $str = <$filehandle>) {
				chomp $str;
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
				if    ($cpfl == $ENC_CP1252A) {
					$txt = decode('cp1252', encode('cp1252a', $txt));
				}
				elsif ($cpfl == $ENC_CP1252B) {
					$txt = decode('cp1252', encode('cp1252b', $txt));
				}
				elsif ($cpfl == $ENC_TRANSLIT) {
					&cyr_to_translit(\$txt);
				}
				elsif ($cpfl == $DEC_CP1252A) {
					$txt = decode('cp1252a', encode('cp1252', $txt));
				}
				elsif ($cpfl == $DEC_CP1252B) {
					$txt = decode('cp1252b', encode('cp1252', $txt));
				}
				# сохранение строки
				if (defined($cmm)) {
					push(@strs, " $tag:$num \"$txt\" #$cmm\n");
				}
				else {
					push(@strs, " $tag:$num \"$txt\"\n");
				}
			}
			close $filehandle;
			undef $filehandle;
			# запись результатов обработки
			unless (defined($dir2)) {$dir2 = $dir1}
			unless (open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir2/$filename"))) {
				my @catalogues = File::Spec->splitdir($filename);
				@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
				if (@catalogues) {
					catcr($dir2, @catalogues);
				}
				open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir2/$filename")) or die "Невозможно открыть файл: $!";
			}
			print $filehandle @strs;
			close $filehandle;
		}
		elsif ($filename =~ m/\.txt$/) {
			if (defined($dir2)) {
				my @catalogues = File::Spec->splitdir($filename);
				@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
				if (@catalogues) {
					catcr($dir2, @catalogues);
				}
				copy(encodelf("$dir1/$filename"), encodelf("$dir2/$filename"))
			}
		}
	}
	return 0;
}
# Build Lite Localisation for EU4
sub l10n_eu4_lite { # r
=head2 l10n_eu4_lite

Функция для постройки Lite-локализации EU4.

=head3 Параметры

=head4 Параметр №1

    $ENC_CP1252A # кодировать из UTF8 в CP1252A
    $ENC_CP1252B # кодировать из UTF8 в CP1252B
    $ENC_TRANSLIT # транслитерировать в рамках UTF8

=head4 Параметр №2

Каталог с оригинальной английской локализацией.

=head4 Параметр №3

Каталог с русской локализацией.

=head4 Параметр №4

Каталог для сохранения результата.

=cut
	# чтение параметров
	my ($cpfl, $dir_orig_en, $dir_orig_ru, $dir_save_ru) = @_;
	# проверка параметров
	unless (-d encode('locale_fs', $dir_orig_en)) {return $FL_SRCEN_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_orig_ru)) {return $FL_SRCRU_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_save_ru)) {return $FL_DSTRU_DIR_NOT_FOUND}
	if (decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_en))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_ru))) or
	    decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_ru))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_save_ru))) or
	    decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_en))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_save_ru)))) {
		return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
	}
	# работа
	my @filenames = grep { m/\.(?:yml|txt)$/ } flwc($dir_orig_ru);
	foreach my $filename (@filenames) {
		if ($filename =~ m/\.yml$/) {
			open(my $filehandle, '<:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_orig_ru/$filename"));
			my $sof; # отбрасывание BOM, если он есть
			read($filehandle, $sof, 1);
			unless ($sof eq "\x{FEFF}") {seek($filehandle, 0, 0)}
			my $fl = 0; # флаг нужности/ненужности обработки строк
			my @strs;
			push(@strs, "\x{FEFF}");
			while (my $str = <$filehandle>) {
				chomp $str;
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
				if    ($cpfl == $ENC_CP1252A) {
					$txt = decode('cp1252', encode('cp1252a', $txt));
				}
				elsif ($cpfl == $ENC_CP1252B) {
					$txt = decode('cp1252', encode('cp1252b', $txt));
				}
				elsif ($cpfl == $ENC_TRANSLIT) {
					&cyr_to_translit(\$txt);
				}
				# сохранение строки
				if (defined($cmm)) {
					push(@strs, " $tag:$num \"$txt\" #$cmm\n");
				}
				else {
					push(@strs, " $tag:$num \"$txt\"\n");
				}
			}
			close $filehandle;
			undef $filehandle;
			# запись результатов обработки
			unless (open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/$filename"))) {
				my @catalogues = File::Spec->splitdir($filename);
				@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
				if (@catalogues) {
					catcr($dir_save_ru, @catalogues);
				}
				open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/$filename")) or die "Невозможно открыть файл: $!";
			}
			print $filehandle @strs;
			close $filehandle;
		}
		elsif ($filename =~ m/\.txt$/) {
			my @catalogues = File::Spec->splitdir($filename);
			@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
			if (@catalogues) {
				catcr($dir_save_ru, @catalogues);
			}
			copy(encodelf("$dir_orig_ru/$filename"), encodelf("$dir_save_ru/$filename"))
		}
	}
	undef @filenames;
	@filenames = ('prov_names_l_english.yml', 'prov_names_adj_l_english.yml');
	foreach my $filename (@filenames) {
		open(my $filehandle, '<:unix:perlio:encoding(utf-8)', encodelf("$dir_orig_en/$filename"));
		my $sof; # отбрасывание BOM, если он есть
		read($filehandle, $sof, 1);
		unless ($sof eq "\x{FEFF}") {seek($filehandle, 0, 0)}
		my @strs;
		push(@strs, "\x{FEFF}");
		while (my $str = <$filehandle>) {
			chomp $str;
			if ($str =~ m/^\#/ or $str =~ m/^ \#/ or $str =~ m/^$/ or $str =~ m/^ $/) {push(@strs, "$str\n"); next}
			if ($str =~ m/^l_/) {
				$str =~ s/l_english/l_russian/;
				push(@strs, "$str\n");
				next;
			}
			if ($cpfl == $ENC_CP1252A) {
				# деление строки
				my ($tag, $num, $txt, $cmm) = &yml_string($str);
				# обработка строки
				$txt =~ y(ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöøùúûüýþÿ)
				         (AAAAAAACEEEEIIIIDNOOOOOOUUUUYTsaaaaaaaceeeeiiiidnoooooouuuuyty);
				# сохранение строки
				if (defined($cmm)) {
					push(@strs, " $tag:$num \"$txt\" #$cmm\n");
				}
				else {
					push(@strs, " $tag:$num \"$txt\"\n");
				}
			}
			else {push(@strs, "$str\n")}
		}
		close $filehandle;
		undef $filehandle;
		# запись результатов обработки
		$filename =~ s/_l_english\.yml/_l_russian\.yml/;
		open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/$filename"));
		print $filehandle @strs;
		close $filehandle;
	}
	return 0;
}
# Print EU4 Tags
sub l10n_eu4_tags { # r
=head2 l10n_eu4_tags

Функция для вывода тэгов локализации EU4.

=head3 Параметры

=head4 Параметр №1

Каталог с оригинальной английской локализацией.

=head4 Параметр №2

Каталог с русской локализацией.

=head4 Параметр №3

Каталог для сохранения результата.

=cut
	# чтение параметров
	my ($dir_orig_en, $dir_orig_ru, $dir_save_ru) = @_;
	# проверка параметров
	unless (-d encode('locale_fs', $dir_orig_en)) {return $FL_SRCEN_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_orig_ru)) {return $FL_SRCRU_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_save_ru)) {return $FL_DSTRU_DIR_NOT_FOUND}
	my @par = ($dir_orig_en, $dir_orig_ru, $dir_save_ru);
	for (my $i = 0; $i < (scalar(@par) - 1); $i++) {
		for (my $j = $i + 1; $j < scalar(@par); $j++) {
			if (decode('locale_fs', abs_path(encode('locale_fs', $par[$i]))) eq decode('locale_fs', abs_path(encode('locale_fs', $par[$j])))) {
				return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
			}
		}
	}
	undef @par;
	# работа
	# русская локализация
	my @filenames = grep { m/\.yml$/ && $_ ne 'languages.yml' } flwc($dir_orig_ru);
	mkdir(encode('locale_fs', "$dir_save_ru/ru"));
	foreach my $filename (@filenames) {
		open(my $filehandle, '<:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_orig_ru/$filename"));
		my $sof; # отбрасывание BOM, если он есть
		read($filehandle, $sof, 1);
		unless ($sof eq "\x{FEFF}") {seek($filehandle, 0, 0)}
		my @strs;
		push(@strs, "\x{FEFF}");
		while (my $str = <$filehandle>) {
			chomp $str;
			# пропуск необрабатываемых строк
			if ($str =~ m/^\#/ or $str =~ m/^ \#/ or $str =~ m/^$/ or $str =~ m/^ $/ or $str =~ m/^l_/) {next}
			# деление строки
			my ($tag, $num, undef, undef) = &yml_string($str);
			# сохранение строки
			push(@strs, "$tag:$num\n");
		}
		close $filehandle;
		undef $filehandle;
		# запись результатов обработки
		$filename =~ s/_l_russian//;
		unless (open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/ru/$filename"))) {
			my @catalogues = File::Spec->splitdir($filename);
			@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
			if (@catalogues) {
				catcr("$dir_save_ru/ru", @catalogues);
			}
			open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/ru/$filename")) or die "Невозможно открыть файл: $!";
		}
		print $filehandle @strs;
		close $filehandle;
	}
	undef @filenames;
	# английская локализация из /localisation/
	@filenames = grep { m/_l_english\.yml$/ && $_ ne 'languages.yml' } flwc($dir_orig_en);
	mkdir(encode('locale_fs', "$dir_save_ru/en"));
	foreach my $filename (@filenames) {
		open(my $filehandle, '<:crlf:perlio:encoding(utf-8)', encode('locale_fs', "$dir_orig_en/$filename"));
		my $sof; # отбрасывание BOM, если он есть
		read($filehandle, $sof, 1);
		unless ($sof eq "\x{FEFF}") {seek($filehandle, 0, 0)}
		my @strs;
		push(@strs, "\x{FEFF}");
		while (my $str = <$filehandle>) {
			chomp $str;
			# пропуск необрабатываемых строк
			if ($str =~ m/^\#/ or $str =~ m/^ \#/ or $str =~ m/^$/ or $str =~ m/^ $/ or $str =~ m/^l_/) {next}
			# деление строки
			my ($tag, $num, undef, undef) = &yml_string($str);
			# сохранение строки
			push(@strs, "$tag:$num\n");
		}
		close $filehandle;
		undef $filehandle;
		# запись результатов обработки
		$filename =~ s/_l_english//;
		unless (open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/en/$filename"))) {
			my @catalogues = File::Spec->splitdir($filename);
			@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
			if (@catalogues) {
				catcr("$dir_save_ru/en", @catalogues);
			}
			open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/en/$filename")) or die "Невозможно открыть файл: $!";
		}
		print $filehandle @strs;
		close $filehandle;
	}
	undef @filenames;
	return 0;
}
sub l10n_eu4_dlc {
=head2 l10n_eu4_dlc

Функция для распаковки английской локализации из zip-архивов DLC.

=head3 Параметры

=head4 Параметр №1

Каталог с zip-архивами DLC.

=head4 Параметр №2

Каталог назначения для распаковки.

=cut
	# чтение параметров
	my ($dir_dlc, $dir_dst) = @_;
	# проверка параметров
	unless (-d encode('locale_fs', $dir_dlc)) {return $FL_SRC_DIR_NOT_FOUND};
	unless (-d encode('locale_fs', $dir_dst)) {return $FL_DST_DIR_NOT_FOUND};
	if (decode('locale_fs', abs_path(encode('locale_fs', $dir_dlc))) eq
	    decode('locale_fs', abs_path(encode('locale_fs', $dir_dst)))) {
		return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
	}
	# работа
	opendir(my $ch, encode('locale_fs', $dir_dlc));
	my @filenames = grep { m/\.zip$/ } map {decode('locale_fs', $_)} readdir $ch;
	closedir($ch);
	foreach my $filename (@filenames) {
		my $zip = Archive::Zip->new();
		unless ($zip->read(encode('locale_fs', "$dir_dlc/$filename")) == AZ_OK) {die "При чтении архива `$filename' прозошла ошибка.\n"};
		my @members = $zip->membersMatching('localisation/.*\.yml');
		if (scalar(@members) > 0) {
			foreach my $member (@members) {
				my @flnm = split(/\//, $member->fileName());
				my $flnm = $flnm[-1];
				$zip->extractMemberWithoutPaths($member, encode('locale_fs', "$dir_dst/$flnm"));
			}
		}
	}
	return 0;
}
# Encode Localisation for CK2
sub l10n_ck2 { # r
=head2 l10n_ck2

Функция для кодировки и декодировки локализации CK2.

=head3 Параметры

=head4 Параметр №1

    $ENC_CP1252A # кодировать из UTF8 в CP1252A
    $ENC_CP1252C # кодировать из UTF8 в CP1252C
    $ENC_TRANSLIT # транслитерировать в CP1252
    $DEC_CP1252A # декодировать из CP1252A в UTF8
    $DEC_CP1252C # декодировать из CP1252C в UTF8

=head4 Параметр №2

Каталог для обработки.

=head4 Параметр №3

Каталог сохранения.
(Необязателен. При указании обработанные данные сохраняются в структуру файлов в указанном каталоге)

=cut
	# чтение параметров
	my ($cpfl, $dir1, $dir2) = @_;
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {return $FL_SRC_DIR_NOT_FOUND};
	if (defined($dir2)) {
		unless (-d encode('locale_fs', $dir2)) {return $FL_DST_DIR_NOT_FOUND}
		if (decode('locale_fs', abs_path(encode('locale_fs', $dir1))) eq
		    decode('locale_fs', abs_path(encode('locale_fs', $dir2)))) {
			return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
		}
	}
	# работа
	my ($reg_read, $reg_write);
	if ($cpfl == $ENC_CP1252A or $cpfl == $ENC_CP1252C or $cpfl == $ENC_TRANSLIT) {$reg_read = ':unix:perlio:encoding(utf-8)'; $reg_write = ':crlf:perlio:encoding(cp1252)'}
	elsif ($cpfl == $DEC_CP1252A or $cpfl == $DEC_CP1252C) {$reg_read = ':crlf:perlio:encoding(cp1252)'; $reg_write = ':unix:perlio:encoding(utf-8)'}
	my @filenames = grep { m/\.(?:csv|txt)$/ } flwc($dir1);
	foreach my $filename (@filenames) {
		if ($filename =~ m/\.csv$/) {
			open(my $filehandle, "<$reg_read", encode('locale_fs', "$dir1/$filename"));
			if ($cpfl == $ENC_CP1252A or $cpfl == $ENC_CP1252C or $cpfl == $ENC_TRANSLIT) {
				my $sof; # отбрасывание BOM, если он есть
				read($filehandle, $sof, 1);
				unless ($sof eq "\x{FEFF}") {seek($filehandle, 0, 0)}
			}
			my @strs;
			while (my $str = <$filehandle>) {
				chomp $str;
				if ($str =~ m/^$/ or $str =~ m/^\#/ or $str =~ m/^;/) {next}
				# деление строки
				my ($tag, $txt) = split(/;/, $str, 3);
				# обработка строки
				if    ($cpfl == $ENC_CP1252A) {
					$txt = decode('cp1252', encode('cp1252a', $txt));
				}
				elsif ($cpfl == $ENC_CP1252C) {
					$txt = decode('cp1252', encode('cp1252c', $txt));
				}
				elsif ($cpfl == $ENC_TRANSLIT) {
					&cyr_to_translit(\$txt);
				}
				elsif ($cpfl == $DEC_CP1252A) {
					$txt = decode('cp1252a', encode('cp1252', $txt));
				}
				elsif ($cpfl == $DEC_CP1252C) {
					$txt = decode('cp1252c', encode('cp1252', $txt));
				}
				# сохранение строки
				push(@strs, "$tag;$txt;x\n");
			}
			close $filehandle;
			undef $filehandle;
			# запись результатов обработки
			unless (defined($dir2)) {$dir2 = $dir1}
			unless (open($filehandle, ">$reg_write", encode('locale_fs', "$dir2/$filename"))) {
				my @catalogues = File::Spec->splitdir($filename);
				@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
				if (@catalogues) {
					catcr($dir2, @catalogues);
				}
				open($filehandle, ">$reg_write", encode('locale_fs', "$dir2/$filename")) or die "Невозможно открыть файл: $!";
			}
			print $filehandle @strs;
			close $filehandle;
		}
		elsif ($filename =~ m/\.txt$/) {
			if (defined($dir2)) {
				my @catalogues = File::Spec->splitdir($filename);
				@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
				if (@catalogues) {
					catcr($dir2, @catalogues);
				}
				copy(encodelf("$dir1/$filename"), encodelf("$dir2/$filename"))
			}
		}
	}
	return 0;
}
# Build Lite Localisation for CK2
sub l10n_ck2_lite {
=head2 l10n_ck2_lite

Функция для постройки Lite-локализации CK2.

=head3 Параметры

=head4 Параметр №1

    $ENC_CP1252A # кодировать из UTF8 в CP1252A
    $ENC_CP1252C # кодировать из UTF8 в CP1252C
    $ENC_TRANSLIT # транслитерировать в CP1252

=head4 Параметр №2

Каталог с оригинальной английской локализацией.

=head4 Параметр №3

Каталог с русской локализацией.

=head4 Параметр №4

Каталог для сохранения результата.

=cut
	# чтение параметров
	my ($cpfl, $dir_orig_en, $dir_orig_ru, $dir_save_ru) = @_;
	# проверка параметров
	unless (-d encode('locale_fs', $dir_orig_en)) {return $FL_SRCEN_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_orig_ru)) {return $FL_SRCRU_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_save_ru)) {return $FL_DSTRU_DIR_NOT_FOUND}
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
		open(my $filehandle, '<:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_orig_ru/$filename"));
		my $sof; # отбрасывание BOM, если он есть
		read($filehandle, $sof, 1);
		unless ($sof eq "\x{FEFF}") {seek($filehandle, 0, 0)}
		while (my $str = <$filehandle>) {
			chomp $str;
			if ($str =~ m/^$/ or $str =~ m/^\#/ or $str =~ m/^;/) {next} # пропуск пустых строк, строк с комментариями и строк без тегов
			my $tag = $str;
			($tag, undef) = split(/;/, $tag, 2);
#			$tag =~ s/;.*$//; # TODO: найти, что быстрее в извлечении полей — split или регулярные выражения?
			my $trns = $str;
			(undef, $trns, undef) = split(/;/, $trns, 3);
#			$trns =~ s/^[^;]*;//;
#			$trns =~ s/;.*$//;
			$loc_ru{$tag} = $trns;
		}
		close $filehandle;
	}
	opendir(my $coeh, encode('locale_fs', $dir_orig_en));
	my @filenames_oe = grep { m/\.csv$/ } map {decode('locale_fs', $_)} readdir $coeh;
	closedir($coeh);
	foreach my $filename (@filenames_oe) {
		open(my $filehandle, '<:crlf:encoding(cp1252)', encode('locale_fs', "$dir_orig_en/$filename"));
		my $ff; # флаг содержания файла
		my @strs; # хранилище строк
		push(@strs, "#CODE;RUSSIAN;x\n");
#		push(@strs, "#CODE;ENGLISH;x\n");
		while (my $str = <$filehandle>) {
			$str =~ s/\x{FFFD}//g;
			chomp($str);
			if ($str =~ m/^$/ or $str =~ m/^\#/ or $str =~ m/^;/) {next}
			my $tag = $str;
			($tag, undef) = split(/;/, $tag, 2);
#			$tag =~ s/;.*$//;
			my $trns = $str;
			(undef, $trns, undef) = split(/;/, $trns, 3);
#			$trns =~ s/^[^;]*;//;
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
				if ($cpfl == $ENC_CP1252A) {
					$trru = decode('cp1252', encode('cp1252a', $trru));
				}
				elsif ($cpfl == $ENC_CP1252C) {
					$trru = decode('cp1252', encode('cp1252c', $trru));
				}
				elsif ($cpfl == $ENC_TRANSLIT) {
					&cyr_to_translit(\$trru);
				}
				$st = "$tag;$trru;x\n";
			}
			elsif (!defined($loc_ru{$tag})) {
				$st = "$tag;$trns;x\n";
			}
			if (defined($st)) {
				push(@strs, $st);
			}
			$ff = 1; # установка флага содержания
		}
		close $filehandle;
		undef $filehandle;
		unless (defined($ff)) {next}
		open($filehandle, '>:unix:crlf:encoding(cp1252)', encode('locale_fs', "$dir_save_ru/$filename"));
		print $filehandle @strs;
		close $filehandle;
	}
	return 0;
}
# Print CK2 Tags
sub l10n_ck2_tags { # r
=head2 l10n_ck2_tags

Функция для вывода тэгов локализации CK2.

=head3 Параметры

=head4 Параметр №1

Каталог с оригинальной английской локализацией.

=head4 Параметр №2

Каталог с русской локализацией.

=head4 Параметр №3

Каталог для сохранения результата.

=cut
	# чтение параметров
	my ($dir_orig_en, $dir_orig_ru, $dir_save_ru) = @_;
	# проверка параметров
	unless (-d encode('locale_fs', $dir_orig_en)) {return $FL_SRCEN_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_orig_ru)) {return $FL_SRCRU_DIR_NOT_FOUND}
	unless (-d encode('locale_fs', $dir_save_ru)) {return $FL_DSTRU_DIR_NOT_FOUND}
	if (decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_en))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_ru))) or
	    decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_ru))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_save_ru))) or
	    decode('locale_fs', abs_path(encode('locale_fs', $dir_orig_en))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir_save_ru)))) {
		return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
	}
	# работа
	my @filenames_or = grep { m/\.csv$/ } flwc($dir_orig_ru);
	mkdir(encode('locale_fs', "$dir_save_ru/ru"));
	foreach my $filename (@filenames_or) {
		open(my $filehandle, '<:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_orig_ru/$filename"));
		my $sof; # отбрасывание BOM, если он есть
		read($filehandle, $sof, 1);
		unless ($sof eq "\x{FEFF}") {seek($filehandle, 0, 0)}
		my $ff;
		my @strs;
		push(@strs, "\x{FEFF}#CODE\n");
		while (my $str = <$filehandle>) {
			chomp $str;
			if ($str =~ m/^$/ or $str =~ m/^\#/ or $str =~ m/^;/) {next}
			my $tag = $str;
			($tag, undef) = split(/;/, $tag, 2);
#			$tag =~ s/;.*$//;
			push(@strs, "$tag\n");
			$ff = 1;
		}
		close $filehandle;
		undef $filehandle;
		unless (defined($ff)) {next}
		unless (open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/ru/$filename"))) {
			my @catalogues = File::Spec->splitdir($filename);
			@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
			if (@catalogues) {
				catcr("$dir_save_ru/ru", @catalogues);
			}
			open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/ru/$filename")) or die "Невозможно открыть файл: $!";
		}
		print $filehandle @strs;
		close $filehandle;
	}
	my @filenames_oe = grep { m/\.csv$/ } flwc($dir_orig_en);
	mkdir(encode('locale_fs', "$dir_save_ru/en"));
	foreach my $filename (@filenames_oe) {
		open(my $filehandle, '<:raw', encode('locale_fs', "$dir_orig_en/$filename"));
		my $ff;
		my @strs;
		push(@strs, "\x{FEFF}#CODE\n");
		while (my $str = <$filehandle>) {
			$str = decode('cp1252', $str);
			$str =~ s/\x{FFFD}//g;
			$str =~ s/\r$//;
			chomp($str);
			if ($str =~ m/^$/ or $str =~ m/^\#/ or $str =~ m/^;/) {next}
			my $tag = $str;
			($tag, undef) = split(/;/, $tag, 2);
#			$tag =~ s/;.*$//;
			push(@strs, "$tag\n");
			$ff = 1;
		}
		close $filehandle;
		undef $filehandle;
		unless (defined($ff)) {next}
		unless (open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/en/$filename"))) {
			my @catalogues = File::Spec->splitdir($filename);
			@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
			if (@catalogues) {
				catcr("$dir_save_ru/en", @catalogues);
			}
			open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir_save_ru/en/$filename")) or die "Невозможно открыть файл: $!";
		}
		print $filehandle @strs;
		close $filehandle;
	}
	return 0;
}
# Очистка и модификация карт шрифтов
sub font { # r
=head2 font

Функция для очистки и модификации карт шрифтов.

=head3 Параметры

=head4 Параметр №1

    $ENC_NULL # только очистить
    $ENC_CP1252A # обработка CP1252A
    $ENC_CP1252B # обработка CP1252B
    $ENC_CP1252C # обработка CP1252C

=head4 Параметр №2

Каталог для обработки.

=head4 Параметр №3

Каталог сохранения.
(Необязателен. При указании обработанные данные сохраняются в структуру файлов в указанном каталоге)

=cut
	# чтение параметров
	my ($cpfl, $dir1, $dir2) = @_;
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {return $FL_SRC_DIR_NOT_FOUND}
	if (defined($dir2)) {
		unless (-d encode('locale_fs', $dir2)) {return $FL_DST_DIR_NOT_FOUND}
		if (decode('locale_fs', abs_path(encode('locale_fs', $dir1))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir2)))) {
			return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
		}
	}
	# работа
	my @filenames = grep { m/(?:\.fnt|\.tga|\.dds)$/ } flwc($dir1);
	foreach my $filename (@filenames) {
		if ($filename =~ m/\.fnt$/) {
			open(my $filehandle, '<:unix:crlf', encode('locale_fs', "$dir1/$filename"));
			my @strs;
			while (my $str = <$filehandle>) {
				chomp $str;
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
					unless ($cpfl == $ENC_NULL) {#если КОДИРОВКА, то заменить номера символов
						&id_to(\$str_id[1], $cpfl);
					}
					delete($str_id[10]);
					push(@strs, "@str_id\n"); next;
				}
				if ($str =~ m/^kerning/) {
					my @str_kerning = split(" ", $str);
					unless ($cpfl == $ENC_NULL) {#если КОДИРОВКА, то заменить номера символов
						&id_to(\$str_kerning[1], $cpfl);
						&id_to(\$str_kerning[2], $cpfl);
					}
					push(@strs, "@str_kerning\n"); next;
				}
			}
			close $filehandle;
			undef $filehandle;
			# сортировка
			unless ($cpfl == $ENC_NULL) {#если КОДИРОВКА, то сортировать
				my $kr;
				for (my $i = 2; $i < scalar(@strs); $i++) {
					if ($strs[$i] =~ m/^kernings/) {$kr = $i - 1; last}
				}
				unless (defined($kr)) {$kr = scalar(@strs) - 1}
				# участок массива от третьей строки до последней строки перед m/^kernings/ или концом файла сортируется по числам столбца id=
				@strs[2..$kr] = sort {&srt($a, $b)} @strs[2..$kr];
			}
			# /сортировка
			# запись результатов обработки
			unless (defined($dir2)) {$dir2 = $dir1}
			unless (open($filehandle, '>:unix:crlf', encode('locale_fs', "$dir2/$filename"))) {
				my @catalogues = File::Spec->splitdir($filename);
				@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
				if (@catalogues) {
					catcr($dir2, @catalogues);
				}
				open($filehandle, '>:unix:crlf', encode('locale_fs', "$dir2/$filename")) or die "Невозможно открыть файл: $!";
			}
			print $filehandle @strs;
			close $filehandle;
		}
		elsif ($filename =~ m/\.(?:tga|dds)$/) {
			my $new_name = $filename;
			$new_name =~ s/_0\.tga$/\.tga/;
			$new_name =~ s/_0\.dds$/\.dds/;
			if (defined($dir2)) {
				my @catalogues = File::Spec->splitdir($filename);
				@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
				if (@catalogues) {
					catcr($dir2, @catalogues);
				}
				copy(encode('locale_fs', "$dir1/$filename"), encode('locale_fs', "$dir2/$new_name"));
			}
			else {
				if ($filename eq $new_name) {next}
				rename(encode('locale_fs', "$dir1/$filename"), encode('locale_fs', "$dir1/$new_name"));
			}
		}
	}
	return 0;
}
# Конвертирование файлов локализации мода-сейва из CK2 в EU4
sub modexport { # r
=head2 modexport

Функция для конвертирования файлов локализации мода-сейва из CK2 в EU4.

=head3 Параметры

=head4 Параметр №1

    $ENC_CP1252A # локализация закодирована в CP1251
    $ENC_CP1252B # локализация закодирована в CP1252B

=head4 Параметр №2

Каталог для обработки.

=head4 Параметр №3

Каталог сохранения.
(Необязателен. При указании обработанные данные сохраняются в структуру файлов в указанном каталоге)

=cut
	# чтение параметров
	my ($cpfl, $dir1, $dir2) = @_;
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {return $FL_SRC_DIR_NOT_FOUND}
	if (defined($dir2)) {
		unless (-d encode('locale_fs', $dir2)) {return $FL_DST_DIR_NOT_FOUND}
		if (decode('locale_fs', abs_path(encode('locale_fs', $dir1))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir2)))) {
			return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
		}
	};
	# работа
	my @filenames = grep { m/\.yml$/ } flwc($dir1);
	foreach my $filename (@filenames) {
		# удаление файлов локализации других языков
		if ($filename =~ m/_l_french\.yml$/ or
		    $filename =~ m/_l_german\.yml$/ or
		    $filename =~ m/_l_spanish\.yml$/) {
			unless (defined($dir2)) {
				unlink encode('locale_fs', "$dir1/$filename");
			}
			next;
		}
		# удаление лишних файлов
		if ($filename =~ m/converted_custom_countries_l_english\.yml$/ or
		    $filename =~ m/converted_custom_deities_l_english\.yml$/ or
		    $filename =~ m/converted_custom_ideas_l_english\.yml$/ or
		    $filename =~ m/converted_heresies_l_english\.yml$/ or
		    $filename =~ m/converted_misc_l_english\.yml$/ or
		    $filename =~ m/converted_religions_l_english\.yml$/ or
		    $filename =~ m/new_converter_texts_l_english\.yml$/ or
		    $filename =~ m/sunset_invasion_custom_countries_l_english\.yml$/ or
		    $filename =~ m/sunset_invasion_custom_ideas_l_english\.yml$/ or
		    $filename =~ m/sunset_invasion_custom_technology_groups_l_english\.yml$/) {
			unless (defined($dir2)) {
				unlink encode('locale_fs', "$dir1/$filename");
			}
			next;
		}
		open(my $filehandle, '<:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir1/$filename"));
		my @strs;
		push(@strs, "\x{FEFF}");
		while (my $str = <$filehandle>) {
			if ($str =~ m/^\x{FEFF}/) {$str =~ s/^\x{FEFF}//}
			if ($str =~ m/^\#/ or $str =~ m/^ \#/ or $str =~ m/^$/ or $str =~ m/^ $/) {push(@strs, $str); next}
			if ($str =~ m/^l_english/) {$str =~ s/l_english/l_russian/; push(@strs, $str); next}
			chomp $str;
			# деление строки
			my ($tag, $num, $txt, $cmm) = &yml_string($str);
			# обработка строки
			$txt =~ y(‚ѓ„…†‡€‰Љ‹ЊЋ‘’“”•–—™љ›њћџ ЎўҐ¦Ё©Є«¬®Ї°±Ііґµ¶·ё№є»јѕїАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя)
			         (‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ ¡¢¥¦¨©ª«¬®¯°±²³´µ¶·¸¹º»¼¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ);
			if ($cpfl == $ENC_CP1252A) {
				if ($filename =~ m/converted_cultures/) {
					$txt =~ s/\x7f\x11$/àÿ/;
				}
				if ($tag =~ m/^..._ADJ$/) {
					$txt .= 'ñê';
				}
			}
			elsif ($cpfl == $ENC_CP1252B) {
				$txt =~ y/^/€/;
				if ($filename =~ m/converted_cultures/) {
					$txt =~ s/\x7f\x11$/a÷/;
				}
			}
			# сохранение строки
			push(@strs, " $tag:$num \"$txt\"\n");
		}
		close $filehandle;
		undef $filehandle;
		my $new_name = $filename;
		$new_name =~ s/_l_english\.yml$/_l_russian\.yml/;
		unless (defined($dir2)) {
			rename(encode('locale_fs', "$dir1/$filename"), encode('locale_fs', "$dir1/$new_name"));
		}
		unless (defined($dir2)) {$dir2 = $dir1}
		unless (open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir2/$new_name"))) {
			my @catalogues = File::Spec->splitdir($new_name);
			@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
			if (@catalogues) {
				catcr($dir2, @catalogues);
			}
			open($filehandle, '>:unix:perlio:encoding(utf-8)', encode('locale_fs', "$dir2/$new_name")) or die "Невозможно открыть файл: $!";
		}
		print $filehandle @strs;
		close $filehandle;
	}
	return 0;
}
# Конвертирование файлов простого текста из UTF8 в CP1252A/B/C
sub plaintext { # r
=head2 plaintext

Функция для конвертирования файлов простого текста между UTF8 и кодировками Recodenc.

=head3 Параметры

=head4 Параметр №1

    $ENC_CP1252A # кодировать из UTF8 в CP1252A
    $ENC_CP1252B # кодировать из UTF8 в CP1252B
    $ENC_CP1252C # кодировать из UTF8 в CP1252C
    $ENC_TRANSLIT # транслитерировать в рамках UTF8
    $DEC_CP1252A # декодировать из CP1252A в UTF8
    $DEC_CP1252B # декодировать из CP1252B в UTF8
    $DEC_CP1252C # декодировать из CP1252C в UTF8


=head4 Параметр №2

Каталог для обработки.

=head4 Параметр №3

Каталог сохранения.
(Необязателен. При указании обработанные данные сохраняются в структуру файлов в указанном каталоге)

=cut
	# чтение параметров
	my ($cpfl, $dir1, $dir2) = @_;
	# проверка параметров
	unless (-d encode('locale_fs', $dir1)) {return $FL_SRC_DIR_NOT_FOUND};
	if (defined($dir2)) {
		unless (-d encode('locale_fs', $dir2)) {return $FL_DST_DIR_NOT_FOUND}
		if (decode('locale_fs', abs_path(encode('locale_fs', $dir1))) eq decode('locale_fs', abs_path(encode('locale_fs', $dir2)))) {
			return $FL_SRC_AND_DST_DIR_ARE_THE_SAME
		}
	};
	# работа
	my ($reg_read, $reg_write);
	if    ($cpfl == $ENC_CP1252A)  {$reg_read = ':encoding(utf-8)'; $reg_write = ':encoding(cp1252a)'}
	elsif ($cpfl == $ENC_CP1252C)  {$reg_read = ':encoding(utf-8)'; $reg_write = ':encoding(cp1252c)'}
	elsif ($cpfl == $ENC_CP1252B)  {$reg_read = ':encoding(utf-8)'; $reg_write = ':encoding(cp1252b)'}
	elsif ($cpfl == $ENC_TRANSLIT) {$reg_read = ':encoding(utf-8)'; $reg_write = ':encoding(utf-8)'}
	elsif ($cpfl == $DEC_CP1252A)  {$reg_read = ':encoding(cp1252a)'; $reg_write = ':encoding(utf-8)'}
	elsif ($cpfl == $DEC_CP1252C)  {$reg_read = ':encoding(cp1252c)'; $reg_write = ':encoding(utf-8)'}
	elsif ($cpfl == $DEC_CP1252B)  {$reg_read = ':encoding(cp1252b)'; $reg_write = ':encoding(utf-8)'}
	my @filenames = grep { !m/^\.\.?$/ } flwc($dir1);
	foreach my $filename (@filenames) {
		unless (-f encode('locale_fs', "$dir1/$filename")) {next}
		open(my $filehandle, "<$reg_read", encode('locale_fs', "$dir1/$filename"));
		if ($reg_read eq ':encoding(utf-8)') {
			my $sof; # отбрасывание BOM, если он есть
			read($filehandle, $sof, 1);
			unless ($sof eq "\x{FEFF}") {seek($filehandle, 0, 0)}
		}
		my @strs;
		if ($reg_write eq ':encoding(utf-8)') {push(@strs, "\x{FEFF}")}
		while (my $str = <$filehandle>) {
			if ($cpfl == $ENC_TRANSLIT) {&cyr_to_translit(\$str)}
			push(@strs, "$str");
		}
		close $filehandle;
		undef $filehandle;
		unless (defined($dir2)) {$dir2 = $dir1}
		open($filehandle, ">$reg_write", encode('locale_fs', "$dir2/$filename"));
		unless (open($filehandle, ">$reg_write", encode('locale_fs', "$dir2/$filename"))) {
			my @catalogues = File::Spec->splitdir($filename);
			@catalogues = @catalogues[0..(scalar(@catalogues) - 2)];
			if (@catalogues) {
				catcr($dir2, @catalogues);
			}
			open($filehandle, ">$reg_write", encode('locale_fs', "$dir2/$filename")) or die "Невозможно открыть файл: $!";
		}
		print $filehandle @strs;
		close $filehandle;
	}
	return 0;
}
################################################################################
# СЕРВИСНЫЕ ФУНКЦИИ
################################################################################
# функция разбора правильной YAML-подобной строки файла локализации EU4
sub yml_string {
	my $str = shift;
	return $str =~ m/^ ([^:]+):(\d*) *"(.*?[^\\]?)"(?: *#(.*))?$/;
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

sub sl {
	my ($a, $b) = @_;
	if ($a eq '') {return $b}
	else {return File::Spec->catdir($a, $b)}
}
sub flwc { # file list with catalogues
	my @dirs = @_;
	my $dir = File::Spec->catdir(@dirs);
	my $pref = File::Spec->catdir(@dirs[1..(scalar(@dirs) - 1)]);
	my @filenames;
	opendir(my $ch, encodelf($dir));
	#say "$dirs[0]; $dir; $pref; $_";
	map {if (-d "$dir/$_") {push(@filenames, flwc(@dirs, $_))} else {push(@filenames, sl($pref, $_))}} grep { !m/^\.\.?$/ } map {decodelf($_)} readdir $ch;
	return @filenames;
}
sub catcr { # catalogues creator
	my @dirs = @_;
	my $dir = File::Spec->catdir(@dirs);
	unless (-d encodelf($dir)) {
		if (@dirs[1..(scalar(@dirs) - 2)]) {
			catcr(@dirs[0..(scalar(@dirs) - 2)])
		}
		mkdir(encodelf($dir)) or die "Не удалось создать каталог $dir\n";
	}
}

# ФУНКЦИИ ПРЕОБРАЗОВАНИЯ КОДИРОВОК
# функция для транслитерирования кириллицы
sub cyr_to_translit {
=head2 cyr_to_translit

Функция для транслитерирования кириллицы.

=head3 Параметры

=head4 Параметр №1

Ссылка на строку для преобразования.

=cut
	my $str = shift; # №1
	$$str =~ y(АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя)
	          (ABVGDEËJZIYKLMNOPRSTUFHQCXÇ’ÎYÊÜÄabvgdeëjziyklmnoprstufhqcxç’îyêüä);
}

# функция для замены номеров символов в кодировке юникод на номера для других кодировок
sub id_to {
=head2 id_to

Функция для замены номеров символов в кодировке юникод на номера для других кодировок.

=head3 Параметры

=head4 Параметр №1

Ссылка на строку для преобразования.

=head4 Параметр №2

    $ENC_CP1252A # заменить кодовые позиции Unicode на CP1252A
    $ENC_CP1252B # заменить кодовые позиции Unicode на CP1252B
    $ENC_CP1252C # заменить кодовые позиции Unicode на CP1252C

=cut
	my $str = shift; # №1
	my $reg = shift; # №2
	my @str = split(/=/, $$str, 2);
	if    ($reg == $ENC_CP1252B) {
		if (defined($cp1252b{$str[1]})) {
			$str[1] = $cp1252b{$str[1]}
		}
	}
	elsif ($reg == $ENC_CP1252C) {
		if (defined($cp1252c{$str[1]})) {
			$str[1] = $cp1252c{$str[1]}
		}
	}
	elsif ($reg == $ENC_CP1252A) {
		if (defined($cp1252a{$str[1]})) {
			$str[1] = $cp1252a{$str[1]}
		}
	}
	$$str = "$str[0]=$str[1]";
}

sub encodelf(;$) {
	encode('locale_fs', $_[0]);
}

sub decodelf(;$) {
	decode('locale_fs', $_[0]);
}
1;

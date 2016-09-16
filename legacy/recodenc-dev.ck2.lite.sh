#!/bin/bash
# ******************************************************************************
# * Перекодирует перевод CK2 для его вывода модифицированными шрифтами по карте
# * безопасной кодировки
# * Установите свои значения в секции «ПЕРЕМЕННЫЕ» перед использованием.
# * Скрипт работает только с Lite-переводом.
# ******************************************************************************

# заменить все find -exec на find | xargs

########## ПЕРЕМЕННЫЕ

loc_eng='' # каталог с файлами «*.csv», в которых во втором поле содержится английская локализация
loc_rus='' # каталог с файлами «*.csv», в которых во втором поле содержится русская локализация
loc='' # каталог с результирующей локализацией

########## ДЕЙСТВИЯ

if [[ -z "$loc_eng" ]]; then exit 1; fi
if [[ -z "$loc_rus" ]]; then exit 1; fi
if [[ -z "$loc" ]]; then exit 1; fi

r=$1

# защита от дурака
rm -rf "$loc"/*
mkdir -p "$loc"
# создание временных каталогов для хранения промежуточных баз локализации
mkdir "$loc/ky"
mkdir "$loc/en"
mkdir "$loc/ru"
mkdir "$loc/pd"
# получение колонки с английской локализацией
for i in $(find "$loc_eng" -maxdepth 1 -name '*.csv' -type f)
do
	i=$(echo "$i" | sed 's/.*\///')
	cat "$loc_eng/$i" | tr -d '\r' | iconv -f cp1252 -t utf8//IGNORE | sed 's/^[^;]*//;s/^;//;s/;.*$//' > "$loc/en/$i"
done
# получение колонки с русской локализацией
for i in $(find "$loc_rus" -maxdepth 1 -name '*.csv' -type f)
do
	i=$(echo "$i" | sed 's/.*\///')
	cat "$loc_rus/$i" | tr -d '\r' | iconv -f cp1252 -t utf8//IGNORE | sed 'y/ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/' | tee "$loc/ru/$i" | sed 's/;.*$//' > "$loc/ky/$i"
done
# сравнение ключей, если задан параметр «-u»
if printf "$r" | grep "^-u$" -m1 > /dev/null
then
	printf 'Сравнение ключей локализаций ...\n'
	find "$loc" -type f -print0 | xargs -0 -I{} -P$(nproc) -n1 sed -i 's/;.*$//' \{}
	diff -c -r "$loc/ru" "$loc/en" > "$loc/eq.diff"
	rm -rf "$loc/ky"
	rm -rf "$loc/en"
	rm -rf "$loc/ru"
	rm -rf "$loc/pd"
	printf "Читайте $loc/eq.diff"
	exit 0
fi
# копирование недостающих файлов из $loc/ru
find "$loc/en" "$loc/ru" -type f -print0 | sed -z 's/^.*\///' | sort -z -d | uniq -z -u | xargs -0 -I{} -P$(nproc) mv "$loc/ru/"\{} "$loc"
find "$loc" -maxdepth 1 -type f -print0 | sed -z 's/^.*\///' | xargs -0 -I{} -P$(nproc) rm "$loc/ky/"\{}
# сращивание баз локализаций
find "$loc/ru" -type f -print0 | xargs -0 -I{} -P$(nproc) -n1 sed -i 's/^[^;]*//;s/^;//;s/;.*$//' \{} #ru
for i in $(ls -1 "$loc/ky")
do
	paste -d\; "$loc/ky/$i" "$loc/en/$i" "$loc/ru/$i" | sed 's/$/;x/' > "$loc/pd/$i"
done
# удаление временных каталогов
rm -rf "$loc/ky"
rm -rf "$loc/en"
rm -rf "$loc/ru"
# добавление в русскую локализацию частей английской
for i in $(find "$loc/pd" -type f)
do
	gawk 'BEGIN {FS = ";"; OFS = ";"};{if (/(^PROV[1-9]|^b_|^c_|^d_|^e_|^k_)/) {print $1,$2,"x"} else {print $1,$3,"x"}};' "$i" > "$i".tmp
	mv "$i".tmp "$i"
done
find "$loc/pd" -type f -print0 | xargs -0 -I{} -P$(nproc) -n1 mv \{} "$loc"
rm -rf "$loc/pd"
# очистка свободного места
find "$loc" -type f -print0 | xargs -0 -I{} -P$(nproc) -n1 sed -i "s/^//g;s/€//g;s/‚/'/g;s/ƒ//g;s/„/\"/g;s/…/.../g;s/†//g;s/‡//g;s/ˆ//g;s/‰//g;s/‹/'/g;s/‘/'/g;s/’/'/g;s/“/\"/g;s/”/\"/g;s/•//g;s/–/-/g;s/—/-/g;s/˜//g;s/™//g;s/›/'/g;s/ / /g;s/¢//g;s/¥//g;s/¦//g;s/¨//g;s/©//g;s/ª//g;s/«/\"/g;s/¬//g;s/®//g;s/¯//g;s/°//g;s/±//g;s/²//g;s/³//g;s/´//g;s/µ//g;s/¶//g;s/·//g;s/¸//g;s/¹//g;s/º//g;s/»/\"/g;s/¼//g;s/½//g;s/¾//g;s/×//g;s/÷//g;" \{}
# преобразование кириллицы к виду в модифицированной кодировке
find "$loc" -type f -print0 | xargs -0 -I{} -P$(nproc) -n1 sed -i 'y/АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя/A^B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷/' \{}
# перекодировка в windows-1252
for i in $(find "$loc" -type f)
do
	iconv -f utf8 -t cp1252 "$i" > "$i".tmp
	mv "$i".tmp "$i"
done
# преобразование формата строк в CRLF
find "$loc" -type f -print0 | xargs -0 -I{} -P$(nproc) -n1 sed -i 's/$/\r/' \{}
# выход
exit 0

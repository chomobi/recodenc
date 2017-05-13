use utf8;
use strict;
use Test::More tests => 3;
use Encode;
use Encode::Recodenc;

my $se_cp1252cyreu4 = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя';
my $sd_cp1252cyreu4 = 'A€B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷';

my $se_cp1252cyrck2 = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя';
my $sd_cp1252cyrck2 = 'A^B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷';

my $se_cp1252cp1251 = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя';
my $sd_cp1252cp1251 = 'ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ';

is (decode('cp1252', encode('cp1252cyreu4', $se_cp1252cyreu4)), $sd_cp1252cyreu4, 'CP1252CYREU4: String encoded correctly');
is (decode('cp1252', encode('cp1252cyrck2', $se_cp1252cyrck2)), $sd_cp1252cyrck2, 'CP1252CYRCK2: String encoded correctly');
is (decode('cp1252', encode('cp1252cp1251', $se_cp1252cp1251)), $sd_cp1252cp1251, 'CP1252CP1251: String encoded correctly');

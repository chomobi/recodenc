use utf8;
use strict;
use Test::More tests => 3;
use Encode;
use Encode::Recodenc;

my $se_cp1252a = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя';
my $sd_cp1252a = 'ÀÁÂÃÄÅ¨ÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäå¸æçèéêëìíîïðñòóôõö÷øùúûüýþÿ';

my $se_cp1252b = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя';
my $sd_cp1252b = 'A€B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷';

my $se_cp1252c = 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя';
my $sd_cp1252c = 'A^B‚ƒEË„…†‡KˆMHO‰PCT‹‘X’“”•–—˜™›×a ¢¥¦eë¨©ª«¬®¯°o±pc²³´xµ¶·¸¹º»¼¾÷';

is (decode('cp1252', encode('cp1252a', $se_cp1252a)), $sd_cp1252a, 'CP1252A: String encoded correctly');
is (decode('cp1252', encode('cp1252b', $se_cp1252b)), $sd_cp1252b, 'CP1252B: String encoded correctly');
is (decode('cp1252', encode('cp1252c', $se_cp1252c)), $sd_cp1252c, 'CP1252C: String encoded correctly');

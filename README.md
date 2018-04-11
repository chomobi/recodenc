<!-- 1. -->

## Предисловие

EU4 и CK2 официально локализованы на английский, немецкий, французский, испанский. Для поддержки этих языков достаточно кодировки CP1252 (висьмибитная кодировка), поддержка юникода в движке игры отсутствует. Соответственно, поддержка кириллицы отсутствует. Для нужд русского перевода игры потребовался механизм отображения кириллицы. Т. к. движок игры поддерживает восьмибитную кодировку, заменив поставляемые для поддержки CP1252 шрифты на шрифты для CP1251, можно отобразить кириллицу, закодированную в CP1251. Эти две кодировки совместимы по кодовым позициям ASCII в начале каждой из кодовых страниц (0-127), что позволяет отображать текст в ASCII, но текст, содержащий символы из второй половины кодировки (128-255) CP1252, отображается как кириллица. Эта проблема малозначительна для Full-версии перевода, но для Lite-версии, где смешан текст в латинице и кириллице, она встаёт в полный рост. Для решения проблемы одновременного отображения расширенной латиницы (вторая половина CP1252) и кириллицы я разработал специальную кодировку «[CP1252CYR](http://tiny.cc/recodenc_tableofencoding)», совместимую с CP1252 по расположению латиницы, а специальные типографские символы (напр., ¥) заменил на буквы кириллицы, отсутствующие в литинице. Однако, у кодировки CP1251 есть серьёзное преимущество — сортировка по алфавиту.

Кодировка создавалась, в качестве самой сложной задачи, для того, чтобы в мультиплеерном чате можно было общаться на английском, немецком, французском, испанском и русском (для тех, у кого установлен мод на локализацию). Неиспользуемых типографских символов было меньше, чем необходимых символов кириллицы, поэтому в качестве некоторых символов кириллицы были использованы похожие по начертанию латинские буквы. Сортировка уникальных символов кириллицы, кроме буквы «Яя», в качестве дани истории, идёт по алфавиту: сначала заглавные, потом строчные — аналогично сортировке символов в ASCII, CP1251, CP1252. В адаптации этой кодировки для CK2 символ «Б» был помещён на место «^» из-за ошибок, возникающих при использовании символов «€» и «½».

<!-- 2. -->

## Файлы локализаций

Официальная локализация EU4 поставляется в виде файлов `*.yml`, синтаксис которых похож на YAML, в кодировке UTF-8 с BOM, обрыв строки LF (в формате \*nix). Но движок игры использует CP1252, поэтому на этапе загрузки локализации происходит перекодировка: символы с позиций в кодировке юникод становятся на позиции в кодировке CP1252. Следовательно, чтобы запросить отображение кириллического символа, его код после перекодировки должен соответствовать номеру в шрифте. Поэтому кириллицу, закодированную в UTF-8 на этапе редактирования перевода, нужно заменить на символы, которые после перекодирования движком игры отобразятся как кириллица. В этом нам поможет скрипт Recodenc.

Официальная локализация CK2 поставляется в виде файлов CSV (`*.csv`) в кодировке CP1252, обрыв строки CRLF (в формате windows). Движок непосредственно работает с байтами в кодировке CP1252, поэтому чтобы запросить отображение кириллического символа, нужно сохранить его в соответствующей кодировке непосредственно. Это подходит для CP1251, а для CP1252CYR нужна конвертация (из CP1251). В этом нам поможет скрипт Recodenc.

Все остальные файлы поставляются в кодировке CP1252, обрывы строк CRLF. Редактируются они в кодировке CP1251 при помощи стандартного программного обеспечения (т. к. нужны только для Full-перевода с кодировкой CP1251).

<!-- 3. -->

## Шрифты для отображения

Движок игры сопоставляет кодовую позицию символа с его рисунком в шрифте и выводит его. Существует несколько программ для рендеринга шрифтов, совместимых с движком игры, я использовал [BMFont](http://angelcode.com/products/bmfont/). Сгенерированный шрифт располагается в двух файлах: изображении `*.tga` или `*.dds` и текстовом файле `*.fnt`, содержащим карту изображения и связывающим кодовую позицию символа с его представлением в графическом виде. Сгенерировать растровые шрифты для кодировки CP1251 относительно легко: достаточно указать программе эту кодировку и исходный векторный шрифт. Для создания шрифта для кодировки CP1252CYR необходимо выбрать кодировку юникод и в ней [выбрать символы из CP1252CYR](http://tiny.cc/recodenc_bmf), отрендерить шрифт, и в fnt-файле в столбце «id» и секции кернингов заменить номера кодовых позиций юникода на номера из CP1252CYR. Это можно сделать при помощи скрипта Recodenc.

### Предлагаемые шрифты

<!-- [CP1251 (EU4)]() -->

<!-- [CP1251 (CK2)]() -->

[CP1252CYREU4](https://www.dropbox.com/s/bch2ar6xtpoc0m4/fonts_cp1252%2Bcyr_v1.7z?dl=1)

<!-- [CP1252CYRCK2]() -->

Шрифты предлагаются только для кодировки CP1252CYR, т. к. выбранный шрифт поддерживает только юникод. Чтобы воспользоваться ими, распакуйте скачанный архив в /gfx/fonts/.

<!-- 4. -->

## Раскладка клавиатуры для ввода

Движок игры при вводе с клавиатуры ожидает получить *байтовые* коды символов, которые от выводит в текстовом поле и обрабатывает. Поэтому, когда вводятся символы за пределами однобайтового начала кодировки юникод, windows передаёт коды символов в кодировке UTF-16, что движок игры воспринимает как два отдельных символа и соответственно выводит их в текстовом поле. Для передачи правильных кодов символов необходимы специальные раскладки клавиатуры.

### Предлагаемые раскладки

[CP1251](http://tiny.cc/recodenc_klru1)

[CP1252CYREU4](http://tiny.cc/recodenc_klru2eu4)

[CP1252CYRCK2](http://tiny.cc/recodenc_klru2ck2)

Скачайте по указанным выше ссылкам архивы. В них находятся файлы установщика и исходники раскладок для программы Microsoft Keyboard Layout Creator. Установите нужную вам раскладку клавиатуры или сразу все́, распаковав архивы запустив в распакованных каталогах `setup.exe`.

ПКМ по языковой панели → Параметры... → Переключение клавиатуры → для пункта «Переключить языки ввода» нажмите кнопку «Сменить сочетание клавиш» и в появившемся окне настройте *разные* комбинации клавиш для переключения языков ввода и смены раскладки клавиатуры. Это нужно для того, чтобы пользоваться, например, парой раскладок «стандартная RU — стандартная EN» пока вы работаете в обычных программах, переключить раскладку на языке RU, и использовать пару раскладок «RU Layout for EU4 CP1252CYR — стандартная EN», пока вы играете в EU4.

На вкладке «Общие» проверьте наличие клавиатурных раскладок в секции русского языка, и, при необходимости, измените порядок.

Общее:

* Кавычка (`"`) не работает, поэтому она заменена на одинарную (`'`).
* Знак номера заменён на решётку, т. к. он отсутствует в кодировке CP1252.
* Букву «Ёё» вводить через AltGr(правый Alt)+русская Ее

CP1251:

* CapsLock не работает на буквах: ЯяЧчЁё

CP1252CYR:

* CapsLock работает на буквах: ЕеХхАаРрОоСс

<!-- 5. -->

## Как пользоваться скриптом

Для того, чтобы воспользоваться скриптом, установите Perl не ниже версии 5.18, модули `IUP` (для графического интерфейса; также вам потребуется X11 с GTK+ 2+ или Motif (в Linux)), `Getopt::Long` (для интерфейса командной строки), `Archive::Zip`, `Encode::Locale` и `Encode::Recodenc` (см. `encxs/INSTALL` от корня проекта), а также скачайте этот проект. На странице с релизами есть windows-сборки. Если вы планируете использовать графический интерфейс в Linux, пропишите переменную окружения `$XDG_CONFIG_DIR` или создайте каталог `~/.config` для сохранения файла конфигурации.

Данный перекодировщик отличается от других тем, что содержит официальную реализацию кодировки CP1252CYR.

Далее рассказано о работе в графическом интерфейсе. О работе с интерфейсом командной строки читайте вывод `recodenc -h`.

### Указание каталога

Для указания скрипту каталога с исходными данными введите путь (без косой черты в конце) в текстовое поле самостоятельно или вызовите диалог выбора каталога кнопкой справа от текстового поля. Если вы не хотите изменять исходные файлы, отметьте галочкой пункт «Сохранить в» и укажите каталог для сохранения выходных данных. Каталоги, которые вы указываете, уже должны существовать. Исходный каталог и каталог сохранения должны быть разными (указание одного и того же каталога для чтения и записи просто испортит файлы). Каталог сохранения не очищается перед записью — файлы с именами, прочитанными из исходного каталога, будут перезаписаны в каталоге сохранения. Исходная файловая структура воспроизводится в выходном каталоге. Обратите внимание, что отдельные файлы не поддерживаются, как и вложенные каталоги.

Интерфейс выбора каталогов для EU4Lite и CK2Lite отличается, т. к. соответствующая функция производит сборку локализации для Lite-перевода, поэтому требуются два исходных каталога с разными локализациями и обязательный каталог сохранения.

Начаная с версии 0.6.1 BOM в начале исходного файла в кодировке UTF-8 не обязателен и не рекомендуется к установке.

<!--
СТАНДАРТНЫЕ ДЕЙСТВИЯ
СООБЩЕНИЯ ОБ ОШИБКАХ

Для перекодировки нажмите на кнопку с желаемым действием и дождитесь появления в строке состояния (слева от кнопки «Закрыть» внизу окна) надписи «Готово!» или сообщения об ошибке.

Если в строке состояния появилось сообщение об ошибке, значит не удаётся прочитать/записать в каталог, возможно, он не существует, или у вас нет парава на чтение/запись в него.
-->

### Вкладка «EU4»

Инструменты на вкладке «EU4» предназначены для манипуляций с локализацией (каталог `/localisation/`) EU4.

Формат входных файлов: кодировка UTF-8 с BOM, обрыв строки LF (в стиле \*nix). Формат выходных файлов такой же. Выбор файлов производится по расширению `*.yml`. Открывать закодированные файлы при помощи стандартного программного обеспечения не рекомендуется (особенно встроенным в windows Блокнотом).

* Кодировать (CP1251) — произвести промежуточное преобразование кодовых позиций символов кириллицы в кодировке UTF-8 из их расположения в этой кодировке к позициям символов, которые после прочтения движком соответственно станут на позиции символов кириллицы в кодировке CP1251.

* Кодировать (CP1252CYR) — произвести промежуточное преобразование кодовых позиций символов кириллицы в кодировке UTF-8 из их расположения в этой кодировке к позициям символов, которые после прочтения движком соответственно станут на позиции символов кириллицы в кодировке CP1252CYREU4.

* Транслитерировать — транслитерировать кириллицу и произвести промежуточное преобразование кодовых позиций символов кириллицы в кодировке UTF-8 из их расположения в этой кодировке к позициям символов, которые после прочтения движком соответственно станут на позиции транслитерированных символов кириллицы в кодировке CP1252.

* Декодировать (CP1251) — обратить промежуточное преобразование кодовых позиций символов кириллицы в кодировке UTF-8 из их расположения в этой кодировке к позициям символов, которые после прочтения движком соответственно станут на позиции символов кириллицы в кодировке CP1251. В большинстве случает работает как ожидается.

* Декодировать (CP1252CYR) — заменить промежуточное представление символов кириллицы из CP1252CYREU4 на символы кириллицы UTF-8, которым не поставлены в соответствие латинский буквы. Внимание! Функция декодировки из CP1252CYREU4 не восстанавливает текст, который был закодирован в эту кодировку. Если же текст был декодирован из CP1252CYREU4 и потом закодирован обратно, то исходный и повторно закодированный файлы бутут совпадать.

<!-- Сначала выберите кодировку. Если вы собираетесь декодировать файлы, то выбранная кодировка сообщает скрипту кодироку исходных данных, если же вы собираетесь кодировать файлы, скрипт таким образом узнает желаемую кодировку выходных данных. Обратите внимание, что декодировать можно только CP1251, т. к. только в этой кодировке из представленных латиница не пересекается с кириллицей, и, декодировав её, можно получить идентичные оригиналу файлы. Транслит предназначен для тех, кто хочет играть с переводом и одновременно использовать красивые латинские шрифты из модов или оригинальные шрифты из игры. -->

### Вкладка «EU4Lite»

Инструменты на вкладке «EU4» предназначены для манипуляций с локализацией (каталог `/localisation/`) EU4.

Формат входных файлов: кодировка UTF-8 с BOM, обрыв строки LF (в стиле \*nix). Формат выходных файлов такой же. Выбор файлов производится по расширению `*.yml`.

* CP1252CYR — получить Lite-перевод в кодировке CP1252CYREU4.

* CP1251 — получить Lite-перевод в кодировке CP1251.

* Транслитерировать — получить транслитерированную версию локализации.

* Только тэгы — вывести тэгы английской (подкаталог «en») и русской (подкаталог «ru») локализаций, которые можно затем сравнить, например, при помощи [WinMerge](http://winmerge.org/).

### Вкладка «EU4Dlc»

Вкладка «EU4Dlc» предназначена для извлечения из zip-архивов DLC локализации.

* Извлечь локализацию — извлечь файлы локализации.

#### Примечания

Возможность сохранить файлы локализации в каталог с архивами DLC не предоставлена, т. к. архивы DLC лежат в каталоге с игрой, а в грамотно настроенной системе запись в каталоги с программами запрещена.

### Вкладка «CK2»

Инструменты на вкладке «CK2» предназначены для манипуляций с локализацией (каталог `/localisation/`) CK2.

Формат файлов русской локализации: кодировка UTF-8 с BOM, обрыв строки LF (в стиле \*nix). Формат файлов закодированной локализации: кодировка CP1252, обрыв строки CRLF (в стиле dos). Выбор файлов производится по расширению `*.csv`.

* Кодировать (CP1251) — перекодировать в CP1251.

* Кодировать (CP1252CYR) — перекодировать в CP1252CYRCK2.

* Транслитерировать — транслитерировать кириллицу и перекодировать в CP1252.

* Декодировать (CP1251) — декодировать из CP1251.

* Декодировать (CP1252CYR) — декодировать из CP1252CYRCK2. Внимание! Функция декодировки из CP1252CYRCK2 не восстанавливает текст, который был закодирован в эту кодировку. Если же текст был декодирован из CP1252CYRCK2 и потом закодирован обратно, то исходный и повторно закодированный файлы бутут совпадать.

#### Примечания

При перекодировке учитываются только первые два поля, остальные отбрасываются. Также удаляются все пустые строки, строки-комментарии и строки без тэгов.

### Вкладка «CK2Lite»

Инструменты на вкладке «CK2» предназначены для манипуляций с локализацией (каталог `/localisation/`) CK2.

Формат входных файлов оригинальной локализации: кодировка CP1252, обрыв строки CRLF (в стиле dos). Формат входных файлов русской локализации: кодировка UTF-8 с BOM, обрыв строки LF (в стиле \*nix). Формат выходных файлов соответствует файлам оригинальной локализации. Выбор файлов производится по расширению `*.csv`.

* CP1252CYR — получить Lite-перевод в кодировке CP1252CYRCK2.

* CP1251 — получить Lite-перевод в кодировке CP1251.

* Транслитерировать — получить транслитерированную версию локализации.

* Только тэгы — вывести тэгы английской (подкаталог «en») и русской (подкаталог «ru») локализаций.

### Вкладка «Шрифт»

Инструменты на вкладке «Шрифт» предназначены для манипуляций со шрифтами для EU4 и CK2, а именно для замены в fnt-картах растрового шрифта в столбце «id» и секции кернингов номеров кодовых позиций юникода на номера из CP1252CYR и CP1251.

Формат входных файлов: кодировка ASCII, обрыв строки CRLF (в стиле dos). Формат выходных файлов такой же. Выбор файлов производится по расширениям `*.fnt`, `*.tga` и `*.dds`. Файлы `*_0.tga` и `*_0.dds` переименовываются/копируются в `*.tga` и `*.dds`.

* Очистить — удалить из fnt-файлов лишние данные.

* CP1252CYREU4 — удалить из fnt-файлов лишние данные и преобразовать коды символов к кодировке CP1252CYR для EU4.

* CP1252CYRCK2 — удалить из fnt-файлов лишние данные и преобразовать коды символов к кодировке CP1252CYR для CK2.

* CP1251 — удалить из fnt-файлов лишние данные и преобразовать коды символов к кодировке CP1251.

### Вкладка «Мод сохранения»

Инструменты на вкладке «Мод сохранения» предназначены для манипуляций локализацией мода, создаваемого CK2 DLC-экспортёром сохранения для EU4.

Формат входных файлов: кодировка UTF-8 с BOM, обрыв строки LF (в стиле \*nix). Формат выходных файлов такой же. Выбор файлов производится по расширению `*.yml`.

Для перекодировки нажмите на кнопку с желаемым действием. Перекодировку следует производить в рамках кодировки, мод-локализацию которой вы использовали в CK2 в соответствующую в EU4.

### Вкладка «Простой текст»

Инструменты на вкладке «Простой текст» предназначены для манипуляций с файлами простого текста.

Формат входных файлов: кодировка UTF-8 с BOM, обрыв строки в родном формате платформы. Формат выходных файлов: кодировка CP1252CYREU4, обрыв строки в родном формате платформы. Производится выбор всех файлов (не каталогов).

Код. (CP1252CYREU4) — перекодировать из UTF-8 в CP1252CYREU4.

Код. (CP1252CYRCK2) — перекодировать из UTF-8 в CP1252CYRCK2.

Код. (CP1251) — перекодировать из UTF8 в CP1251.

Транслитерировать — транслитерировать в рамках кодировки UTF-8.

Дек. (CP1252CYREU4) — перекодировать из CP1252CYREU4 в UTF-8.

Дек. (CP1252CYRCK2) — перекодировать из CP1252CYRCK2 в UTF-8.

Дек. (CP1251) — перекодировать из CP1251 в UTF-8.

<!-- 6. -->

## Файлы в проекте и их функции

`encxs` — каталог с дистрибутивом кодировок.

`COPYING` — лицензия, под которой доступны файлы проекта.

`NEWS` — изменения по версиям.

`README.md` — этот файл.

`recodenc.pl` — скрипт с интерфейсом командной строки.

`recodenc-gui.pl` — скрипт с графическим интерфейсом.

`Recodenc.pm` — модуль, в котором определены функции преобразования кодировок. Необходим для работы `recodenc` и `recodenc-gui`.

<!-- 7. -->

## Кодировки

Символы кодировки CP1252 (отображаемые EU4):

```
 !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ ¡¢¥¦¨©ª«¬®¯°±²³´µ¶·¸¹º»¼¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ
```

Символы кодировки CP1251 (отображаемые EU4; без ASCII):

```
Ђ‚ѓ„…†‡€‰Љ‹ЊЋЏ‘’“”•–—™љ›њћџ ЎўҐ¦Ё©Є«¬®Ї°±Ііґµ¶·ё№є»јѕїАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюя
```

Символы кодировки CP1252CYR (отображаемые EU4; без ASCII):

```
БГДЖЗИЙЛПŠУŒŽФЦЧШЩЪЫЬЭšЮœžŸб¡вгджзийклмнптуфцчшщъыьэю¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖЯØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõöяøùúûüýþÿ
```

<!-- в разделе №8 был несвободный текст -->

## Примеры текста

Текст примера:

```
Съешь же ещё этих мягких французских булок да выпей чаю.
```

CP1251 в промежуточном представлении в UTF8:

```
Ñúåøü æå åù¸ ýòèõ ìÿãêèõ ôðàíöóçñêèõ áóëîê äà âûïåé ÷àþ.
```

CP1252CYR в промежуточном представлении в UTF8:

```
C¹e·» ¨e e¸ë ¼²ªx ¯÷¥¬ªx ´pa°µ³©c¬ªx  ³®o¬ ¦a ¢º±e« ¶a¾.
```

Транслит:

```
S’exy je eçë êtih mägkih franquzskih bulok da vîpey caü.
```

<!-- 9. -->

## Связь с автором

Если у вас возникли проблемы, вопросы или предложения по поводу скрипта, ракладок клавиатуры и шрифтов, ссылки на которые приведены здесь, то пишите на адрес, указанный в лицензии, или на [Discord-сервер](https://discord.gg/uwvsCFZ).

<!-- 10. -->

## Лицензия

Copyright © 2016-2018 terqüéz

Этот текст доступен на условиях лицензии [CC BY-NC-ND 4.0 Международная](https://creativecommons.org/licenses/by-nc-nd/4.0/). Программный код скрипта доступен на условиях GPLv3 или (по вашему выбору) более поздней версии.

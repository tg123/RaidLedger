#!/bin/bash

#enUS
L="deDE
esES
esMX
frFR
itIT
koKR
ptBR
ruRU
zhCN
zhTW
"


function make_locale(){
	for i in $L ;do 
	echo "elseif locale == '$i' then"
	echo "--@localization(locale=\"$i\", format=\"lua_additive_table\", handle-unlocalized=\"comment\")@"
	done
}

function make_toc(){
	for i in $L ;do 
	echo "## Notes-$i: @localization(locale=\"$i\", key=\"TOC_NOTES\")@"
	echo "## Title-$i: @localization(locale=\"$i\", key=\"Title\")@"
	done
}

if [ "x$1" == "xloc" ];then
	make_locale
elif [ "x$1" == "xloc" ];then
	make_toc
else
	# import to wowace
	# 
	cat *.lua | grep "L\[\".*?\"]"  -Po | sed -e s/$/' = true'/g | sort -u
	echo 'L["TOC_NOTES"] = "A ledger for GDKP/gold run raid. Feedback: farmer1992@gmail.com"'
	echo 'L["TITLE"] = "Raid Ledger"'
fi

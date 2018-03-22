#!/bin/bash
#TODO sprawdza czy /boot jest zamontowane
#TODO kasowanie archiwow jak sie skonczy
#TODO unxz zwraca fausz jak plik istnieje
#TODO wywalenie post install do osobnego pliku
#TODO !!! ponieranie jako nie root !!!
#TODO opcjonalnie zamiast silentoldconfig dac olddefconfig zeby bral domyslne opcje bez pytania

src_location=/usr/src
kernel_timestamp="/var/lib/kernel_timestamp"

unset rebuild

while [[ $# -gt 0 ]]
do
    arg="$1"
    case "$arg" in
	-r|--rebuild)
	    rebuild=true
	    shift
	    ;;
	*)
	    echo "WTF $arg ???"
	    exit 1
	    ;;
    esac
done


#TODO zlikwiduj to spagetti

[[ ! $rebuild ]] && \
    {
	lastdl="$(curl 'https://www.kernel.org/releases.json' | jq '.latest_stable.version as $v | .releases | .[]  | if (.version == $v )  then . else empty end ')"
	[[ "" == "$lastdl" ]] && { echo 'failed to get realese informations, is your internet connection active?' ; exit 1; }
    }

#TODO zmienic to na cos bardziej kulturalnego? [[ sie nie sypie jak nie ma timestampa ale nie jest do porownywania liczb
if [[ "$(cat "$kernel_timestamp")" < "$(echo "$lastdl" | jq .released.timestamp)" || $rebuild ]];
then

     if [[ ! $rebuild ]]
     then
	 cd "$src_location" || { echo "ded on cd $src_location" ; exit 1; }
	 
	 filename="$(echo "$lastdl" | jq .source | xargs basename | sed 's/.tar.xz$//g')"

	 echo "$lastdl" | jq .source | xargs wget                       || { echo 'ded on wget src' ; exit 1; }
	 echo "$lastdl" | jq .pgp | xargs wget                          || { echo 'ded on wget sig' ; exit 1; }

	 unxz "$filename".tar.xz                                        || { echo 'ded on unxz' ; exit 1; }

	 gpg2 --verify "$filename".tar.sign                             || { echo '===FAILED=TO=VERIFY=SIGNATURE===' ; exit 1; }

	 tar -x -f "$filename".tar                                      || { echo 'ded on tar' ; exit 1; }

	 rm -f "$src_location/linux"                                    || { echo 'removing old link' ; exit 1; }
	 ln -vs "$src_location/$filename" "$src_location/linux"         || { echo 'ded on creating link' ; exit 1; }

	 echo "$lastdl" | jq .released.timestamp > "$kernel_timestamp"  || { echo 'failed to save timestamp' ; exit 1; }

	 cd "$src_location"/linux                                       || { echo 'ded on cd linux' ; exit 1; }

	 zcat /proc/config.gz > ./.config                       || { echo 'ded on zcat /proc/config.gz ,  this script use this file to get prevoius .config' ; exit 1; }

	 make silentoldconfig                                           || { echo 'ded on silentoldconfig' ; exit 1; }
     else
	 cd "$src_location"/linux                                       || { echo 'ded on cd linux' ; exit 1; }
     fi

     make                                                           || { echo 'ded on make' ; exit 1; }
     make modules                                                   || { echo 'ded on make modules' ; exit 1; }
     make install                                                   || { echo 'ded on make install' ; exit 1; }
     make modules_install                                           || { echo 'ded on make modules_install' ; exit 1; }

     #===================POST=INSTALL=======================#koniecznie src_location to musi byc /usr/src
     emerge --buildpkg r8168                                                || { echo 'ded on emerge r8168' ; exit 1; }
     #======================================================
     
     grub-mkconfig -o /boot/grub/grub.cfg                           || { echo 'ded on grub-mkconfig' ; exit 1; }
else
    echo "nothing new"
fi
echo 'ok'
exit 0

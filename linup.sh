#!/bin/bash

src_location=/usr/src
kernel_timestamp="/var/lib/kernel_timestamp"

while [[ $# -gt 0 ]]
do
    arg="$1"
    case "$arg" in
	-r|--rebuild)
	    rebuild=true
	    ;;
	--post-install)
	    shift
	    postinst="$1"
	    ;;
	*)
	    echo "what does $arg mean ???"
	    exit 1
	    ;;
	  esac
	  
    shift
done


#TODO zlikwiduj to spagetti

[[ ! $rebuild ]] && \
    {
	lastdl="$(curl 'https://www.kernel.org/releases.json' | jq '.latest_stable.version as $v | .releases | .[]  | if (.version == $v )  then . else empty end ')"
	[[ "" == "$lastdl" ]] && { echo 'failed to get release information, is your internet connection active?' ; exit 1; }
    }

if [[ "$(cat "$kernel_timestamp")" < "$(echo "$lastdl" | jq .released.timestamp)" || $rebuild ]];
then

     if [[ ! $rebuild ]]
     then
	 cd "$src_location" || { echo "failed on cd $src_location" ; exit 1; }
	 
	 filename="$(echo "$lastdl" | jq .source | xargs basename | sed 's/.tar.xz$//g')"

	 echo "$lastdl" | jq .source | xargs wget                       || { echo 'failed on wget src' ; exit 1; }
	 echo "$lastdl" | jq .pgp | xargs wget                          || { echo 'failed on wget sig' ; exit 1; }

	 unxz "$filename".tar.xz                                        || { echo 'failed on unxz' ; exit 1; }

	 gpg2 --verify "$filename".tar.sign                             || { echo '===FAILED=TO=VERIFY=SIGNATURE===' ; exit 1; }

	 tar -x -f "$filename".tar                                      || { echo 'failed on tar' ; exit 1; }

	 rm "$filename".tar
	 rm "$filename".tar.sign

	 rm -f "$src_location/linux"                                    || { echo 'failed to old link' ; exit 1; }
	 ln -vs "$src_location/$filename" "$src_location/linux"         || { echo 'failed on creating link' ; exit 1; }

	 echo "$lastdl" | jq .released.timestamp > "$kernel_timestamp"  || { echo 'failed to save timestamp' ; exit 1; }

	 cd "$src_location"/linux                                       || { echo 'failed on cd linux' ; exit 1; }

	 zcat /proc/config.gz > ./.config                 || { echo 'failed on zcat /proc/config.gz , this script use this file to get previous .config' ; exit 1; }

	 make silentoldconfig                                           || { echo 'failed on silentoldconfig' ; exit 1; }
     else
	 cd "$src_location"/linux                                       || { echo 'failed on cd linux' ; exit 1; }
     fi

     make                                                           || { echo 'failed on make' ; exit 1; }
     make modules                                                   || { echo 'failed on make modules' ; exit 1; }
     make install                                                   || { echo 'failed on make install' ; exit 1; }
     make modules_install                                           || { echo 'failed on make modules_install' ; exit 1; }

     if [[ $postinst ]] ; then
	 eval "$postinst"                                           || { echo 'postinstalation script failed' ; exit 1; }
     fi
     
     grub-mkconfig -o /boot/grub/grub.cfg                           || { echo 'failed on grub-mkconfig' ; exit 1; }
else
    echo "nothing new"
fi
echo 'ok'
exit 0

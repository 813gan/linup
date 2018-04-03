#!/bin/bash

src_location=/usr/src
version='stable'
kernel_timestamp="/var/lib/linup_timestamp"

function get_config
{
    zcat /proc/config.gz > "$src_location"/linux/.config || { echo 'failed on zcat /proc/config.gz ,  this script use this file to get previous .config' ; exit 1; }
}

function save_timestamp
{
    [[ -e "$kernel_timestamp" ]] || echo null > "$kernel_timestamp"
    tmp=`mktemp`
    ver_tst="$(echo "$release" | jq --arg ver "$version" '{($ver):(.released.timestamp)}')"
    jq --argjson data "$ver_tst" '(. + $data)' <"$kernel_timestamp" > $tmp || { echo 'failed to parse timestamp' ; exit 1; }
    rm "$kernel_timestamp"
    mv "$tmp" "$kernel_timestamp" || { echo 'failed to save timestamp' ; exit 1; }
}

function configure_kernel
{
    cd "$src_location"/linux                                       || { echo 'failed on cd linux' ; exit 1; }
    make silentoldconfig                                           || { echo 'failed on silentoldconfig' ; exit 1; }
}

function update_kernel
{
    json="$(wget -qO - 'https://www.kernel.org/releases.json')"
    [[ "" == "$json" ]] && { echo 'failed to get release information, is your internet connection active?' ; exit 1; }
    
    if [[ "$version" == 'stable' ]]
    then
	release="$(echo "$json" | jq '.latest_stable.version as $v | .releases | .[]  | if (.version == $v ) then . else empty end')"
    else
	release="$(echo "$json" | jq --arg ver "$version" '.releases | .[] | if (.version | test( "^"+$ver+".*";"" )) then . else empty end')"
    fi

    [[ "" == "$release" ]] && { echo "There is no release '$version'!" ; exit 1; }
    [[ `jq .iseol <<<"$release"` == 'true' ]] && { echo 'This is EOL release!' ; eol=true ; }

    if [[ "$(jq --arg ver "$version" '.[$ver]//0' <"$kernel_timestamp")" < "$(echo "$release" | jq .released.timestamp)" ]];
    then
	cd "$src_location" || { echo "failed on cd $src_location" ; exit 1; }

	filename="$(echo "$release" | jq .source | xargs basename | sed 's/.tar.xz$//g')"

	echo "$release" | jq .source | xargs wget                      || { echo 'failed on wget src' ; exit 1; }
	echo "$release" | jq .pgp | xargs wget                         || { echo 'failed on wget sig' ; exit 1; }

	unxz "$filename".tar.xz                                        || { echo 'failed on unxz' ; exit 1; }

	gpg2 --verify "$filename".tar.sign                             || { echo '===FAILED=TO=VERIFY=SIGNATURE===' ; exit 1; }

	tar -x -f "$filename".tar                                      || { echo 'failed on tar' ; exit 1; }

	rm "$filename".tar
	rm "$filename".tar.sign

	rm -f "$src_location/linux"                                    || { echo 'failed to old link' ; exit 1; }
	ln -vs "$src_location/$filename" "$src_location/linux"         || { echo 'failed on creating link' ; exit 1; }

	save_timestamp

	cd "$src_location"/linux                                       || { echo 'failed on cd linux' ; exit 1; }

	get_config

    else
	echo 'Kernel is up-to-date'
	exit 0
    fi
}

function make_kernel
{
    cd "$src_location"/linux                                       || { echo 'failed on cd linux' ; exit 1; }
    
    make                                                           || { echo 'failed on make' ; exit 1; }
    make modules                                                   || { echo 'failed on make modules' ; exit 1; }
}

function install_kernel
{
    cd "$src_location"/linux                                       || { echo 'failed on cd linux' ; exit 1; }
    
    make install                                                   || { echo 'failed on make install' ; exit 1; }
    make modules_install                                           || { echo 'failed on make modules_install' ; exit 1; }
}

function postinst
{
    return
}

function update_bootloader
{
    grub-mkconfig -o /boot/grub/grub.cfg                           || { echo 'failed on grub-mkconfig' ; exit 1; }
}


###

while [[ $# -gt 0 ]]
do
    arg="$1"
    case "$arg" in
	-r|--rebuild)
	    rebuild=true
	    ;;
	--config)
	    shift
	    config="$1"
	    ;;
	--version)
	    shift
	    opt_version="$1"
	    ;;
	*)
	    echo "what does $arg mean ???"
	    exit 1
	    ;;
    esac
	  
    shift
done

if [[ $config ]]
then
    . "$config"
else
    if [[ -f /etc/linup && -r /etc/linup ]]
    then
	. /etc/linup
    elif [[ -f /etc/local/linup && -r /etc/local/linup ]]
    then
	. /etc/local/linup
    fi
fi

if [[ "$opt_version" ]]
then
    version="$opt_version"
fi

if [[ ! $rebuild ]]
then
    update_kernel
fi

configure_kernel
make_kernel
install_kernel
postinst
update_bootloader

[[ $eol ]] && echo 'This is EOL release!'
echo 'ok'
exit 0

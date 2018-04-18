# linup
**This script will update your custom kernel.**

### Dependencies

- gcc 
- make
- \>=jq-1.5
- gpg && [Linux kernel release signing keys](https://www.kernel.org/category/signatures.html)
- GRUB-2
- Kernel compiled with `.config` support and access to `.config` through `/proc/config.gz` ( `CONFIG_IKCONFIG=y` and `CONFIG_IKCONFIG_PROC=y` ) 



### Usage

### Warning: Before running this script as root make sure that You are able to restore your previous kernel.  Messing up with kernel/bootloader always can make your system non-bootable. 

By default linup do following things:
- Check if your kernel is up-to-date, if it is, exit.
- Download the latest stable kernel, extract, check signatures and replace `.config` with your current configuration.
- Build and install kernel.
- Update bootloader, out of box linup works only with GRUB.

You can change this behaviour with command line arguments and configuration files described in section 'Advanced usage'.

**Linup accepts following command line arguments:**

- `-r` or `--rebuild`  
Do not check for new version, just build and install Linux sources pointed by symlink "$src_location/linux" (by default /usr/src/linux)
- `-dl` or `--download-only`  
Do not build or install anything, just download sources, update symlink (by default /usr/src/linux) and replace downloaded `.config` with your current configuration.
If your sources are up-to-date linup will exit without any changes.
- `--version`  
Select kernel version. You can find available versions at [kernel.org](https://www.kernel.org/category/releases.html)
- `--config`  
Set custom path to configuration file. By default linup try to use `/etc/linup` or `/etc/local/linup`

### Advanced usage

TODO

### Examples

If you have no configuration file and You just want to download and install last stable release simply use  
`# linup.sh`

You probably want stick to one of the long-term versions.
Use `--version` to select version. For example to download and install long-term maintance kernel v4.4 use  
`# linup.sh --version 4.4`

After every successful download linup will save timestamp and refuse to download and build kernel until new version appears. To rebuild kernel use  
`# linup.sh -r`

If You don't have custom kernel You want linup just to download selected version and then let You configure it.  
`# linup.sh -dl --version 4.4 && cd /usr/src/linux && make menuconfig`  
and then build and install  
`# linup.sh -r`

You may find [Gentoo handbook](https://wiki.gentoo.org/wiki/Handbook:X86/Installation/Kernel) and [wiki](https://wiki.gentoo.org/wiki/Main_Page) helpful while configuring kernel.

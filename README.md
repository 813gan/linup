# linup
**This script will update your custom kernel.**

### Dependencies

- gcc 
- make
- \>=jq-1.5
- gpg && [Linux kernel release signing keys](https://www.kernel.org/category/signatures.html)
- Kernel compiled with `.config` support and access to `.config` through `/proc/config.gz` ( `CONFIG_IKCONFIG=y` and `CONFIG_IKCONFIG_PROC=y`  ) 

### Usage

Linup accepts following command line arguments:

- `-r` or `--rebuild`  
Do not check for new version, just build and install Linux sources pointed by symlink "$src_location/linux" (by default /usr/src/linux)

- `-dl` or `--download-only`  
Do not build or install anything, just download sources, update symlink (by default /usr/src/linux) and replace downloaded `.config` with your current configuration.
If your sources are up-to-date linup will exit without any changes.

- `--version`  
Select kernel version. You can find available versions at [kernel.org](https://www.kernel.org/category/releases.html)

### Examples

If You just want to download and install last stable release simply use  
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

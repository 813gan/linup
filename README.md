# linup
**This script will update your custom kernel.**

### Dependencies

- gcc 
- make
- \>=jq-1.5
- gpg && [Linux kernel release signing keys](https://www.kernel.org/category/signatures.html)
- Kernel compiled with .config support and access to .config through /proc/config.gz ( `CONFIG_IKCONFIG=y` and `CONFIG_IKCONFIG_PROC=y`  ) 

### Usage

If You just want to download and install last stable release simply use
`# linup.sh`

You probably want stick to one of the long-term versions.
Use `--version` to select version. For example to download long-term maintance kernel v4.4 use
`# linup.sh --version 4.4`

After every successful download linup will save timestamp and refuse to download and build kernel until new version appears. To rebuld kernel use
`# linup.sh -r`

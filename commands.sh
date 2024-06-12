#!/bin/bash

suite="trixie"
arr_archs=( "all" "arm64" )
gpg_home="../gpg-xiaomi-vayu/private/gpg"

ASK() { echo; read -p "$*" answer; }

fn_mk_dirs() {
    mkdir -p pool/main
    mkdir -p dists/"${suite}"/main/binary-all
    mkdir -p dists/"${suite}"/main/binary-arm64
}

<< "RELEASE_FILE"
create dists/stable/Release
cat <<EOF > dists/stable/Release
Origin: My APT Repository
Label: My APT Repository
Suite: stable/sid
Codename: stable/sid
Architectures: amd64
Components: main
Description: My APT Repository
EOF
RELEASE_FILE

fn_apt_gpg_pub_download() {
## TODO: Get pubkey from repo
curl -s https://github.com/berbascum/my-apt-repo/raw/main/berb-apt.gpg | sudo gpg --dearmor -o /usr/share/keyrings/berb-apt.gpg
}
fn_apt_list_config() {
deb [arch=all signed-by=/usr/share/keyrings/vayu.gpg] https://droidian-vayu.github.io/apt-xiaomi-vayu "${suite}" main
}


fn_gpg_keys_show() {
    gpg --homedir ${gpg_home} --list-keys #--keyid-format SHORT
}
fn_gpg_keys_show_long() {
    gpg --homedir ${gpg_home} --list-keys --keyid-format long
}
fn_gpg_keys_show_short() {
    gpg --homedir ${gpg_home} --list-keys --keyid-format short
}

fn_scanpackages() {
    # First copy debs to pool/main
    for arch in ${arr_archs[@]}; do
	dpkg-scanpackages --multiversion pool/ \
	    > dists/"${suite}"/main/binary-"${arch}"/Packages
        cat dists/${suite}/main/binary-"${arch}"/Packages | gzip -9 \
	    > dists/${suite}/main/binary-"${arch}"/Packages.gz
	## Remove if exist
        [ -f "packages-"${arch}".db" ] && rm -f packages-"${arch}".db
    done
}

fn_gen_ftp_archive() {
        apt-ftparchive generate -c=aptftp.conf aptgenerate.conf
        apt-ftparchive release -c=aptftp.conf dists/${suite} >dists/${suite}/Release
}
fn_sign_all() {
    ## Sign
    gpg --homedir ${gpg_home} -abs -u "${KEY_LONG}" \
	-o dists/${suite}/Release.gpg dists/${suite}/Release
    ## Next shortest is showed at first ilne  with --list-keys --keyid-format long near 
    gpg --homedir ${gpg_home} --export "${KEY_SHORT}" > vayu.gpg
    gpg --homedir ${gpg_home} -u "${KEY_LONG}" \
	--clear-sign --output dists/"${suite}"/InRelease dists/"${suite}"/Release
}


#fn_gpg_keys_show
#fn_gpg_keys_show_long
#fn_gpg_keys_show_short

#fn_mk_dirs
#
ASK "Rescan and sign the repo? [ y|n ]: "
[ "${answer}" != "y" ] && exit
. ${gpg_home}/key-ids.sh
fn_scanpackages
fn_gen_ftp_archive
fn_sign_all

#fn_apt_list_config
#fn_apt_gpg_pub_download

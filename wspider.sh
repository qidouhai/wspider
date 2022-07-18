#!/bin/bash
# - iNFO -----------------------------------------------------------------------------
#
#        Author: wuseman <wuseman@nr1.nu>
#      FileName: wspider.sh
#       Version: 1.0
#
#       Created: 2022-07-03 (15:35:50)
#      Modified: 2022-07-13 (21:25:27)
#
#           iRC: wuseman (Libera/EFnet/LinkNet) 
#       Website: https://www.nr1.nu/
#        GitHub: https://github.com/wuseman/
#
# - Descrpiption --------------------------------------------------------------------
#
#      No description has been added
#
# - LiCENSE -------------------------------------------------------------------------
#
#      Copyright (C) 2021, wuseman                                     
#                                                                       
#      This program is free software; you can redistribute it and/or modify 
#      it under the terms of the GNU General Public License as published by 
#      the Free Software Foundation; either version 3 of the License, or    
#      (at your option) any later version.                                  
#                                                                       
#      This program is distributed in the hope that it will be useful,      
#      but WITHOUT ANY WARRANTY; without even the implied warranty of       
#      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        
#      GNU General Public License for more details.                         
#                                                                       
#      You must obey the GNU General Public License. If you will modify     
#      the file(s), you may extend this exception to your version           
#      of the file(s), but you are not obligated to do so.  If you do not   
#      wish to do so, delete this exception statement from your version.    
#      If you delete this exception statement from all source files in the  
#      program, then also delete it here.                                   
#
#      You should have received a copy of the GNU General Public License
#      along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# - End of Header -------------------------------------------------------------
VERSION=1.0

sSOURCE="https://crt.sh/?q"


#### Author of emagnet will be printed if --author or -a is being used
wspider_author() {
    cat << "EOF"

Copyright (C) 2022, wuseman

wspider was founded in 2022 and was released as open source
on github.com/wuseman/wspider in July 2022 and is licensed
under GNU LESSER GENERAL PUBLIC LICENSE GPLv3

  - Author  : wuseman <wuseman@nr1.nu>
  - IRC     : wuseman <chat.libera.chat>
  - Telegram: https://t.me/wuseman

 Please report bugs/issues on:

  - https://github.com/wuseman/wspider/issues

EOF
}

okMSG() {
    echo -e "[\e[1;32m*\e[0m] $*"
}

errMSG() {
    echo -e "[\e[1;31m*\e[0m] $*"
}


wspider_banner() {
    cat << "EOF"
                    (
                     )
                    (
              /\  .-"""-.  /\
             //\\/  ,,,  \//\\
             |/\| ,;;;;;, |/\|
             //\\\;-"""-;///\\      Author: wuseman
            //  \/   .   \/  \\     Script: wspider v1.0
           (| ,-_| \ | / |_-, |)
             //`__\.-.-./__`\\
            // /.-(() ())-.\ \\
           (\ |)   '---'   (| /)
            ` (|           |) `
             \)           (/

EOF
}

requirements() {
    hash wget2 &> /dev/null
    if [[ $? -ne "0" ]]; then 
        echo -e "$basename$0: internal error -- wget2 is required to be installed for this crawler..."; 
        exit 1
    fi
}

wspider_usage() {
cat << EOF

    Usage: $basename$0 -u <url> [options]

        -a      - Print author info 
        -h      - Print this useful help
        -i      - Print current IPv4 address
        -p      - Path where all other directories will be saved to
        -s      - Include subdomains, mirror all subdomains of host (will take long time)
        -t      - Specifies the download threads for a resource.  (Default: as many cores your cpu has)
        -u      - URL for our website to mirror 
        -v      - Print wspider verrsion
        -V      - Set verbose mode ON
        -U      - Use a random UserAgent

EOF
exit 0
}

randomized_userAgent() { 
if [[ $U = "1" ]]; then
    ua=$(curl -s https://raw.githubusercontent.com/wuseman/wspider/main/extra/userAgents.txt|sed '1,21d'|shuf -n1;shuf -e ${ua})
else
    ua=$userAGENT
fi
}

subdomains() {
curl -sL ${sSOURCE}=$u \
    |grep -i $u \
    |awk -F[\<\>] '{print $3}' \
    |awk '!seen[$0]++' \
    |sort \
    |grep $u|grep -v crt.sh > hosts.txt

seq 1 50|parallel -j50 -a hosts.txt 'ping -c 1 {} >/dev/null \
    && echo -e "{} \r ................................................. [....\e[1;32mup\e[0m]\rHost: https://{} " \
    || echo -e "{} \r ................................................. [....\e[1;31mdn\e[0m]\rHost: https://{} "' 2>/dev/null|awk 'length < 140' |tee status.txt

#printf '%59s\n' |tr ' ' '-'
#printf "\e[7m%-`tput cols`s\e[0m\n" "Found: $(cat hosts.txt|wc -l) subdomains for ${u}, $(cat mirror.txt|wc -l) will be mirrored"
#printf '%59s\n' |tr ' ' '-'
}

if [[ -z $1 ]];then wspider_usage;exit; fi


while getopts ":u:p:t:r:ahivVsUs" opt; do
    case $opt in
        a) 
            wspider_author
            exit 
            ;;
        h) 
            wspider_usage; 
            exit                 
            ;;
        i)
            echo -e "iPv4: $(curl -s https://www.nr1.nu/i/)" 
            exit 0
            ;;
        v) 
            echo -e "$basename$0: v$VERSION"; 
            exit 1
            ;;
        V)
            export V=1
            set -xv  # Set xtrace and verbose mode.
            ;;
        u)
            u=$OPTARG
            ;;
        p)
            p=$OPTARG
            ;;
        t)
            t=$OPTARG
            ;;
        s)
            s=1
            ;;
        U)
            U=1
            ;;
        # *)
            #   echo "invalid command: no parameter included with argument $OPTARG"
            #  ;;
        esac
    done

    if  [[ -z "${u}" ]]; then 
        echo -e "$basename$0: internal error -- url is missing";
        exit 1;
    fi

    if [[ -z "${p}" ]]; then 
        echo -e "$basename$0: internal error -- you must include a path to store downloaded content in";
        exit 1;
    fi


if [[ -z ${t} ]]; then t=$(grep  -c ^processor /proc/cpuinfo);else t=${t};fi
wspider_banner
randomized_userAgent
i="$(curl -sL ifconfig.co)"
printf "\e[7m%-`tput cols`s\e[0m\n" "wspider v1.0"
if [[ $s -ne "1" ]]; then
echo -e "............................: ${u}\rWebsite"
echo -e "............................: ${p}\rPath "
echo -e "............................: ${i}\rIPv4: "
echo -e "............................: \e[1;31mOFF\e[0m\rSubdomains: "
echo -e "............................: ${ua}\rUserAgent: "
echo -e "............................: ${t} of $(xargs --show-limits -s 1 2>&1|grep -i "parallelism"|awk '{print $8}')\rDownload Threads: "
printf "\e[7m%-`tput cols`s\e[0m\n" "Press Enter To Continue"
read;echo -e "\nMirroring: ${u}..."
wget2 --max-threads ${t} \
    --user-agent "${ua}" \
    --mirror \
    --recursive \
    --level inf \
    --progress=bar \
    --base=${u} \
    --force-html \
    --force-css \
    --force-sitemap \
    --force-atom \
    --force-rss \
    --force-metalink \
    --max-redirect=${t} \
    --convert-links \
    --robots=off \
    -i mirror.txt \
    -P ${p} ${u}
else
echo -e ".................................................: ${u}\rWebsite"
echo -e ".................................................: ${p}\rPath "
echo -e ".................................................: ${i}\rIPv4: "
echo -e ".................................................: \e[1;32mON\e[0m\rSubdomains: "
echo -e ".................................................: ${ua}\rUserAgent: "
echo -e ".................................................: ${t} of $(xargs --show-limits -s 1 2>&1|grep -i "parallelism"|awk '{print $8}')\rDownload Threads: "
printf "\e[7m%-`tput cols`s\e[0m\n" "Press Enter To Continue"
read 
subdomains
cat status.txt|grep "up"|grep -Eo "(http|https)://[a-zA-Z0-9./?=_-].*"> mirror.txt
wget2 --max-threads ${t} \
      --user-agent "${ua}" \
      --mirror \
      --recursive \
      --level inf \
      --progress=bar \
      --robots=off \
       -i mirror.txt 
fi
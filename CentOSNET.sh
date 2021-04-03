#!/bin/bash

export tmpVER=''
export tmpDIST=''
export tmpWORD=''
export tmpMirror=''
export tmpINS=''
export ipAddr=''
export ipMask=''
export ipGate=''
export linuxdists=''
export setNet='0'
export isMirror='0'
export UNKNOWHW='0'
export UNVER='6.4'

while [[ $# -ge 1 ]]; do
  case $1 in
    -v|--ver)
      shift
      tmpVER="$1"
      shift
      ;;
    -c|--centos)
      shift
      linuxdists='centos'
      tmpDIST="$1"
      shift
      ;;
    -p|--password)
      shift
      tmpWORD="$1"
      shift
      ;;
    --ip-addr)
      shift
      ipAddr="$1"
      shift
      ;;
    --ip-mask)
      shift
      ipMask="$1"
      shift
      ;;
    --ip-gate)
      shift
      ipGate="$1"
      shift
      ;;
    -a|--auto)
      shift
      tmpINS='auto'
      ;;
    -m|--manual)
      shift
      tmpINS='manual'
      ;;
    -yum|--mirror)
      shift
      isMirror='1'
      tmpMirror="$1"
      shift
      ;;
    *)
      echo -ne " Usage:\n\tbash DebianNET.sh\t-c/--centos [\033[33m\033[04mdists-verison\033[0m]\n\t\t\t\t-v/--ver [32/\033[33m\033[04mi386\033[0m|64/amd64]\n\t\t\t\t--ip-addr/--ip-gate/--ip-mask\n\t\t\t\t-apt/--mirror\n\t\t\t\t-dd/--image\n\t\t\t\t-a/--auto\n\t\t\t\t-m/--manual\n"
      exit 1;
      ;;
    esac
  done

[[ "$EUID" -ne '0' ]] && echo "Error:This script must be run as root!" && exit 1;

function CheckDependence(){
FullDependence='0';
for BIN_DEP in `echo "$1" |sed 's/,/\n/g'`
  do
    if [[ -n "$BIN_DEP" ]]; then
      Founded='0';
      for BIN_PATH in `echo "$PATH" |sed 's/:/\n/g'`
        do
          ls $BIN_PATH/$BIN_DEP >/dev/null 2>&1;
          if [ $? == '0' ]; then
            Founded='1';
            break;
          fi
        done
      if [ "$Founded" == '1' ]; then
        echo -en "$BIN_DEP\t\t[\033[32mok\033[0m]\n";
      else
        FullDependence='1';
        echo -en "$BIN_DEP\t\t[\033[31mfail\033[0m]\n";
      fi
    fi
  done
if [ "$FullDependence" == '1' ]; then
  exit 1;
fi
}

clear && echo -e "\n\033[36m# Check Dependence\033[0m\n"
CheckDependence wget,awk,xz,openssl,grep,dirname,file,cut,cat,cpio,gzip

[[ -f '/boot/grub/grub.cfg' ]] && GRUBOLD='0' && GRUBDIR='/boot/grub' && GRUBFILE='grub.cfg';
[[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub2/grub.cfg' ]] && GRUBOLD='0' && GRUBDIR='/boot/grub2' && GRUBFILE='grub.cfg';
[[ -z "$GRUBDIR" ]] && [[ -f '/boot/grub/grub.conf' ]] && GRUBOLD='1' && GRUBDIR='/boot/grub' && GRUBFILE='grub.conf';
[ -z "$GRUBDIR" -o -z "$GRUBFILE" ] && echo -ne "Error! \nNot Found grub path.\n" && exit 1;

[[ -n "$tmpVER" ]] && {
  [ "$tmpVER" == '32' -o "$tmpVER" == 'i386' ] && VER='i386';
  [ "$tmpVER" == '64' -o "$tmpVER" == 'amd64' ] && VER='x86_64';
}
[[ -z "$VER" ]] && VER='i386';

[[ -z "$linuxdists" ]] && linuxdists='centos';

[[ "$isMirror" == '1' ]] && [[ -n "$tmpMirror" ]] && {
  echo "$tmpMirror" |grep -q '^http://';
  [[ $? == '0' ]] && {
    TMPMirror="$(echo "$tmpMirror" |awk -F'://' '{print $2}')";
  } || {
    echo -en "\n\033[31mInvaild Mirror! \033[0m\n\033[33mexample:\033[0m http://archive.kernel.org/centos-vault\n\n";
    exit 1
  }
  [[ -n "$TMPMirror" ]] && {
    echo "$TMPMirror" |grep -q '/$';
    [[ $? == '0' ]] && {
      CentOSMirror="$(dirname "$TMPMirror.centos")";
    } || {
      CentOSMirror="$TMPMirror";
    }
  } || {
    bash $0 error;
    exit 1
  }
} || {
  CentOSMirror='vault.centos.org';
}

[[ -z "$tmpDIST" ]] && {
  [[ "$linuxdists" == 'centos' ]] && tmpDIST='6.4';
}

[[ -z "$DIST" ]] && {
  DISTCheck="$(echo "$tmpDIST" |grep -o '[.0-9]\{1,\}')";
  ListDIST="$(wget --no-check-certificate -qO- "http://$CentOSMirror/dir_sizes" |cut -f2 |grep '^[0-9]')"
  DIST="$(echo "$ListDIST" |grep "^$DISTCheck")"
  [[ -z "$DIST" ]] && {
    echo -ne '\nThe dists version not found, Please check it! \n\n'
    bash $0 error;
    exit 1;
  }
  wget --no-check-certificate -qO- "http://$CentOSMirror/$DIST/os/$VER/.treeinfo" |grep -q 'general';
  [[ $? != '0' ]] && {
    echo -ne "\nThe version not found in this mirror, Please change mirror try again! \n\n";
    exit 1;
  }
}

[[ -n "$tmpINS" ]] && {
  [[ "$tmpINS" == 'auto' ]] && inVNC='n';
  [[ "$tmpINS" == 'manual' ]] && inVNC='y';
}

[ -n "$ipAddr" ] && [ -n "$ipMask" ] && [ -n "$ipGate" ] && setNet='1';
[[ -n "$tmpWORD" ]] && myPASSWORD="$(openssl passwd -1 "$tmpWORD")";
[[ -z "$myPASSWORD" ]] && myPASSWORD='$1$0shYGfBd$8v189JOozDO1jPqPO645e1';
[[ -z "$INCFW" ]] && INCFW='0';

clear && echo -e "\n\033[36m# Install\033[0m\n"

ASKVNC(){
  inVNC='y';
  [[ "$ddMode" == '0' ]] && {
    echo -ne "\033[34mCan you login VNC?\033[0m\e[33m[\e[32my\e[33m/n]\e[0m "
    read tmpinVNC
    [[ -n "$inVNCtmp" ]] && inVNC="$tmpinVNC"
  }
  [ "$inVNC" == 'y' -o "$inVNC" == 'Y' ] && inVNC='y';
  [ "$inVNC" == 'n' -o "$inVNC" == 'N' ] && inVNC='n';
}

[ "$inVNC" == 'y' -o "$inVNC" == 'n' ] || ASKVNC;
[[ "$linuxdists" == 'centos' ]] && LinuxName='CentOS';
[[ "$inVNC" == 'y' ]] && VNC_WARN='1' && echo -e "\033[34mManual Mode\033[0m insatll \033[33m$LinuxName\033[0m [\033[33m$DIST\033[0m] [\033[33m$VER\033[0m] in VNC. "
[[ "$inVNC" == 'n' ]] && VNC_WARN='0' && echo -e "\033[34mAuto Mode\033[0m insatll \033[33m$LinuxName\033[0m [\033[33m$DIST\033[0m] [\033[33m$VER\033[0m]. "

if [[ "$DIST" != "$UNVER" ]]; then
  awk 'BEGIN{print '${UNVER}'-'${DIST}'}' |grep -q '^-'
  if [ $? != '0' ]; then
    UNKNOWHW='1';
    echo -en "\033[33mThe version lower then \033[31m$UNVER\033[33m may not support in auto mode! \033[0m\n";
    if [[ "$inVNC" == 'n' ]]; then
      echo -en "\033[35mYou can connect VNC with \033[32mPublic IP\033[35m and port \033[32m1\033[35m/\033[32m5901\033[35m in vnc viewer.\033[0m\n"
      read -n 1 -p "Press Enter to continue..." INP
      [[ "$INP" != '' ]] && echo -ne '\b \n\n';
    fi
  fi
  awk 'BEGIN{print '${UNVER}'-'${DIST}'+0.59}' |grep -q '^-'
  if [ $? == '0' ]; then
    echo -en "\n\033[31mThe version higher then \033[33m6.9 \033[31mis not support in current! \033[0m\n\n"
    exit 1;
  fi
fi

echo -e "\n[\033[33m$LinuxName\033[0m] [\033[33m$DIST\033[0m] [\033[33m$VER\033[0m] Downloading..."
[[ -z "$CentOSMirror" ]] && echo -ne "\033[31mError! \033[0mGet debian mirror fail! \n" && exit 1
wget --no-check-certificate -qO '/boot/initrd.img' "http://$CentOSMirror/$DIST/os/$VER/isolinux/initrd.img"
[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'initrd.img' failed! \n" && exit 1
wget --no-check-certificate -qO '/boot/vmlinuz' "http://$CentOSMirror/$DIST/os/$VER/isolinux/vmlinuz"
[[ $? -ne '0' ]] && echo -ne "\033[31mError! \033[0mDownload 'vmlinux' failed! \n" && exit 1

[[ "$setNet" == '1' ]] && {
  IPv4="$ipAddr";
  MASK="$ipMask";
  GATE="$ipGate";
} || {
  DEFAULTNET="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.*' |head -n1 |sed 's/proto.*\|onlink.*//g' |awk '{print $NF}')";
  [[ -n "$DEFAULTNET" ]] && IPSUB="$(ip addr |grep ''${DEFAULTNET}'' |grep 'global' |grep 'brd' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}/[0-9]\{1,2\}')";
  IPv4="$(echo -n "$IPSUB" |cut -d'/' -f1)";
  NETSUB="$(echo -n "$IPSUB" |grep -o '/[0-9]\{1,2\}')";
  GATE="$(ip route show |grep -o 'default via [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}')";
  [[ -n "$NETSUB" ]] && MASK="$(echo -n '128.0.0.0/1,192.0.0.0/2,224.0.0.0/3,240.0.0.0/4,248.0.0.0/5,252.0.0.0/6,254.0.0.0/7,255.0.0.0/8,255.128.0.0/9,255.192.0.0/10,255.224.0.0/11,255.240.0.0/12,255.248.0.0/13,255.252.0.0/14,255.254.0.0/15,255.255.0.0/16,255.255.128.0/17,255.255.192.0/18,255.255.224.0/19,255.255.240.0/20,255.255.248.0/21,255.255.252.0/22,255.255.254.0/23,255.255.255.0/24,255.255.255.128/25,255.255.255.192/26,255.255.255.224/27,255.255.255.240/28,255.255.255.248/29,255.255.255.252/30,255.255.255.254/31,255.255.255.255/32' |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'${NETSUB}'' |cut -d'/' -f1)";
}

[[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPv4" ]] || {
echo "Not found \`ip command\`, It will use \`route command\`."
ipNum() {
  local IFS='.';
  read ip1 ip2 ip3 ip4 <<<"$1";
  echo $((ip1*(1<<24)+ip2*(1<<16)+ip3*(1<<8)+ip4));
}

SelectMax(){
ii=0;
for IPITEM in `route -n |awk -v OUT=$1 '{print $OUT}' |grep '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'`
  do
    NumTMP="$(ipNum $IPITEM)";
    eval "arrayNum[$ii]='$NumTMP,$IPITEM'";
    ii=$[$ii+1];
  done
echo ${arrayNum[@]} |sed 's/\s/\n/g' |sort -n -k 1 -t ',' |tail -n1 |cut -d',' -f2;
}

[[ -z $IPv4 ]] && IPv4="$(ifconfig |grep 'Bcast' |head -n1 |grep -o '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' |head -n1)";
[[ -z $GATE ]] && GATE="$(SelectMax 2)";
[[ -z $MASK ]] && MASK="$(SelectMax 3)";

[[ -n "$GATE" ]] && [[ -n "$MASK" ]] && [[ -n "$IPv4" ]] || {
  echo "Error! Not configure network. ";
  exit 1;
}
}

[[ "$setNet" != '1' ]] && [[ -f '/etc/network/interfaces' ]] && {
  [[ -z "$(sed -n '/iface.*inet static/p' /etc/network/interfaces)" ]] && AutoNet='1' || AutoNet='0';
  [[ -d /etc/network/interfaces.d ]] && {
    ICFGN="$(find /etc/network/interfaces.d -name '*.cfg' |wc -l)" || ICFGN='0';
    [[ "$ICFGN" -ne '0' ]] && {
      for NetCFG in `ls -1 /etc/network/interfaces.d/*.cfg`
        do 
          [[ -z "$(cat $NetCFG | sed -n '/iface.*inet static/p')" ]] && AutoNet='1' || AutoNet='0';
          [[ "$AutoNet" -eq '0' ]] && break;
        done
    }
  }
}

[[ "$setNet" != '1' ]] && [[ -d '/etc/sysconfig/network-scripts' ]] && {
  ICFGN="$(find /etc/sysconfig/network-scripts -name 'ifcfg-*' |grep -v 'lo'|wc -l)" || ICFGN='0';
  [[ "$ICFGN" -ne '0' ]] && {
    for NetCFG in `ls -1 /etc/sysconfig/network-scripts/ifcfg-* |grep -v 'lo$' |grep -v ':[0-9]\{1,\}'`
      do 
        [[ -n "$(cat $NetCFG | sed -n '/BOOTPROTO.*[dD][hH][cC][pP]/p')" ]] && AutoNet='1' || {
          AutoNet='0' && . $NetCFG;
          [[ -n $NETMASK ]] && MASK="$NETMASK";
          [[ -n $GATEWAY ]] && GATE="$GATEWAY";
        }
        [[ "$AutoNet" -eq '0' ]] && break;
      done
  }
}

[[ ! -f $GRUBDIR/$GRUBFILE ]] && echo "Error! Not Found $GRUBFILE. " && exit 1;

[[ ! -f $GRUBDIR/$GRUBFILE.old ]] && [[ -f $GRUBDIR/$GRUBFILE.bak ]] && mv -f $GRUBDIR/$GRUBFILE.bak $GRUBDIR/$GRUBFILE.old;
mv -f $GRUBDIR/$GRUBFILE $GRUBDIR/$GRUBFILE.bak;
[[ -f $GRUBDIR/$GRUBFILE.old ]] && cat $GRUBDIR/$GRUBFILE.old >$GRUBDIR/$GRUBFILE || cat $GRUBDIR/$GRUBFILE.bak >$GRUBDIR/$GRUBFILE;

[[ "$GRUBOLD" == '0' ]] && {
  READGRUB='/tmp/grub.read'
  cat $GRUBDIR/$GRUBFILE |sed -n '1h;1!H;$g;s/\n/+++/g;$p' |grep -oPm 1 'menuentry\ .*\{.*\}\+\+\+' |sed 's/\+\+\+/\n/g' >$READGRUB
  LoadNum="$(cat $READGRUB |grep -c 'menuentry ')"
  if [[ "$LoadNum" -eq '1' ]]; then
    cat $READGRUB |sed '/^$/d' >/tmp/grub.new;
  elif [[ "$LoadNum" -gt '1' ]]; then
    CFG0="$(awk '/menuentry /{print NR}' $READGRUB|head -n 1)";
    CFG2="$(awk '/menuentry /{print NR}' $READGRUB|head -n 2 |tail -n 1)";
    CFG1="";
    for tmpCFG in `awk '/}/{print NR}' $READGRUB`
      do
        [ "$tmpCFG" -gt "$CFG0" -a "$tmpCFG" -lt "$CFG2" ] && CFG1="$tmpCFG";
      done
    [[ -z "$CFG1" ]] && {
      echo "Error! read $GRUBFILE. ";
      exit 1;
    }

    sed -n "$CFG0,$CFG1"p $READGRUB >/tmp/grub.new;
    [[ -f /tmp/grub.new ]] && [[ "$(grep -c '{' /tmp/grub.new)" -eq "$(grep -c '}' /tmp/grub.new)" ]] || {
      echo -ne "\033[31mError! \033[0mNot configure $GRUBFILE. \n";
      exit 1;
    }
  fi
  [ ! -f /tmp/grub.new ] && echo "Error! $GRUBFILE. " && exit 1;
  sed -i "/menuentry.*/c\menuentry\ \'Install OS \[$DIST\ $VER\]\'\ --class debian\ --class\ gnu-linux\ --class\ gnu\ --class\ os\ \{" /tmp/grub.new
  sed -i "/echo.*Loading/d" /tmp/grub.new;
  INSERTGRUB="$(awk '/menuentry /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
}

[[ "$GRUBOLD" == '1' ]] && {
  CFG0="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)";
  CFG1="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE|head -n 2 |tail -n 1)";
  [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 == $CFG0 ] && sed -n "$CFG0,$"p $GRUBDIR/$GRUBFILE >/tmp/grub.new;
  [[ -n $CFG0 ]] && [ -z $CFG1 -o $CFG1 != $CFG0 ] && sed -n "$CFG0,$CFG1"p $GRUBDIR/$GRUBFILE >/tmp/grub.new;
  [[ ! -f /tmp/grub.new ]] && echo "Error! configure append $GRUBFILE. " && exit 1;
  sed -i "/title.*/c\title\ \'Install OS \[$DIST\ $VER\]\'" /tmp/grub.new;
  sed -i '/^#/d' /tmp/grub.new;
  INSERTGRUB="$(awk '/title /{print NR}' $GRUBDIR/$GRUBFILE|head -n 1)"
}

[[ -n "$(grep 'linux.*/\|kernel.*/' /tmp/grub.new |awk '{print $2}' |tail -n 1 |grep '^/boot/')" ]] && Type='InBoot' || Type='NoBoot';

LinuxKernel="$(grep 'linux.*/\|kernel.*/' /tmp/grub.new |awk '{print $1}' |head -n 1)";
[[ -z "$LinuxKernel" ]] && echo "Error! read grub config! " && exit 1;
LinuxIMG="$(grep 'initrd.*/' /tmp/grub.new |awk '{print $1}' |tail -n 1)";
[ -z "$LinuxIMG" ] && sed -i "/$LinuxKernel.*\//a\\\tinitrd\ \/" /tmp/grub.new && LinuxIMG='initrd';

[[ "$Type" == 'InBoot' ]] && {
  sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/boot\/vmlinuz ks=file:\/\/ks.cfg ksdevice=link" /tmp/grub.new;
  sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/boot\/initrd.img" /tmp/grub.new;
}

[[ "$Type" == 'NoBoot' ]] && {
  sed -i "/$LinuxKernel.*\//c\\\t$LinuxKernel\\t\/vmlinuz ks=file:\/\/ks.cfg ksdevice=link" /tmp/grub.new;
  sed -i "/$LinuxIMG.*\//c\\\t$LinuxIMG\\t\/initrd.img" /tmp/grub.new;
}

sed -i '$a\\n' /tmp/grub.new;

[[ "$inVNC" == 'n' ]] && {
GRUBPATCH='0';

[ -f '/etc/network/interfaces' -o -d '/etc/sysconfig/network-scripts' ] || {
  echo "Error, Not found interfaces config.";
  exit 1;
}

sed -i ''${INSERTGRUB}'i\\n' $GRUBDIR/$GRUBFILE;
sed -i ''${INSERTGRUB}'r /tmp/grub.new' $GRUBDIR/$GRUBFILE;
[[ -f  $GRUBDIR/grubenv ]] && sed -i 's/saved_entry/#saved_entry/g' $GRUBDIR/grubenv;

[[ -d /boot/tmp ]] && rm -rf /boot/tmp;
mkdir -p /boot/tmp;
cd /boot/tmp;
COMPTYPE="$(file /boot/initrd.img |grep -o ':.*compressed data' |cut -d' ' -f2 |sed -r 's/(.*)/\L\1/' |head -n1)"
[[ -z "$COMPTYPE" ]] && echo "Detect compressed type fail." && exit 1;
CompDected='0'
for ListCOMP in `echo -en 'lzma\nxz\ngzip'`
  do
    if [[ "$COMPTYPE" == "$ListCOMP" ]]; then
      CompDected='1'
      if [[ "$COMPTYPE" == 'gzip' ]]; then
        NewIMG="initrd.img.gz"
      else
        NewIMG="initrd.img.$COMPTYPE"
      fi
      mv -f "/boot/initrd.img" "/boot/$NewIMG"
      break;
    fi
  done
[[ "$CompDected" != '1' ]] && echo "Detect compressed type not support." && exit 1;
[[ "$COMPTYPE" == 'lzma' ]] && UNCOMP='xz --format=lzma --decompress';
[[ "$COMPTYPE" == 'xz' ]] && UNCOMP='xz --decompress';
[[ "$COMPTYPE" == 'gzip' ]] && UNCOMP='gzip -d';

$UNCOMP < ../$NewIMG | cpio --extract --verbose --make-directories --no-absolute-filenames >>/dev/null 2>&1
cat >/boot/tmp/ks.cfg<<EOF
#platform=x86, AMD64, or Intel EM64T
# Firewall configuration
firewall --enabled --ssh
# Install OS instead of upgrade
install
# Use network installation
url --url="http://$CentOSMirror/$DIST/os/$VER/"
# Root password
rootpw --iscrypted $myPASSWORD
# System authorization information
auth --useshadow --passalgo=sha512
firstboot --disable
# System language
lang en_US
# System keyboard
keyboard us
# SELinux configuration
selinux --disabled
# Installation logging level
logging --level=info
# Reboot after installation
reboot
# Perform installation mode
text
# Ingore Unsupported Hardware Detected alert
unsupported_hardware
# VNC support
vnc
# Do not install a graphical environment
skipx
# System timezone
timezone --isUtc Asia/Hong_Kong
# Network information
#ONDHCP network --bootproto=dhcp --onboot=on
#NODHCP network --bootproto=static --ip=$IPv4 --netmask=$MASK --gateway=$GATE --nameserver=8.8.8.8 --onboot=on
# System bootloader configuration
bootloader --location=mbr --append="rhgb quiet crashkernel=auto"
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel 
# Disk partitioning information
autopart

%packages
@base
%end

%post --interpreter=/bin/bash
rm -rf /root/anaconda-ks.cfg
rm -rf /root/install.*log
%end

EOF
[[ "$setNet" == '0' ]] && [[ "$AutoNet" == '1' ]] && {
  sed -i 's/#ONDHCP\ //g' /boot/tmp/ks.cfg
} || {
  sed -i 's/#NODHCP\ //g' /boot/tmp/ks.cfg
}
[[ "$UNKNOWHW" == '1' ]] && sed -i 's/^unsupported_hardware/#unsupported_hardware/g' /boot/tmp/ks.cfg
[[ "$(echo "$DIST" |grep -o '^[0-9]\{1\}')" == '5' ]] && sed -i '0,/^%end/s//#%end/' /boot/tmp/ks.cfg
rm -rf ../$NewIMG;
find . | cpio -H newc --create --verbose | gzip -9 > ../initrd.img;
rm -rf /boot/tmp;
}

[[ "$inVNC" == 'y' ]] && {
  sed -i '$i\\n' $GRUBDIR/$GRUBFILE
  sed -i '$r /tmp/grub.new' $GRUBDIR/$GRUBFILE
  echo -e "\n\033[33m\033[04mIt will reboot! \nPlease look at VNC! \nSelect\033[0m\033[32m Install OS [$DIST $VER] \033[33m\033[4mto install system.\033[04m\n\n\033[31m\033[04mThere is some information for you.\nDO NOT CLOSE THE WINDOW! \033[0m\n"
  echo -e "\033[35mIPv4\t\tNETMASK\t\tGATEWAY\033[0m"
  echo -e "\033[36m\033[04m$IPv4\033[0m\t\033[36m\033[04m$MASK\033[0m\t\033[36m\033[04m$GATE\033[0m\n\n"

  read -n 1 -p "Press Enter to reboot..." INP
  [[ "$INP" != '' ]] && echo -ne '\b \n\n';
}

chown root:root $GRUBDIR/$GRUBFILE
chmod 444 $GRUBDIR/$GRUBFILE

sleep 3 && reboot >/dev/null 2>&1


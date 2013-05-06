#!/bin/bash
# This script is for generating a role structure in LDAP for use with 
# apache tomcat.
#
# For information on how to configure tomcat to use this structure, 
# please refer to the following document.
# http://tomcat.apache.org/tomcat-7.0-doc/realm-howto.html#JNDIRealm
#


roles=()
function getRoles()
{
  if [ "$1" == "" ]; then
    return 1;
  fi;

  IFS=',' read -r -a roles <<<"$1"
}

function showhelp()
{
  printf "$0 -b|--basedn -r|--roles \n"
  printf "\t $0 -b dc=example,dc=com -r tomcat,manager-gui,manager-script,admin-gui \\ \n"
  echo ${roles[@]}
}

# get the options and evaluate them
OPTS=`getopt -o b:v:r:hd -l basedn:roles:,vhostname:,help,debug -- "$@"`
eval set -- "$OPTS"
while true ; do
  case "$1" in
    -b|--basedn) basedn="$2" ; shift 2 ;;
    -r|--roles) getRoles $2 ; shift 2 ;;
    -v|--vhostname) vhname="$2" ; shift 2 ;;
    -\?|--help)
      showhelp;
      exit 0;
      shift 1;;
    -d|--debug) DEBUG=true ; shift 1;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done;

if [[ ${#roles[@]} -eq 0 || "$vhname" == "" || "$basedn" == "" ]]; then
  showhelp;
  exit 1;
fi

tomcatldif="
dn: ou=tomcat,$basedn
objectClass: organizationalUnit
ou: tomcat

dn: ou=$vhname,ou=tomcat,$basedn
objectClass: organizationalUnit
ou: $vhname

dn: uid=manager,ou=$vhname,ou=tomcat,$basedn
objectClass: inetOrgPerson
uid: manager
sn: Account
cn: Manager Account
userPassword: {MD5}$(uuidgen | md5sum)

dn: ou=groups,ou=$vhname,ou=tomcat,$basedn
objectClass: organizationalUnit
ou: groups
"
for role in "${roles[@]}"; do 
  tomcatldif+="
dn: cn=$role,ou=groups,ou=$vhname,ou=tomcat,$basedn
objectClass: groupOfUniqueNames
cn: $role
uniqueMember: uid=manager,ou=$vhname,ou=tomcat,$basedn
"
done;

echo "$tomcatldif"

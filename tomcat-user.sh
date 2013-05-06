#!/bin/bash
# This script is for generating a user based on the structure in LDAP 
# created by tomcat-roler.sh for use with apache tomcat.
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
  printf "$0 -b|--basedn ou=blah,...,dc=example,dc=com"
  printf " -r|--roles tomcat[,manager-gui,etc,...]\n"
  printf "\t-b|--basedn    the base dn path for your ldap entry. \n"
  printf "\t-r|--roles     the comma separated tomcat roles available for \n"
  printf "\t               that domain.\n"
  printf "e.g. $0 -b ou=customer-domain,ou=tomcat,dc=example,dc=com -r tomcat,manager-gui,manager-script,admin-gui \\ \n"
  echo ${roles[@]}
}

# get the options and evaluate them
OPTS=`getopt -o b:r:hd -l basedn:,roles:,help,debug -- "$@"`
eval set -- "$OPTS"
while true ; do
  case "$1" in
    -b|--basedn) basedn="$2" ; shift 2 ;;
    -r|--roles) getRoles $2 ; shift 2 ;;
    -\?|--help)
      showhelp;
      exit 0;
      shift 1;;
    -d|--debug) DEBUG=true ; shift 1;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done;

if [[ ${#roles[@]} -eq 0 || "$basedn" == "" ]]; then
  showhelp;
  exit 1;
fi

read -r -p 'Enter the uid: ' user
read -r -p 'Enter first name: ' fn
read -r -p 'Enter last name: ' ln

userldif="
dn: uid=$user,$basedn
cn: $fn $ln
givenName: $fn
sn: $ln
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
objectClass: top
uid: $user
"

for role in "${roles[@]}"; do 
  roleldif+="
dn: cn=$role,ou=roles,$basedn
changetype: modify
add: uniqueMember
uniqueMember: uid=$user,$basedn
"
done;


echo "$userldif"
echo "$roleldif"

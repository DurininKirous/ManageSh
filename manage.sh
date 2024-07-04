#!/bin/bash
CheckGroup() 
{
  [[ -n $(cat /etc/group | awk -F ':' '{print $1}' | grep -w $1) ]]
}
if [[ $# -eq 0 ]]; then
  echo "There is nothing like add_users, add_group, off_group, on_group"
  exit 1
fi
if [[ $1 == add_group ]];then
  $(CheckGroup $2)
  if [[ $? -eq 1 ]]; then
    groupadd $2
    ssh -i /home/user/.ssh/id_ecdsa user@vladivostok "sudo groupadd $2"
  else
    echo "Such group already exists"
    exit 2
  fi
fi
if [[ $1 == add_users ]];then
  $(CheckGroup $2)
  if [[ $? -eq 1 ]];then
    echo "Such group doesn't exists"
    exit 3
  else
    for (( i=1; i <= $4; i++ ));do
      name="${3}${i}"
      useradd -m -G $2 $name
      ssh -i /home/user/.ssh/id_ecdsa user@vladivostok  "sudo useradd -m -G $2 $name"
      password=$(openssl rand -base64 16)
      usermod --password $password $name
      ssh -i /home/user/.ssh/id_ecdsa user@vladivostok  "sudo usermod --password $password $name"
      echo $name $password
   done
  fi
fi
if [[ $1 == off_group ]];then
  $(CheckGroup $2)
  if [[ $? -eq 1 ]];then
    echo "Such group doesn't exists"
    exit 3
  else
    grep $2 /etc/group | cut -d ':' -f 4 | tr ',' '\n' | xargs -I ARG passwd -l ARG
    ssh -i /home/user/.ssh/id_ecdsa user@vladivostok  "grep $2 /etc/group | cut -d ':' -f 4 | tr ',' '\n' | xargs -I ARG sudo passwd -l ARG"
  fi
fi
if [[ $1 == on_group ]];then
  $(CheckGroup $2)
  if [[ $? -eq 1 ]];then
    echo "Such group doesn't exists"
    exit 3
  else
    grep $2 /etc/group | cut -d ':' -f 4 | tr ',' '\n' | xargs -I ARG passwd -u ARG
    ssh -i /home/user/.ssh/id_ecdsa user@vladivostok  "grep $2 /etc/group | cut -d ':' -f 4 | tr ',' '\n' | xargs -I ARG sudo passwd -u ARG"
  fi
fi

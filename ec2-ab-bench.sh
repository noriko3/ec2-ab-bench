#!/bin/bash

usage() {
    echo "Usage: $(basename ${0}) [url]"
}

prog=`echo $(basename ${0}) | sed -e "s/\.sh//g"`

if [ $# -eq 1 ]; then
    target_url="${1}"
else
    usage 1>&2
    exit 1
fi

# Config file check
if [ ! -r ~/.aws/config ] || [ ! -r ${prog}.conf ]; then
    echo "Cannot read config file." 1>&2
    exit 1
fi

# Command check
if ! type -p jq > /dev/null; then
    echo "Command not found: jq" 1>&2
    exit 1
fi

. ${prog}.conf

mkdir -p ${HOME}/tmp/ab
DIR_DATE=`date +%m%d-%H%M`

work_dir=${HOME}/tmp/ab/${DIR_DATE}
mkdir -p ${work_dir}
user_data="${work_dir}/user-data.txt"
output_file="${work_dir}/output.json"

echo "work_dir: "${work_dir}

cat <<EOF > ${user_data}
#cloud-config
packages:
 - httpd
runcmd: 
 - [sysctl, -w, fs.file-max=99848]
 - [ls, -la, /etc/security/limits.conf]
 - [sh, -c, 'echo "* soft nofile 1048576" >> /etc/security/limits.conf']
 - [sh, -c, 'echo "* hard nofile 1048576" >> /etc/security/limits.conf']
EOF

aws ec2 run-instances \
    --image-id ${image_id} \
    --instance-type ${instance_type} \
    --count ${instance_count} \
    --security-group-ids ${security_group_ids} \
    --subnet-id ${subnet_id} \
    --key-name ${key_name} \
    --user-data file://${user_data} \
    --associate-public-ip-address \
    > ${output_file}

instance_id=`cat ${output_file} | jq -r ".Instances[].InstanceId"`

aws ec2 create-tags \
    --resources ${instance_id} \
    --tags Key=Name,Value=${prog} \
    > /dev/null

# Complete message
instance_id_list=`echo ${instance_id} | sed -e "s/\s/ /g"`
echo "Instances: ${instance_id_list}"
echo "Cleanup command: aws ec2 terminate-instances --instance-ids ${instance_id_list}"

echo "sleep 1min"
sleep 60s

for ins in ${instance_id}
do
    host=`aws ec2 describe-instances --instance-ids ${ins} | jq -r ".Reservations[].Instances[].NetworkInterfaces[].Association.PublicDnsName"`
    echo "ab -n ${request_number} -c ${client_number} '${target_url}' && exit" | ssh -oStrictHostKeyChecking=no -i ${HOME}/.ssh/${key_name}.pem ec2-user@${host} > ${work_dir}/${ins}.log 2>/dev/null &
done

exit $?

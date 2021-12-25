#!/usr/bin/env bash
#
# Offical default configurations are referenced from:
# https://insights-core.readthedocs.io/en/latest/shared_parsers_catalog/etcd_conf.html
# https://github.com/etcd-io/etcd/blob/main/etcd.conf.yml.sample

#################################
# Important!!!
# Please check variables before apply
# ETCD
ETCD_ENV="stage"
SERVICE="etcd-cluster"
ENV="stage"
# FATAL!!! YOU SHOULD CHANGE ENV HERE!!!
FOR="gp"

# Datadog Agent
export DD_AGENT_MAJOR_VERSION=7
export DD_API_KEY=
export DD_SITE="datadoghq.com"
export DD_CONFIG_DIR="/etc/datadog-agent/conf.d/etcd.d"
export DD_TAGS="dd_env:${ETCD_ENV} dd_service:etcd"
#################################

sudo su

ETCD_USER="etcd"
ETCD_CONFIG_DIR="/etc/etcd"
ETCD_REMOTE_ROOT=("prod" "sta" "dev" "uat")
ETCD_CONFIG_FILE="${ETCD_CONFIG_DIR}/etcd.conf"
ETCD_NAME="$HOSTNAME"
ETCD_VERSION="v3.5.1"
ETCD_DATA_DIR="/home/etcd"
ETCD_QUOTA_BACKEND_BYTES=$((8*1024*1024*1024))
INSTANCE_FILTER="labels.service=${SERVICE} AND labels.env=${ENV} AND labels.for=${FOR}"

curl -L https://github.com/coreos/etcd/releases/download/"$ETCD_VERSION"/etcd-"$ETCD_VERSION"-linux-amd64.tar.gz -o etcd-"$ETCD_VERSION"-linux-amd64.tar.gz

tar xzvf etcd-"$ETCD_VERSION"-linux-amd64.tar.gz
rm etcd-"$ETCD_VERSION"-linux-amd64.tar.gz

cd etcd-"$ETCD_VERSION"-linux-amd64 || exit 1
cp etcd /usr/local/bin/
cp etcdctl /usr/local/bin/

rm -rf etcd-"$ETCD_VERSION"-linux-amd64

mkdir -p "${ETCD_DATA_DIR}"
mkdir -p "${ETCD_CONFIG_DIR}"

groupadd --system $ETCD_USER
useradd -s /sbin/nologin --system -g $ETCD_USER $ETCD_USER
chown -R $ETCD_USER:$ETCD_USER "${ETCD_DATA_DIR}"

# internal ip for current VM
THIS_IP="$(/sbin/ifconfig ens4 | grep 'inet ' | cut -d: -f2 | awk '{ print $2}')"

IP_ALL=$(gcloud compute instances list --filter="${INSTANCE_FILTER}" | awk 'FNR >1 {print $4}')
NAME_ALL=$(gcloud compute instances list --filter="${INSTANCE_FILTER}" | awk 'FNR >1 {print $1}')

IP_ARRAY=(${IP_ALL[@]})
NAME_ARRAY=(${NAME_ALL[@]})
LEN=${#IP_ARRAY[@]}


for ((i=0; i<"$LEN"; i++))
do
  ETCD_INITIAL_CLUSTER+="${NAME_ARRAY[$i]}=http://${IP_ARRAY[$i]}:2380,"
done

ETCD_LISTEN_CLIENT_URLS="http://${THIS_IP}:2379,http://127.0.0.1:2379"
ETCD_LISTEN_PEER_URLS="http://${THIS_IP}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${THIS_IP}:2379"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${THIS_IP}:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_AUTO_COMPACTION_RETENTION="1"

cat << EOF | tee -a "$ETCD_CONFIG_FILE" > /dev/null
ETCD_NAME=${ETCD_NAME}
ETCD_DATA_DIR=${ETCD_DATA_DIR}
ETCD_QUOTA_BACKEND_BYTES=${ETCD_QUOTA_BACKEND_BYTES}
ETCD_LISTEN_PEER_URLS=${ETCD_LISTEN_PEER_URLS}
ETCD_LISTEN_CLIENT_URLS=${ETCD_LISTEN_CLIENT_URLS}
ETCD_INITIAL_ADVERTISE_PEER_URLS=${ETCD_INITIAL_ADVERTISE_PEER_URLS}
ETCD_ADVERTISE_CLIENT_URLS=${ETCD_ADVERTISE_CLIENT_URLS}
ETCD_INITIAL_CLUSTER=${ETCD_INITIAL_CLUSTER}
ETCD_INITIAL_CLUSTER_STATE=${ETCD_INITIAL_CLUSTER_STATE}
ETCD_AUTO_COMPACTION_RETENTION=${ETCD_AUTO_COMPACTION_RETENTION}
ETCD_MAX_WALS=5
ETCD_ENABLE_V2=true
EOF

cat << EOF | tee -a /etc/systemd/system/etcd.service > /dev/null
[Unit]
Description=etcd key-value store
Documentation=https://github.com/etcd-io/etcd
After=network.target
[Service]
User=${ETCD_USER}
Type=notify
EnvironmentFile=${ETCD_CONFIG_FILE}
ExecStart=/usr/local/bin/etcd
Restart=always
RestartSec=10s
LimitNOFILE=40000
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable etcd.service
systemctl start etcd.service

max_retry=3
wait_time=5
n=0
until [ "$n" -ge "$max_retry" ]
do
  # Check etcd cluster health
  current_status="$(etcdctl cluster-health)"
  expect_status="cluster is healthy"
  [[ "$current_status" =~ "$expect_status" ]] && break
  n=$((n+1))
  sleep $wait_time
done

for i in "${ETCD_REMOTE_ROOT[@]}"
do
  # Must create etcd remote root before pushing
  # ref: https://github.com/csigo/config/blob/master/pusher/main.go
  ETCDCTL_API=2 etcdctl mkdir "/configs/envs/$i"
done

bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"

mkdir -p $DD_CONFIG_DIR
cat << EOF > $DD_CONFIG_DIR/etcd.yaml
init_config:
instances:
   - url: "http://localhost:2379"
     use_preview: true
     prometheus_url: http://localhost:2379/metrics
EOF

cat << EOF > /etc/datadog-agent/datadog.yaml
api_key: ${DD_API_KEY}
site: datadoghq.com
tags:
  - env:dd_env:${ETCD_ENV}
  - env:dd_service:etcd
  - env:dd_for:${FOR}
  - dd_env:${ETCD_ENV}
  - dd_service:etcd
  - dd_for:${FOR}
EOF

systemctl restart datadog-agent

echo "Startup Script is finished."

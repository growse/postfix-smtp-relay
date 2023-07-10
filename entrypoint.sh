#!/bin/sh
_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child" 2>/dev/null
}

trap _term TERM

echo 'Settings postfix using postconf variables from environment...'
env | grep '^POSTCONF_' \
    | cut -d _ -f 2- \
    | xargs -r -n 1 -I % postconf -e '%'

postconf -e "mydomain = ${RELAY_MYDOMAIN}"
postconf -e "relayhost = ${RELAY_HOST}"
postconf -e "relay_domains = ${RELAY_DOMAINS}"
postconf -e "myhostname = ${RELAY_MYHOSTNAME}"

postconf -e "2bounce_notice_recipient = postmaster@${RELAY_MYDOMAIN}"

postconf -e "smtpd_sasl_local_domain = ${RELAY_MYDOMAIN}"
postconf -e "smtp_sasl_password_maps = inline:{${RELAY_HOST}=${RELAY_USERNAME}:${RELAY_PASSWORD}}"

if [ -f "${tls_cacert_path}" ]; then
  postconf -e "smtpd_tls_CAfile = ${tls_cacert_path}"
fi

if [ -f "${tls_cert_path}" ]; then
  postconf -e "smtpd_tls_cert_file = ${tls_cert_path}"
fi

if [ -f "${tls_key_path}" ]; then
  postconf -e "smtpd_tls_key_file = ${tls_key_path}"
  postconf -e "smtpd_use_tls = yes"
  postconf -e "smtpd_enforce_tls = yes"
  echo "submission inet n       -       n       -       -       smtpd" >> /etc/postfix/master.cf
fi

/usr/sbin/postfix start-fg &
child=$!
wait "$child"

# syntax=docker/dockerfile:1

FROM alpine:3.18.2

RUN --mount=type=cache,target=/var/cache/apk apk --update add postfix=3.8.1-r0 cyrus-sasl=2.1.28-r4 cyrus-sasl-digestmd5=2.1.28-r4 cyrus-sasl-login=2.1.28-r4 tzdata busybox-extras

RUN echo "maillog_file = /dev/stdout" >> /etc/postfix/main.cf

RUN postconf -e 'inet_interfaces = all' \
    && postconf -e 'inet_protocols = ipv6,ipv4' \
    && postconf -e 'maillog_file = /dev/stdout' \
    && postconf -e 'smtpd_relay_restrictions = permit_sasl_authenticated, reject' \
    && postconf -e 'relay_destination_concurrency_limit = 20' \
    && postconf -e 'bounce_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'delay_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'error_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'header_size_limit = 4096000' \
    && postconf -e 'smtp_sasl_security_options = noanonymous' \
    && postconf -e 'smtp_sasl_auth_enable = yes' \
    && postconf -e 'smtp_sasl_path = smtpd' \
    && postconf -e 'smtp_tls_security_level = encrypt' \
    && postconf -e 'smtp_tls_session_cache_database = lmdb:$data_directory/smtp_tls_session_cache' \
    && postconf -e 'smtpd_sasl_path = smtpd' \
    && postconf -e 'smtpd_sasl_auth_enable = yes' \
    && postconf -e 'smtpd_tls_loglevel = 1' \
    && postconf -e 'smtpd_tls_received_header = yes' \
    && postconf -e 'smtpd_tls_session_cache_timeout = 3600s' \
    && postconf -e 'smtpd_sasl_tls_security_options=noanonymous' \
    && postconf -e 'smtpd_tls_session_cache_database = lmdb:$data_directory/smtpd_tls_session_cache'

RUN mkdir /etc/sasl2 && echo 'pwcheck_method: auxprop' >/etc/sasl2/smtpd.conf \
                         && echo 'auxprop_plugin: sasldb' >>/etc/sasl2/smtpd.conf \
                         && echo 'mech_list: LOGIN DIGEST-MD5' >>/etc/sasl2/smtpd.conf \
                         && echo 'sasldb_path: /data/sasldb2' >>/etc/sasl2/smtpd.conf \
                         && echo 'log_level: 2' >>/etc/sasl2/smtpd.conf


RUN postalias /etc/postfix/aliases

#RUN mkdir -p /data &&  echo "pass" | saslpasswd2 -f /data/sasldb2 -c -u growse.com -p user && chown :postfix /data/sasldb2 && chmod 440 /data/sasldb2
# Runtime configuration
ENV RELAY_DOMAINS ""
ENV RELAY_HOST ""
ENV RELAY_MYDOMAIN ""
ENV RELAY_MYHOSTNAME ""

ENV tls_cacert_path ""
ENV tls_cert_path ""
ENV tls_key_path ""

EXPOSE 25/tcp
EXPOSE 587/tcp

VOLUME [/var/spool/postfix, /data]
COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]

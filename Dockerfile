FROM centos:7

VOLUME ["/scripts", "/results"]

RUN yum install nmap mailx postfix -y; yum clean all

# Postfix is used to send email
CMD /usr/sbin/postfix start; /scripts/scan.sh

FROM centos:centos7

# info
MAINTAINER version: 0.1

# update container
RUN yum -y update
RUN yum -y install epel-release
RUN yum -y install gd gd-devel wget httpd php gcc make perl tar sendmail supervisor unzip

# users and groups
RUN adduser nagios
RUN groupadd nagcmd
RUN usermod -a -G nagcmd nagios
RUN usermod -a -G nagios apache

# get archives

ADD https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.3.2.tar.gz nagios-4.3.2.tar.gz
ADD https://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz nagios-plugins-2.2.1.tar.gz



# install nagios
RUN tar xf nagios-4.3.2.tar.gz
RUN cd nagios-4.3.2 && ./configure --with-command-group=nagcmd
RUN cd nagios-4.3.2 && make all && make install && make install-init
RUN cd nagios-4.3.2 && make install-config && make install-commandmode && make install-webconf

# user/password = nagiosadmin/nagiosadmin
RUN echo "nagiosadmin:M.t9dyxR3OZ3E" > /usr/local/nagios/etc/htpasswd.users
RUN chown nagios:nagios /usr/local/nagios/etc/htpasswd.users

# install plugins
RUN tar xf nagios-plugins-2.2.1.tar.gz
RUN cd nagios-plugins-2.2.1 && ./configure --with-nagios-user=nagios --with-nagios-group=nagios
RUN cd nagios-plugins-2.2.1 && make && make install

# create initial config
RUN /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

# some bug fixes
RUN touch /var/www/html/index.html
RUN chown nagios.nagcmd /usr/local/nagios/var/rw
RUN chmod g+rwx /usr/local/nagios/var/rw
RUN chmod g+s /usr/local/nagios/var/rw

# init bug fix
# RUN sed -i '/$NagiosBin -d $NagiosCfgFile/a (sleep 10; chmod 666 \/usr\/local\/nagios\/var\/rw\/nagios\.cmd) &' /etc/init.d/nagios

# remove gcc
RUN yum -y remove gcc

# port 80
EXPOSE 25 80

# supervisor configuration
ADD supervisord.conf /etc/supervisord.conf

# start up nagios, sendmail, apache
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]


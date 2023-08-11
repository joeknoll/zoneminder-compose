FROM archlinux:latest as buildlayer
#RUN rm -r /var/lib/pacman/sync/
RUN /usr/sbin/pacman -Syyu --noconfirm
RUN /usr/bin/pacman-key -u
RUN /usr/bin/pacman-db-upgrade
RUN /usr/sbin/pacman -S --noconfirm git base-devel cmake sudo \
    libvncserver pcre vlc \
    nginx fcgiwrap
RUN /usr/sbin/echo "nobody ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/nobody

################### Install AUR dependencies:
RUN /usr/sbin/su -s /bin/bash nobody -c "cd /tmp/ && /usr/sbin/git clone https://aur.archlinux.org/yay.git"
RUN /usr/bin/mkdir --mode=777 -p /.cache/go-build
RUN /usr/sbin/su -s /bin/bash nobody -c "cd /tmp/yay/ && /usr/sbin/makepkg -s --noconfirm -i"
RUN /usr/sbin/su -s /bin/bash nobody -c "/usr/sbin/yay -S --noconfirm --norebuild --noredownload --useask pod2man"
RUN /usr/sbin/su -s /bin/bash nobody -c "/usr/sbin/yay -S --noconfirm --norebuild --noredownload --useask zoneminder"

RUN /usr/sbin/touch /var/log/zm.log   && /usr/sbin/chown http:http /var/log/zm.log
RUN /usr/sbin/mkdir -p /run/fcgiwrap/ && /usr/sbin/chown http:http /run/fcgiwrap/

################### Clean-up
#RUN /usr/sbin/pacman -Rs --noconfirm git base-devel cmake

################### Create DB
FROM mariadb:latest as zmdb
COPY --from=buildlayer /usr/share/zoneminder/db/zm_create.sql /docker-entrypoint-initdb.d/zm_create.sql
COPY --from=buildlayer /usr/share/zoneminder/db/ /usr/share/zoneminder/db/

################### Create Zoneminder
FROM buildlayer as zm
ADD ./dockerinit.sh /dockerinit.sh
CMD ["/dockerinit.sh"]


sudo rm /etc/apache2/extra/httpd-vhosts.conf
sudo mkdir /etc/resolver
sudo ln -s $HOME/.dotfiles/localhost/httpd-vhosts.conf /etc/apache2/extra/httpd-vhosts.conf
ln -s $HOME/.dotfiles/localhost/dnsmasq.conf /usr/local/etc/dnsmasq.conf
sudo ln -s $HOME/.dotfiles/localhost/gabri /etc/resolver/gabri
sudo ln -s $HOME/.dotfiles/localhost/trunk /etc/resolver/trunk

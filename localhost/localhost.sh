sudo rm /etc/apache2/extra/httpd-vhosts.conf
sudo mkdir /etc/resolver
sudo ln -s $HOME/.dotfiles/localhost/httpd-vhosts.local /etc/apache2/extra/httpd-vhosts.conf
ln -s $HOME/.dotfiles/localhost/dnsmasq.local /usr/local/etc/dnsmasq.conf
sudo ln -s $HOME/.dotfiles/localhost/gabri.local /etc/resolver/gabri
sudo ln -s $HOME/.dotfiles/localhost/trunk.local /etc/resolver/trunk

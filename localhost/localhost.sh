sudo rm /etc/apache2/extra/httpd-vhosts.conf
sudo mkdir /etc/resolver
sudo ln -s $HOME/.dotfiles/apache/httpd-vhosts.conf /etc/apache2/extra/httpd-vhosts.conf
sudo ln -s $HOME/.dotfiles/dnsmasq/gabri /etc/resolver/gabri
sudo ln -s $HOME/.dotfiles/dnsmasq/trunk /etc/resolver/trunk

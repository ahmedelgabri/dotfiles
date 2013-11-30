# apache & dnsmasq

1- Create `Sites` folder under User.

2- run `localhost.sh` to symlink the proper files to get `.gabri` & `.trunk` domains working locally.

3- edit `httpd.conf`
    - uncomment apache php module
    - uncomment vhosts files
    - change _DocumentRoot_ & all instances related to this to `/Users/Gabri/Sites`
    - add `index.php` to `<IfModule dir_module>`

    <Directory "/Users/Gabri/Sites">
      Options Indexes MultiViews
      AllowOverride All
      Order allow,deny
      Allow from all
    </Directory>

4- restart apache

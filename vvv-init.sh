# Provision WordPress Trunk

# Make a database, if we don't already have one
echo -e "\nCreating database 'wordpress_trunk' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS wordpress_trunk"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON wordpress_trunk.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Nginx Logs
if [[ ! -d /srv/log/wordpress-trunk ]]; then
    mkdir -p /srv/log/wordpress-trunk
fi
    touch /srv/log/wordpress-trunk/error.log
    touch /srv/log/wordpress-trunk/access.log

# Checkout, install and configure WordPress trunk via core.svn
if [[ ! -d "/srv/www/wordpress-trunk" ]]; then
  echo "Checking out WordPress trunk from core.svn, see https://core.svn.wordpress.org/trunk"
  svn checkout "https://core.svn.wordpress.org/trunk/" "/srv/www/wordpress-trunk"
  cd /srv/www/wordpress-trunk
  echo "Configuring WordPress trunk..."
  noroot wp core config --dbname=wordpress_trunk --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
// Match any requests made via xip.io.
if ( isset( \$_SERVER['HTTP_HOST'] ) && preg_match('/^(local.wordpress-trunk.)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(.xip.io)\z/', \$_SERVER['HTTP_HOST'] ) ) {
    define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
    define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
}

define( 'WP_DEBUG', true );
PHP
  echo "Installing WordPress trunk..."
  noroot wp core install --url=local.wordpress-trunk.dev --quiet --title="Local WordPress Trunk Dev" --admin_name=admin --admin_email="admin@local.dev" --admin_password="password"
else
  echo "Updating WordPress trunk..."
  cd /srv/www/wordpress-trunk
  svn up
fi
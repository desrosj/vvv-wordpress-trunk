# Provision WordPress Trunk

# Make a database, if we don't already have one
echo -e "\nCreating database 'wordpress_${VVV_SITE_NAME}' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS wordpress_${VVV_SITE_NAME}"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON wordpress_${VVV_SITE_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Nginx Logs
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/error.log
touch ${VVV_PATH_TO_SITE}/log/access.log

# Checkout, install and configure WordPress trunk via core.svn
if [[ ! -d "${VVV_PATH_TO_SITE}/public_html" ]]; then
  echo "Checking out WordPress trunk from core.svn, see https://core.svn.wordpress.org/trunk"
  svn checkout "https://core.svn.wordpress.org/trunk/" "${VVV_PATH_TO_SITE}/public_html"
  cd ${VVV_PATH_TO_SITE}/public_html
  echo "Configuring WordPress trunk..."
  noroot wp core config --dbname=wordpress_${VVV_SITE_NAME} --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
// Match any requests made via xip.io.
if ( isset( \$_SERVER['HTTP_HOST'] ) && preg_match('~^(getenv("VVV_SITE_NAME").)\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(.xip.io)\z/', \$_SERVER['HTTP_HOST'] ) ) {
    define( 'WP_HOME', 'http://' . \$_SERVER['HTTP_HOST'] );
    define( 'WP_SITEURL', 'http://' . \$_SERVER['HTTP_HOST'] );
}

define( 'WP_DEBUG', true );
PHP
  echo "Installing WordPress trunk..."
  noroot wp core install --url=${VVV_SITE_NAME}.dev --quiet --title="Local WordPress Trunk Dev" --admin_name=admin --admin_email="admin@local.dev" --admin_password="password"
else
  echo "Updating WordPress trunk..."
  cd ${VVV_PATH_TO_SITE}/public_html
  svn up
fi

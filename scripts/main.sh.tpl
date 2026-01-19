#!/bin/bash

until ping -c 1 google.com; do
  echo "Waiting for internet..."
  sleep 5
done

echo "# ++++++++++++++++++++++ SQL INSTALLATION BEGIN ++++++++++++++++++++++"
echo "# ++++++++++++++++++++++ INSTALLATION BEGIN ++++++++++++++++++++++"
apt update
apt install -y git nginx npm mysql-client
echo "# ++++++++++++++++++++++ INSTALLATION END ++++++++++++++++++++++"

sleep 10

RDS_ADDRESS="${rds_address}"
export MYSQL_PWD="${db_password}"

echo "# ++++++++++++++++++++++ SQL COMMAND BEGIN ++++++++++++++++++++++"
mysql -h $RDS_ADDRESS -u admin <<EOF
CREATE DATABASE IF NOT EXISTS transactions;
USE transactions;

CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    amount DECIMAL(10, 2) NOT NULL,
    description VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
EOF
unset MYSQL_PWD
echo "# ++++++++++++++++++++++ SQL COMMAND END ++++++++++++++++++++++"
echo "# ++++++++++++++++++++++ SQL INSTALLATION END ++++++++++++++++++++++"

echo "# ++++++++++++++++++++++ BACKEND INSTALLATION BEGIN ++++++++++++++++++++++"

cat <<'EOF' > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _;

    location / {
        resolver 169.254.169.253 valid=10s; 
        
        proxy_pass "${s3_url}";
        proxy_set_header Host "${s3_host}";

        proxy_set_header Authorization "";
        proxy_hide_header x-amz-id-2;
        proxy_hide_header x-amz-request-id;
        proxy_intercept_errors on;

        error_page 404 = /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host NGINX_VAR_HOST;
        proxy_set_header X-Real-IP NGINX_VAR_REMOTE_ADDR;
        proxy_set_header X-Forwarded-For NGINX_VAR_X_FORWARDED;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 90s;
        proxy_send_timeout 90s;
        proxy_read_timeout 90s;
    }
}
EOF

sed -i 's/NGINX_VAR_HOST/$host/g' /etc/nginx/sites-available/default
sed -i 's/NGINX_VAR_REMOTE_ADDR/$remote_addr/g' /etc/nginx/sites-available/default
sed -i 's/NGINX_VAR_X_FORWARDED/$proxy_add_x_forwarded_for/g' /etc/nginx/sites-available/default

systemctl restart nginx
echo "# ++++++++++++++++++++++ NGINX CONF END ++++++++++++++++++++++"

echo "# ++++++++++++++++++++++ CLONE & SETUP BEGIN ++++++++++++++++++++++"
mkdir -p /var/www/backend
cd /var/www/backend
git clone -b development https://github.com/ebad-arshad/s3-cloudfront-rds-ec2-web-application.git
mv s3-cloudfront-rds-ec2-web-application/app-tier/* .
rm -rf s3-cloudfront-rds-ec2-web-application
echo "# ++++++++++++++++++++++ CLONE & SETUP END ++++++++++++++++++++++"

echo "# ++++++++++++++++++++++ DB CONFIG BEGIN ++++++++++++++++++++++"
if [ -f DbConfig.js ]; then
    sed -i "s|DB_HOST.*|DB_HOST: '${rds_address}',|g" DbConfig.js
    sed -i "s|DB_USER.*|DB_USER: '${db_user}',|g" DbConfig.js
    sed -i "s|DB_PWD.*|DB_PWD: '${db_password}',|g" DbConfig.js
    sed -i "s|DB_DATABASE.*|DB_DATABASE: '${db_database}',|g" DbConfig.js
else
    echo "DbConfig.js not found"
fi
echo "# ++++++++++++++++++++++ DB CONFIG END ++++++++++++++++++++++"
echo "# ++++++++++++++++++++++ START APP BEGIN ++++++++++++++++++++++"
# Install Node.js dependencies
npm install

# Install PM2 to manage the Node.js process (keeps it running in background)
npm install -g pm2

# Start the application using npm start via PM2
pm2 start npm --name "backend" -- start

# Configure PM2 to start on system boot
pm2 startup systemd
pm2 save
echo "# ++++++++++++++++++++++ START APP END ++++++++++++++++++++++"

echo "# ++++++++++++++++++++++ BACKEND INSTALLATION END ++++++++++++++++++++++"
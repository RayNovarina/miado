from ruby:2.3

env DEBIAN_FRONTEND=noninteractive \
  NODE_VERSION=6.9.1

run sed -i '/deb-src/d' /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y build-essential libpq-dev postgresql-client

run curl -sSL "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" | tar xfJ - -C /usr/local --strip-components=1 && \
  npm install npm -g

run useradd -m -s /bin/bash -u 1000 railsuser
user railsuser

workdir /app

# Works:
# docker-compose run -p 3000:3000 web bash -c "bin/rails server -b 0.0.0.0"

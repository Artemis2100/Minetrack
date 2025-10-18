FROM node:16

ARG TINI_VER="v0.19.0"

# install tini
ADD https://github.com/krallin/tini/releases/download/$TINI_VER/tini /sbin/tini
RUN chmod +x /sbin/tini

# ADD THIS SECTION TO FORCE ARCHIVE MIRRORS
# This overwrites the sources.list to point to the Debian Archive.
RUN sed -i 's/http:\/\/deb.debian.org/http:\/\/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i 's/http:\/\/security.debian.org/http:\/\/archive.debian.org\/debian-security/g' /etc/apt/sources.list

# install sqlite3
RUN apt-get update \
    && apt-get install    --quiet --yes --no-install-recommends sqlite3 \
    && apt-get clean      --quiet --yes                                  \
    && apt-get autoremove --quiet --yes                                  \
    && rm -rf /var/lib/apt/lists/*

# copy minetrack files
WORKDIR /usr/src/minetrack
COPY . .

# build minetrack
RUN npm install --build-from-source \
 && npm run build

# run as non root
RUN addgroup --gid 10043 --system minetrack \
 && adduser  --uid 10042 --system --ingroup minetrack --no-create-home --gecos "" minetrack \
 && chown -R minetrack:minetrack /usr/src/minetrack
USER minetrack

EXPOSE 8080

ENTRYPOINT ["/sbin/tini", "--", "node", "main.js"]

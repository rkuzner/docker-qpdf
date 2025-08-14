FROM ubuntu:latest

# update image packages
RUN apt-get update
# install cron daemon to support in-container cron schedule
RUN apt-get install -y cron
# install qPDF tool onto the image
RUN apt-get install -y qpdf

# add a user so the tool is encapsulated
RUN useradd -m -U -G crontab -s /bin/bash conusr

# allow the user to have cron schedules
RUN touch /var/spool/cron/crontabs/conusr && \
    chown conusr:crontab /var/spool/cron/crontabs/conusr && \
    chmod u+s /usr/sbin/cron

# prepare the image EntryPoint with logMessage function
COPY scripts/log-message.sh /
COPY scripts/entrypoint.sh /
RUN chmod +x /entrypoint.sh

# prepare the tool-run script with logMessage function
COPY scripts/log-message.sh /home/conusr/
COPY scripts/tool-run.sh /home/conusr/
RUN chown conusr:conusr /home/conusr/tool-run.sh && \
    chmod +x /home/conusr/tool-run.sh

# allow app to operate on data, source & target folders
# allow folders for config & logs
RUN mkdir -p /config && chmod go+rw /config && \
    mkdir -p /logs   && chmod go+rw /logs   && \
    mkdir -p /source && chmod go+rw /source && \
    mkdir -p /target && chmod go+rw /target

# declare volumes
VOLUME /config /logs /source /target

# allow app to find passwords file on default path
ENV PASSWORDS_FILENAME=/config/passwords.csv
ENV LOG_FOLDER=/logs
ENV KEEP_SOURCEFILE=false
ENV MOVE_UNENCRYPTED=true
ENV TOOL_SCHEDULE=

# switch to the user
USER conusr
WORKDIR /home/conusr

ENTRYPOINT ["/entrypoint.sh"]

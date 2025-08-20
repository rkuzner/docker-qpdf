FROM debian:stable-slim

# update image packages
RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y

# install cron daemon to support in-container cron schedule
# install qPDF tool onto the image
RUN apt-get install -y cron qpdf

# add a user so the tool is encapsulated
RUN useradd -m -U -G users,crontab -s /bin/bash theuser

# allow the user to have cron schedules
RUN \
 touch /var/spool/cron/crontabs/theuser && \
 chown theuser:crontab /var/spool/cron/crontabs/theuser && \
 chmod u+s /usr/sbin/cron

 # prepare the image EntryPoint with logMessage function
 COPY scripts/log-message.sh scripts/entrypoint.sh /app/
 RUN chmod +x /app/entrypoint.sh

 # prepare the tool-run script with logMessage function
 COPY scripts/log-message.sh scripts/tool-run.sh /home/theuser/
 RUN \
 chown theuser:theuser /home/theuser/log-message.sh && \
 chown theuser:theuser /home/theuser/tool-run.sh && \
 chmod +x /home/theuser/tool-run.sh

 # allow user to operate on config, logs, source & target folders
 RUN \
  mkdir -p /app    && chmod go+r /app && \
  mkdir -p /config && chmod go+rw /config && \
  mkdir -p /logs   && chmod go+rw /logs   && \
  mkdir -p /source && chmod go+rw /source && \
  mkdir -p /target && chmod go+rw /target

# declare volumes
VOLUME /config /logs /source /target

# add env var for tool_name
ENV TOOL_NAME="qpdf"

# switch to the user
USER theuser
WORKDIR /home/theuser

ENTRYPOINT ["/app/entrypoint.sh"]

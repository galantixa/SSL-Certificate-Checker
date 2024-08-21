FROM alpine:latest
RUN apk add --no-cache bash openssl mutt coreutils dcron tzdata curl
ENV TZ=Asia/Jakarta
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && echo "$TZ" > /etc/timezone
RUN mkdir -p /home/{username}
COPY check.sh /home/{username}/
COPY .env /home/username/
RUN chmod +x /home/{username}/check-ssl.sh
COPY ssl_cron_check /etc/crontabs/root
RUN touch /var/log/cron.log
CMD ["sh", "-c", "crond -f -l 2 && tail -f /dev/null"]

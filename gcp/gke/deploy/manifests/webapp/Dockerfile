FROM python:3.8.3-alpine
LABEL maintainer="Sudheer Kondla, skondla@me.com"
RUN mkdir /app
WORKDIR /app
COPY . /app
RUN addgroup -S app && adduser -S app -G app
RUN apk update && apk add bash
RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN cp lib/rdsAdmin.py /usr/local/lib/python3.8
RUN apk add curl
RUN chmod +x dbWebAPI.sh
#RUN chown -R app:app /app
USER app
EXPOSE 25443
ENTRYPOINT [ "/bin/bash" ]
CMD [ "dbWebAPI.sh" ]


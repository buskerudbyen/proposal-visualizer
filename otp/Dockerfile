FROM docker.io/opentripplanner/opentripplanner:6aadbf753fa1fb018a2ea64cedf3b53c80f9861f

## need to override the data location because /var/opentripplanner/ is a volume
WORKDIR /var/otp/
COPY *.json /var/otp/

ENV BIKELY_TOKEN=""
ENV BIKELY_AUTHORIZATION=""

RUN java $JAVA_OPTS -cp @/app/jib-classpath-file @/app/jib-main-class-file /var/otp/ --build --save

ENTRYPOINT java $JAVA_OPTS -cp @/app/jib-classpath-file @/app/jib-main-class-file /var/otp/ --load --serve

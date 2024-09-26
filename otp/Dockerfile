FROM docker.io/lehrenfried/opentripplanner:bikeep

## need to override the data location because /var/opentripplanner/ is a volume
WORKDIR /var/otp/
COPY *.json /var/otp/

RUN java $JAVA_OPTS -cp @/app/jib-classpath-file @/app/jib-main-class-file /var/otp/ --build --save

ENTRYPOINT java $JAVA_OPTS -cp @/app/jib-classpath-file @/app/jib-main-class-file /var/otp/ --load --serve

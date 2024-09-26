.PRECIOUS: %/streetGraph.obj
CURL:=curl -L -\# --fail --create-dirs
JAVA:=java -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1044 -Dlogback.configurationFile=${current_dir}/logback.xml
current_dir = $(shell pwd)

download: otp.jar

otp.jar:
	${CURL} https://otp.leonard.io/snapshots/otp-SNAPSHOT-shaded-latest.jar -o $@

build: otp.jar
	${JAVA} -Xmx50G -jar otp.jar --build --save .

run: otp.jar
	${JAVA} -XX:+HeapDumpOnOutOfMemoryError -Xmx10G -jar otp.jar --load --serve .

build-otp:
	cd ~/dev/OpenTripPlanner/ && \
		mvn clean package -Dmaven.test.skip -P prettierSkip && cp target/otp-*-*-shaded.jar ~/dev/norway/proposal-visualizer/otp/otp.jar

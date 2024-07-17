shopt -s globstar

xmlstarlet \
	edit \
	--inplace \
	-N mvn=http://maven.apache.org/POM/4.0.0 \
	--update '/mvn:project/mvn:version' \
	--value "$1" \
	pom.xml ./**/pom.xml

xmlstarlet \
	edit \
	--inplace \
	-N mvn=http://maven.apache.org/POM/4.0.0 \
	--update '/mvn:project/mvn:parent/mvn:version' \
	--value "$1" \
	pom.xml ./**/pom.xml

xmlstarlet \
	edit \
	--inplace \
	-N mvn=http://maven.apache.org/POM/4.0.0 \
	--subnode '/mvn:project/mvn:properties' \
	--type elem \
	-n "project.build.outputTimestamp" \
	--value "1980-01-01T00:00:02Z" \
	./pom.xml ./**/pom.xml


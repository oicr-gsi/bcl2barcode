# bcl2barcode

## Overview

bcl2barcode produces index (barcode) counts for all reads in a lane or set of lanes.

![Summary dot plot](./docs/summary.png)

## Dependencies

* [bcl2fastq 2.20.0.422](https://support.illumina.com/sequencing/sequencing_software/bcl2fastq-conversion-software.html)
* [htslib 1.9](https://github.com/samtools/htslib)

## Usage

### Cromwell
```java -jar cromwell.jar run bcl2barcode.wdl --inputs inputs.json```

### Inputs

#### Required workflow parameters:

Parameter|Value
---|---
bcl2barcode.basesMask | String
bcl2barcode.lanes | Array[Int]
bcl2barcode.runDirectory | String

#### Optional workflow parameters:

Parameter|Value
---|---
bcl2barcode.outputFileNamePrefix | String? (optional)

#### Optional task parameters:

Parameter|Value
---|---
bcl2barcode.countDualIndex.bgzip | String? (optional, default = "bgzip")
bcl2barcode.countDualIndex.cores | Int? (optional, default = 16)
bcl2barcode.countDualIndex.mem | Int? (optional, default = 16)
bcl2barcode.countDualIndex.modules | String? (optional, default = "htslib/1.9")
bcl2barcode.countSingleIndex.bgzip | String? (optional, default = "bgzip")
bcl2barcode.countSingleIndex.cores | Int? (optional, default = 16)
bcl2barcode.countSingleIndex.mem | Int? (optional, default = 16)
bcl2barcode.countSingleIndex.modules | String? (optional, default = "htslib/1.9")
bcl2barcode.generateIndexFastqs.bcl2fastq | String? (optional, default = "bcl2fastq")
bcl2barcode.generateIndexFastqs.mem | Int? (optional, default = 32)
bcl2barcode.generateIndexFastqs.modules | String? (optional, default = "bcl2fastq/2.20.0.422")

### Outputs

Output | Type | Description
---|---|---
`counts.gz` | File | Sorted index counts in csv format (count,index)

## Niassa + Cromwell

This WDL workflow is wrapped in a Niassa workflow (https://github.com/oicr-gsi/pipedev/tree/master/pipedev-niassa-cromwell-workflow) so that it can used with the Niassa metadata tracking system (https://github.com/oicr-gsi/niassa). 

* Building
```
mvn clean install
```

* Testing
```
mvn clean verify \
clean verify \
-Djava_opts="-Xmx1g -XX:+UseG1GC -XX:+UseStringDeduplication" \
-DrunTestThreads=2 \
-DskipITs=false \
-DskipRunITs=false \
-DworkingDirectory=/path/to/tmp/ \
-DschedulingHost=niassa_oozie_host \
-DwebserviceUrl=http://niassa-url:8080 \
-DwebserviceUser=niassa_user \
-DwebservicePassword=niassa_user_password \
-Dcromwell-host=http://cromwell-url:8000
```

## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

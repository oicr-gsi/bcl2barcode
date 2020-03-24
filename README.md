# bcl2barcode

bcl2barcode produces index (barcode) counts for all reads in a lane or set of lanes.

## Overview

## Dependencies

* [bcl2fastq 2.20.0.422](https://support.illumina.com/sequencing/sequencing_software/bcl2fastq-conversion-software.html)
* [htslib 1.9](https://github.com/samtools/htslib)


## Usage

### Cromwell
```
java -jar cromwell.jar run bcl2barcode.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`runDirectory`|String|Illumina run directory (e.g. /path/to/191219_M00000_0001_000000000-ABCDE).
`lanes`|Array[Int]|A single lane or a list of lanes for no lane splitting (merging lanes).
`basesMask`|String|The bases mask to produce the index reads (e.g. single 8bp index = "Y1N*,I8,N*", dual 8bp index = "Y1N*,I8,I8,N*").


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`outputFileNamePrefix`|String?|None|Output prefix to prefix output file names with.


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`generateIndexFastqs.bcl2fastq`|String|"bcl2fastq"|bcl2fastq binary name or path to bcl2fastq.
`generateIndexFastqs.modules`|String|"bcl2fastq/2.20.0.422"|Environment module name and version to load (space separated) before command execution.
`generateIndexFastqs.mem`|Int|32|Memory (in GB) to allocate to the job.
`generateIndexFastqs.timeout`|Int|6|Maximum amount of time (in hours) the task can run for.
`countDualIndex.bgzip`|String|"bgzip"|bgzip binary name or path to bgzip.
`countDualIndex.modules`|String|"htslib/1.9"|Environment module name and version to load (space separated) before command execution.
`countDualIndex.mem`|Int|16|Memory (in GB) to allocate to the job.
`countDualIndex.cores`|Int|16|The number of cores to allocate to the job.
`countDualIndex.timeout`|Int|6|Maximum amount of time (in hours) the task can run for.
`countSingleIndex.bgzip`|String|"bgzip"|bgzip binary name or path to bgzip.
`countSingleIndex.modules`|String|"htslib/1.9"|Environment module name and version to load (space separated) before command execution.
`countSingleIndex.mem`|Int|16|Memory (in GB) to allocate to the job.
`countSingleIndex.cores`|Int|16|The number of cores to allocate to the job.
`countSingleIndex.timeout`|Int|6|Maximum amount of time (in hours) the task can run for.


### Outputs

Output | Type | Description
---|---|---
`counts`|File|Gzipped and sorted index counts in csv format (count,index).


## Niassa + Cromwell

This WDL workflow is wrapped in a Niassa workflow (https://github.com/oicr-gsi/pipedev/tree/master/pipedev-niassa-cromwell-workflow) so that it can used with the Niassa metadata tracking system (https://github.com/oicr-gsi/niassa).

* Building
```
mvn clean install
```

* Testing
```
mvn clean verify \
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

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_

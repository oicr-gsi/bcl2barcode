version 1.0

workflow bcl2barcode {
  input {
    String runDirectory
    Array[Int] lanes
    String basesMask
    String? outputFileNamePrefix
  }

  call generateIndexFastqs {
    input:
      runDirectory = runDirectory,
      lanes = lanes,
      basesMask = basesMask
  }
  if(defined(generateIndexFastqs.index2)) {
    call countDualIndex {
      input:
        index1 = generateIndexFastqs.index1,
        index2 = select_first([generateIndexFastqs.index2]),
        outputFileNamePrefix = outputFileNamePrefix
    }
  }
  if(!defined(generateIndexFastqs.index2)){
    call countSingleIndex {
      input:
        index1 = generateIndexFastqs.index1,
        outputFileNamePrefix = outputFileNamePrefix
    }
  }

  output {
    File counts = select_first([countSingleIndex.counts, countDualIndex.counts])
  }

  parameter_meta {
    runDirectory: {
      description: "Illumina run directory (e.g. /path/to/191219_M00000_0001_000000000-ABCDE).",
      vidarr_type: "directory"
    }
    lanes: "A single lane or a list of lanes for no lane splitting (merging lanes)."
    basesMask: "The bases mask to produce the index reads (e.g. single 8bp index = \"Y1N*,I8,N*\", dual 8bp index = \"Y1N*,I8,I8,N*\")."
    outputFileNamePrefix: "Output prefix to prefix output file names with."
  }

  meta {
    author: "Michael Laszloffy"
    email: "michael.laszloffy@oicr.on.ca"
    description: "bcl2barcode produces index (barcode) counts for all reads in a lane or set of lanes."
    dependencies: [
      {
        name: "bcl2fastq/2.20.0.422",
        url: "https://support.illumina.com/sequencing/sequencing_software/bcl2fastq-conversion-software.html"
      },
      {
        name: "htslib/1.9",
        url: "https://github.com/samtools/htslib"
      }
    ]
    output_meta: {
    counts: {
        description: "Gzipped and sorted index counts in csv format (count,index).",
        vidarr_label: "counts"
    }
}
  }
}

task generateIndexFastqs {
  input {
    String runDirectory # TODO: switch to "Directory" when Cromwell supports Directory symlink localization
    Array[Int] lanes
    String basesMask
    String bcl2fastq = "bcl2fastq"
    String modules = "bcl2fastq/2.20.0.422"
    Int mem = 32
    Int timeout = 6
  }

  String outputDirectory = "out"

  command <<<
    ~{bcl2fastq} \
    --runfolder-dir "~{runDirectory}" \
    --intensities-dir "~{runDirectory}/Data/Intensities/" \
    --processing-threads 8 \
    --output-dir "~{outputDirectory}" \
    --create-fastq-for-index-reads \
    --sample-sheet "/dev/null" \
    --tiles "s_[~{sep='' lanes}]" \
    --use-bases-mask "~{basesMask}" \
    --no-lane-splitting \
    --interop-dir "~{outputDirectory}/Interop"
  >>>

  output {
    File index1 = "~{outputDirectory}/Undetermined_S0_I1_001.fastq.gz"
    File? index2 = "~{outputDirectory}/Undetermined_S0_I2_001.fastq.gz"
  }

  runtime {
    memory: "~{mem} GB"
    modules: "~{modules}"
    timeout: "~{timeout}"
  }

  parameter_meta {
    runDirectory: "Illumina run directory (e.g. /path/to/191219_M00000_0001_000000000-ABCDE)."
    lanes: "A single lane or a list of lanes for no lane splitting (merging lanes)."
    basesMask: "The bases mask to produce the index reads (e.g. single 8bp index = \"Y1N*,I8,N*\", dual 8bp index = \"Y1N*,I8,I8,N*\")."
    bcl2fastq: "bcl2fastq binary name or path to bcl2fastq."
    modules: "Environment module name and version to load (space separated) before command execution."
    mem: "Memory (in GB) to allocate to the job."
    timeout: "Maximum amount of time (in hours) the task can run for."
  }

  meta {
    output_meta: {
      index1: "Index 1 fastq.gz.",
      index2: "Index 2 fastq.gz (if \"basesMask\" has specified a second index)."
    }
  }
}

 task countSingleIndex {
  input {
    File index1
    String? outputFileNamePrefix
    String bgzip = "bgzip"
    String modules = "htslib/1.9"
    Int mem = 16
    Int cores = 16
    Int timeout = 6
  }

  command <<<
    ~{bgzip} -@ ~{cores} -cd ~{index1} | \
    awk 'NR%4==2' | \
    awk '{
            counts[$0]++
    }

    END {
            for (i in counts) {
                    print counts[i] "," i
            }
    }' | \
    sort -nr | \
    gzip -n > "~{outputFileNamePrefix}counts.gz"
  >>>

  output {
    File counts = "~{outputFileNamePrefix}counts.gz"
  }

  runtime {
    memory: "~{mem} GB"
    cpu: "~{cores}"
    modules: "~{modules}"
    timeout: "~{timeout}"
  }

  parameter_meta {
    index1: "First index fastq.gz of a single index run to perform counting on."
    outputFileNamePrefix: "Output prefix to prefix output file names with."
    bgzip: "bgzip binary name or path to bgzip."
    modules: "Environment module name and version to load (space separated) before command execution."
    mem: "Memory (in GB) to allocate to the job."
    cores: "The number of cores to allocate to the job."
    timeout: "Maximum amount of time (in hours) the task can run for."
  }

  meta {
    output_meta: {
      counts: "Gzipped and sorted index counts in csv format (count,index)."
    }
  }
}

 task countDualIndex {
  input {
    File index1
    File index2
    String? outputFileNamePrefix
    String bgzip = "bgzip"
    String modules = "htslib/1.9"
    Int mem = 16
    Int cores = 16
    Int timeout = 6
  }

  command <<<
    paste -d '-' \
    <(~{bgzip} -@ ~{ceil(cores/2)} -cd ~{index1} | awk 'NR%4==2') \
    <(~{bgzip} -@ ~{floor(cores/2)} -cd ~{index2} | awk 'NR%4==2') | \
    awk '{
            counts[$0]++
    }

    END {
            for (i in counts) {
                    print counts[i] "," i
            }
    }' | \
    sort -nr | \
    gzip -n > "~{outputFileNamePrefix}counts.gz"
  >>>

  output {
    File counts = "~{outputFileNamePrefix}counts.gz"
  }

  runtime {
    memory: "~{mem} GB"
    cpu: "~{cores}"
    modules: "~{modules}"
    timeout: "~{timeout}"
  }

  parameter_meta {
    index1: "First index fastq.gz of a dual index run to perform counting on."
    index2: "Second index fastq.gz of a dual index run to perform counting on."
    outputFileNamePrefix: "Output prefix to prefix output file names with."
    bgzip: "bgzip binary name or path to bgzip."
    modules: "Environment module name and version to load (space separated) before command execution."
    mem: "Memory (in GB) to allocate to the job."
    cores: "The number of cores to allocate to the job."
    timeout: "Maximum amount of time (in hours) the task can run for."
  }

  meta {
    output_meta: {
      counts: "Gzipped and sorted index counts in csv format (count,index)."
    }
  }
}

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
}

task generateIndexFastqs {
  input {
    Int? mem = 32
    String? bcl2fastq = "bcl2fastq"
    String runDirectory # TODO: switch to "Directory" when Cromwell supports Directory symlink localization
    Array[Int] lanes
    String basesMask
    String? modules = "bcl2fastq/2.20.0.422"
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
  }
}

 task countSingleIndex {
  input {
    Int? mem = 16
    Int? cores = 16
    File index1
    String? outputFileNamePrefix
    String? bgzip = "bgzip"
    String? modules = "htslib/1.9"
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
  }
}

 task countDualIndex {
  input {
    Int? mem = 16
    Int? cores = 16
    File index1
    File index2
    String? outputFileNamePrefix
    String? bgzip = "bgzip"
    String? modules = "htslib/1.9"
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
  }
}

version 1.0

workflow bcl2barcode {
    call generateIndexFastqs
    if(defined(generateIndexFastqs.index2)) {
        call countDualIndex {
            input:
                index1 = generateIndexFastqs.index1,
                index2 = select_first([generateIndexFastqs.index2])
        }
    }
    if(!defined(generateIndexFastqs.index2)){
        call countSingleIndex {
            input:
                index1 = generateIndexFastqs.index1
        }
    }
    output {
        File counts = select_first([countSingleIndex.counts, countDualIndex.counts])
    }
 }

task generateIndexFastqs {
    input {
        Int? mem = 32
        String bcl2fastq
        String runDirectory
        String lane
        String basesMask
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
        --tiles "s_~{lane}" \
        --use-bases-mask "~{basesMask}" \
        --no-lane-splitting \
        --interop-dir "~{outputDirectory}/Interop"
    >>>

    output {
        File index1 = "~{outputDirectory}/Undetermined_S0_I1_001.fastq.gz"
        File? index2 = "~{outputDirectory}/Undetermined_S0_I2_001.fastq.gz"
    }

    runtime {
        memory: "${mem} GB"
    }
 }

 task countSingleIndex {
    input {
        Int? mem = 16
        File index1
    }

    command <<<
        zcat ~{index1} | \
        awk 'NR%4==2' | \
        sort --buffer-size 8G --parallel=24 | \
        uniq -c | \
        sort -nr | \
        awk '{ print $1 "," $2}' | \
        gzip -n > "counts.gz"
    >>>

    output {
        File counts = "counts.gz"
    }

    runtime {
        memory: "${mem} GB"
    }
 }

 task countDualIndex {
    input {
        Int? mem = 16
        File index1
        File index2
    }

    command <<<
        paste -d '-' <(zcat ~{index1} | awk 'NR%4==2') <(zcat ~{index2} | awk 'NR%4==2') | \
        sort --buffer-size 8G --parallel=24 | \
        uniq -c | \
        sort -nr | \
        awk '{ print $1 "," $2}' | \
        gzip -n > "counts.gz"
    >>>

    output {
        File counts = "counts.gz"
    }

    runtime {
        memory: "${mem} GB"
    }
 }
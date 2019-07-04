workflow test {
    call myTask
    output {
        File my_out = myTask.out
    }
 }

 task myTask {
     Int? mem = 2
     String filePrefix

     command {
         sleep 1 && echo "hello world" > ${filePrefix}.out
     }
     output {
         File out = "${filePrefix}.out"
     }

     runtime {
         memory: "${mem+2} GB"
     }
 }
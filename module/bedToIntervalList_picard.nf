/*
*   Picard BedToIntervalList
*   This module runs Picard BedToIntervalList on a BED file
*
*/
nextflow.enable.dsl=2
include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process run_BedToIntervalList_Picard {
    container params.docker_image_picard

    publishDir path: "${params.workflow_output_dir}/intermediate/${task.process.replace(':','/')}",
        pattern: "*.interval_list",
        mode: "copy",
        enabled: params.save_intermediate_files

    ext log_dir_suffix: { "-${type}" }

    input:
        tuple val(type), path(bed), path(reference_dict)

    output:
        tuple val(type), path(interval_list), emit: interval_list
        path ".command.*"

    script:
    interval_list = "${bed.getBaseName()}.interval_list"

    """
    set -euo pipefail

    java \"-Xmx${(task.memory * params.jvm_fraction).getMega()}M\" \
    -jar /usr/local/share/picard-slim-${params.picard_version}-0/picard.jar \
        BedToIntervalList \
        --INPUT ${bed} \
        --OUTPUT ${interval_list} \
        --SEQUENCE_DICTIONARY $reference_dict \
        --SORT false

    """
}

/*
*   SAMtools stats
*   This module runs SAMtools stats on a BAM file
*
*/
log.info """\
====================================
    S A M T O O L S   S T A T S
====================================
Docker Images:
- docker_image_SAMtools: ${params.docker_image_samtools}
====================================
"""

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process run_stats_SAMtools {
    container params.docker_image_samtools

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "*stats.txt",
        mode: "copy",
        enabled: true

    publishDir path: "${params.workflow_log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}-${id}/log${file(it).getName()}" }

    input:
        tuple val(orig_id), val(id), path(path), val(sample_type)

    output:
        path "*stats.txt"
        path ".command.*"

    script:
    output_filename = generate_standard_filename("SAMtools-${params.samtools_version}",
        params.dataset_id,
        id,
        [:])
    rmdups = params.remove_duplicates ? "--remove-dups" : ""

    """
    set -euo pipefail
    samtools stats ${rmdups} ${params.samtools_stats_additional_options} ${path} > ${output_filename}_stats.txt
    """
}

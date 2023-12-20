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

process stats_SAMtools {
    container params.docker_image_samtools

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "*stats.txt",
        mode: "copy",
        enabled: true

    publishDir path: "${params.workflow_log_output_dir}/${task.process.split(':')[-1]}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    input: 
        tuple val(orig_id), val(id), path(path), val(sample_type)

    output:
        path "*stats.txt", emit: stats
        path ".command.*"

    script:
    output_filename = generate_standard_filename("Samtools-${params.samtools_version}",
        params.dataset_id,
        id,
        [:])

    """
    set -euo pipefail
    samtools stats --threads ${task.cpus} ${path} > ${output_filename}_stats.txt
    """
}

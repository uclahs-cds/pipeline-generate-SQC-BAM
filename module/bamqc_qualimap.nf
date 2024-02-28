/*
*   Qualimap bamqc
*   This module runs Qualimap's QC analysis for a BAM file
*/
log.info """\
=====================================
            B A M Q C
=====================================
Docker Images:
- docker_image_Picard: ${params.docker_image_qualimap}
====================================
"""

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process run_bamqc_Qualimap {
    container params.docker_image_qualimap

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "*_stats",
        mode: "copy",
        enabled: true

    publishDir path: "${params.workflow_log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}-${id}/log${file(it).getName()}" }

    input:
        tuple val(orig_id), val(id), path(path), val(sample_type)

    output:
        path "*_stats", emit: stats
        path ".command.*"

    script:
    output_filename = generate_standard_filename("Qualimap-${params.qualimap_version}",
        params.dataset_id,
        id,
        [:])

    """
    set -euo pipefail
    qualimap bamqc \
        --java-mem-size=${(task.memory * params.jvm_fraction).getMega()}M \
        -bam ${path} \
        -nt ${task.cpus} \
        -c \
        ${params.bamqc_additional_options}
    """
}

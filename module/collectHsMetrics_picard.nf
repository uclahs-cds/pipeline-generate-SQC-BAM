/*
*   Picard CollectHsMetrics
*   This module runs Picard CollectHsMetrics on a BAM file
*
*/
log.info """\
====================================
C O L L E C T   H S   M E T R I C S
====================================
Docker Images:
- docker_image_Picard: ${params.docker_image_picard}
====================================
"""

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process run_CollectHsMetrics_Picard {
    container params.docker_image_picard

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "*HsMetrics.txt",
        mode: "copy",
        enabled: true

    publishDir path: "${params.workflow_log_output_dir}}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    input: 
        tuple val(orig_id), val(id), path(path), val(sample_type)

    output:
        path "*", emit: metrics
        path ".command.*"

    script:
    output_filename = generate_standard_filename("Picard-${params.picard_version}",
        params.dataset_id,
        id,
        [:])

    """
    set -euo pipefail
    java -Xmx${(task.memory).getMega()}m \
        -jar /usr/local/share/picard-slim-${params.picard_version}-0/picard.jar \
        CollectHsMetrics \
        INPUT=${path} \
        BAIT_INTERVALS=${params.bait_intervals} \
        TARGET_INTERVALS=${params.target_intervals} \
        OUTPUT=${output_filename}_HsMetrics.txt \
        COVERAGE_CAP=${params.hs_coverage_cap} \
        TMP_DIR=/scratch/${SLURM_JOB_ID}
    """
}

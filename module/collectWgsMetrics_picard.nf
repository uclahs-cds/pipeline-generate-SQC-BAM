/*
*   Picard CollectWgsMetrics
*   This module runs Picard CollectWgsMetrics on a BAM file
*
*/
log.info """\
=====================================
C O L L E C T   W G S   M E T R I C S
=====================================
Docker Images:
- docker_image_Picard: ${params.docker_image_picard}
====================================
"""

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process run_CollectWgsMetrics_Picard {
    container params.docker_image_picard

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "*WgsMetrics.txt",
        mode: "copy",
        enabled: true

    publishDir path: "${params.workflow_log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    input: 
        tuple val(orig_id), val(id), path(path), val(sample_type)
        path reference
        path reference_index

    output:
        path "*WgsMetrics.txt"
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
        CollectWgsMetrics \
        INPUT=${path} \
        OUTPUT=${output_filename}_WgsMetrics.txt \
        REFERENCE_SEQUENCE=${reference} \
        COVERAGE_CAP=${params.cwm_coverage_cap} \
        MINIMUM_MAPPING_QUALITY=${params.cwm_minimum_mapping_quality} \
        MINIMUM_BASE_QUALITY=${params.cwm_minimum_base_quality} \
        READ_LENGTH=${params.read_length} \
        TMP_DIR=${params.work_dir} \
        ${params.cwm_additional_options}
    """
}

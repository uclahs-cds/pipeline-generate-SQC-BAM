/*
*   Qualimap bamqc
*   This module runs Qualimap's QC analysis for a BAM file
*/

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
        saveAs: { "${task.process.replace(':', '/')}-${sm_id}/log${file(it).getName()}" }

    input:
        tuple path(path), val(unused), val(sm_id), val(unused), val(unused), val(unused), val(unused), val(unused)

    output:
        path "*_stats", emit: stats
        path ".command.*"

    script:
    output_filename = generate_standard_filename("Qualimap-${params.qualimap_version}",
        params.dataset_id,
        sm_id,
        [:])

    """
    set -euo pipefail
    qualimap bamqc \
        --java-mem-size=${(task.memory * params.jvm_fraction).getMega()}M \
        -bam ${path} \
        -outdir ${output_filename}_stats \
        -outformat ${params.bamqc_outformat} \
        -outfile ${output_filename} \
        -nt ${task.cpus} \
        -c \
        ${params.bamqc_additional_options}
    """
}

/*
*   Nextflow module for running FASTQC
*
*   @input fq_path path path to the input FASTQ file
*   @output fastqc_output_dir dir unzipped FASTQC output directory
*/

include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'

process assess_ReadQuality_FastQC {
    container params.docker_image_fastqc

    publishDir path: "${params.workflow_output_dir}/output",
        pattern: "${output_filename}",
        mode: "copy",
        enabled: true
    ext log_dir_suffix: { "-${sm_id}" }

    input:
        tuple path(path), val(unused), val(sm_id), val(rg_arg), val(unused), val(unused), val(unused), val(read_length)

    output:
        path("${output_filename}")

    script:
    output_filename = generate_standard_filename("FastQC-${params.fastqc_version}",
        params.dataset_id,
        sm_id,
        [:])

    """
    set -euo pipefail
    mkdir "${output_filename}"
    fastqc \
        --outdir "${output_filename}" \
        --threads ${task.cpus} \
        --format bam \
        --extract \
        --delete \
        ${params.fastqc_additional_options} \
        ${path}
    """
}

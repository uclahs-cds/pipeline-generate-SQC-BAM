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
    ext log_dir_suffix: { "-${target}" }

    input:
        tuple path(path), val(unused), val(sm_id), val(rg_arg), val(rg_id), val(unused), val(unused), val(ununsed)

    output:
        path("${output_filename}")

    script:
    target = "${sm_id}-${rg_id}"
    output_filename = generate_standard_filename("FastQC-${params.fastqc_version}",
        params.dataset_id,
        target,
        [:])

    """
    set -euo pipefail
    mkdir "${output_filename}"
    samtools view -F 0x900 -h ${rg_arg} ${path} | \
        samtools fastq | \
        fastqc \
        --outdir "./" \
        --format fastq \
        --extract \
        --delete \
        ${params.fastqc_additional_options} \
        stdin:${output_filename}
    """
}

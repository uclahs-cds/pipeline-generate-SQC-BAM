#!/usr/bin/env nextflow

nextflow.enable.dsl=2
include { generate_standard_filename } from './external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'
include { run_validate_PipeVal } from './external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
    options: [
        docker_image_version: params.pipeval_version,
        main_process: "./" //Save logs in <log_dir>/process-log/run_validate_PipeVal
        ]
    )

log.info """\
    ------------------------------------
    S Q C - D N A  P I P E L I N E
    ------------------------------------
    Boutros Lab

    Current Configuration:
    - pipeline:
        name: ${workflow.manifest.name}
        version: ${workflow.manifest.version}

    - input:
        dataset_id: ${params.dataset_id}
        patient_id: ${params.patient_id}
        tumor: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['path']}
        normal: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['path']}
        reference: ${params.reference}

    - output:
        output_dir: ${params.output_dir_base}
        log_output_dir: ${params.log_output_dir}

    - option:
        ucla_cds: ${params.ucla_cds}
        save_intermediate_files: ${params.save_intermediate_files}
        docker_container_registry: ${params.docker_container_registry}

    - sample names extracted from input BAM files and sanitized:
        tumor_in: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['orig_id']}
        tumor_out: ${params.samples_to_process.findAll{ it.sample_type == 'tumor' }['id']}
        normal_in: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['orig_id']}
        normal_out: ${params.samples_to_process.findAll{ it.sample_type == 'normal' }['id']}
"""

params.reference_index = "${params.reference}.fai"
params.reference_dict = "${file(params.reference).parent / file(params.reference).baseName}.dict"

include { stats_SAMtools } from './module/stats_samtools' addParams(
    workflow_output_dir: "${params.output_dir_base}/Stats_SAMtools-${params.samtools_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/Stats_SAMtools-${params.samtools_version}",
    )

// Returns the index file for the given bam or vcf
def indexFile(bam_or_vcf) {
    if(bam_or_vcf.endsWith('.bam')) {
        return "${bam_or_vcf}.bai"
        }
    else if(bam_or_vcf.endsWith('vcf.gz')) {
        return "${bam_or_vcf}.tbi"
        }
    else {
        throw new Exception("Index file for ${bam_or_vcf} file type not supported. Use .bam or .vcf.gz files.")
        }
    }


Channel
    .fromList(params.samples_to_process)
    .map { sample ->
        return tuple(sample.orig_id, sample.id, sample.path, sample.sample_type)
    }
    .set { samplesToProcessChannel }


workflow {
    // Input file validation
    Channel
        .fromList(params.samples_to_process)
        .map{ it -> [it['path'], indexFile(it['path'])] }
        .flatten()
        .set { files_to_validate_ch }

    reference_ch = Channel.from(
        params.reference,
        params.reference_index,
        params.reference_dict
        )

    files_to_validate_ch = files_to_validate_ch
        .mix(reference_ch)
    run_validate_PipeVal(files_to_validate_ch)
    run_validate_PipeVal.out.validation_result.collectFile(
        name: 'input_validation.txt', newLine: true,
        storeDir: "${params.output_dir_base}/validation"
        )

    stats_SAMtools(
        samplesToProcessChannel
        )
    }

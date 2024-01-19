#!/usr/bin/env nextflow

nextflow.enable.dsl=2
include { run_validate_PipeVal } from './external/pipeline-Nextflow-module/modules/PipeVal/validate/main.nf' addParams(
    options: [
        docker_image_version: params.pipeval_version,
        main_process: "./" //Save logs in <log_dir>/process-log/run_validate_PipeVal
        ]
    )
include { run_stats_SAMtools } from './module/stats_samtools' addParams(
    workflow_output_dir: "${params.output_dir_base}/SAMtools-${params.samtools_version}",
    workflow_log_output_dir: "${params.log_output_dir}/process-log/SAMtools-${params.samtools_version}"
    )

include { indexFile } from './external/pipeline-Nextflow-module/modules/common/indexFile/main.nf'

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

Channel
    .fromList(params.samples_to_process)
    .map { sample ->
        return tuple(sample.orig_id, sample.id, sample.path, sample.sample_type)
    }
    .set { samplesToProcessChannel }

Channel
    .fromList(params.samples_to_process)
    .map{ it -> [it['path'], indexFile(it['path'])] }
    .flatten()
    .set { files_to_validate_ch }

Channel
    .from(
        params.reference,
        params.reference_index,
        params.reference_dict
        )
    .set { reference_ch }

files_to_validate_ch = files_to_validate_ch
    .mix(reference_ch)

workflow {
    // Input file validation
    run_validate_PipeVal(files_to_validate_ch)
    run_validate_PipeVal.out.validation_result.collectFile(
        name: 'input_validation.txt', newLine: true,
        storeDir: "${params.output_dir_base}/validation"
        )

    run_stats_SAMtools(
        samplesToProcessChannel
        )
    }

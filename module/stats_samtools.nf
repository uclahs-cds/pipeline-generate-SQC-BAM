/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process stats_SAMtools {
    container params.docker_image_samtools

    publishDir path: "${params.workflow_output_dir}/${task.process.split(':')[-1]}",
        pattern: "*stats",
        mode: "copy",
        enabled: true

    publishDir path: "${params.workflow_log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    input: 
        tuple val(orig_id), val(id), path(path), val(sample_type)

    output:
        path "${path}.stats", emit: stats
        path ".command.*"

    script:
    """
    set -euo pipefail
    samtools stats --threads ${task.cpus} ${path} > ${path}.stats
    """
}

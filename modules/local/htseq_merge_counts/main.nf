process HTSEQ_MERGE_COUNTS {
    tag "${species}"
    label 'process_low'
    container "nfcore/dualrnaseq:dev"
    // container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
    //     ? 'https://depot.galaxyproject.org/singularity/python:3.8.3'
    //     : 'nfcore/dualrnaseq:dev'}"

    input:
    tuple val(species), path(counts)

    output:
    path("${species}_counts.txt"), emit: merged_counts

    script:
    """
    python3 ${workflow.projectDir}/bin/merge_counts.py -i ${counts.join(' ')} -o ${species}_counts.txt
    """
}

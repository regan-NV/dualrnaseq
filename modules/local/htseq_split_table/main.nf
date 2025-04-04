process HTSEQ_SPLIT_TABLE {
    tag "${meta.id}"
    label 'process_low'
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/python:3.8.3'
        : 'nfcore/dualrnaseq:dev'}"

    input:
    tuple val(meta), path(counts)
    path host_annotation_tsv
    path pathogen_annotation_tsv

    output:
    tuple val(meta), path("host_${meta.id}.tsv"), emit: host
    tuple val(meta), path("pathogen_${meta.id}.tsv"), emit: pathogen

    script:
    """
    awk 'NR==FNR { a[\$1]; next } \$1 in a' ${host_annotation_tsv} ${counts} > host_${meta.id}.tsv
    awk 'NR==FNR { a[\$1]; next } \$1 in a' ${pathogen_annotation_tsv} ${counts} > pathogen_${meta.id}.tsv
    """
}

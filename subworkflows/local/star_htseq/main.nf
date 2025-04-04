include { STAR_GENOMEGENERATE } from '../../../modules/nf-core/star/genomegenerate/main'
include { STAR_ALIGN } from '../../../modules/local/star_align_genome/main'
include { HTSEQ_COUNT } from '../../../modules/local/htseq_count'
include { HTSEQ_SPLIT_TABLE as HTSEQ_SPLIT_TABLE_EACH } from '../../../modules/local/htseq_split_table/main'
include { HTSEQ_MERGE_COUNTS} from '../../../modules/local/htseq_merge_counts/main'

workflow STAR_HTSEQ {
    take:
    ch_reads // channel: [ val(meta), [ reads ] ]
    ch_host_pathogen_fasta_genome
    ch_host_pathogen_gff
    ch_host_annotation_tsv
    ch_pathogen_annotation_tsv

    main:

    ch_versions = Channel.empty()


    // -------
    // Run create STAR index
    // -------
    STAR_GENOMEGENERATE(
        ch_host_pathogen_fasta_genome,
        ch_host_pathogen_gff,
    )
    ch_versions = ch_versions.mix(STAR_GENOMEGENERATE.out.versions)


    // -------
    // Run STAR align
    // -------
    STAR_ALIGN(
        ch_reads,
        STAR_GENOMEGENERATE.out.index,
        ch_host_pathogen_gff,
        true,
        '',
        '',
    )
    ch_versions = ch_versions.mix(STAR_ALIGN.out.versions)


    // -------
    // Run HTSeq-count
    // -------
    if (params.run_htseq) {

        HTSEQ_COUNT(
            STAR_ALIGN.out.bam_sorted,
            ch_host_pathogen_gff,
        )
        ch_versions = ch_versions.mix(HTSEQ_COUNT.out.versions.first())
    }

    // -------
    // Split each count table into host and pathogen reads (for each dataset)
    // -------
    HTSEQ_SPLIT_TABLE_EACH(HTSEQ_COUNT.out.counts,
                            ch_host_annotation_tsv,
                            ch_pathogen_annotation_tsv
                            )


    // Then extract files and collect them
    host_files = HTSEQ_SPLIT_TABLE_EACH.out.host
        .map { meta, file -> file }
        .collect()

    pathogen_files = HTSEQ_SPLIT_TABLE_EACH.out.pathogen
        .map { meta, file -> file }
        .collect()


    // Create a more explicit merge channel
    host_channel = host_files.map { files -> tuple("host", files) }
    pathogen_channel = pathogen_files.map { files -> tuple("pathogen", files) }


    // Combine them
    merged_channel = host_channel.mix(pathogen_channel)

    // Then use merged_channel as input for HTSEQ_MERGE_COUNTS
    HTSEQ_MERGE_COUNTS(merged_channel)

    // -------
    //  Capture the number of counted reads by HTSeq and save as output
    // -------

    emit:
    versions = ch_versions // channel: [ versions.yml ]
}

//
// Check input samplesheet and get read channels
//
include { FASTQC }                                     from '../../modules/nf-core/fastqc/main'
include { PICARD_COLLECTRNASEQMETRICS }                from '../../modules/nf-core/picard/collectrnaseqmetrics/main'
include { GATK4_MARKDUPLICATES }                       from '../../modules/nf-core/gatk4/markduplicates/main'
include { PICARD_COLLECTINSERTSIZEMETRICS }            from '../../modules/nf-core/picard/collectinsertsizemetrics/main'
include { SAMTOOLS_FLAGSTAT }                          from '../../modules/nf-core/samtools/flagstat/main'

workflow QC_WORKFLOW {
    take:
        ch_bam_sorted
        ch_bam_sorted_indexed
        ch_refflat
        ch_fasta
        ch_fai
        ch_rrna_interval

    main:
        ch_versions = Channel.empty()

        FASTQC (
         ch_bam_sorted
        )
        ch_versions = ch_versions.mix(FASTQC.out.versions.first())
        ch_fastqc_zip = Channel.empty().mix(FASTQC.out.zip)

        PICARD_COLLECTRNASEQMETRICS(ch_bam_sorted,
                                    ch_refflat.map { meta, refflat -> [ refflat ]},
                                    ch_fasta.map { meta, fasta -> [ fasta ]},
                                    ch_rrna_interval.map { meta, rrna_interval -> [ rrna_interval ]})
        ch_versions = ch_versions.mix(PICARD_COLLECTRNASEQMETRICS.out.versions)
        ch_rnaseq_metrics = Channel.empty().mix(PICARD_COLLECTRNASEQMETRICS.out.metrics)

        GATK4_MARKDUPLICATES(ch_bam_sorted, ch_fasta.map { meta, fasta -> [ fasta ]}, ch_fai.map { meta, fasta_fai -> [ fasta_fai ]})
        ch_versions = ch_versions.mix(GATK4_MARKDUPLICATES.out.versions)
        ch_duplicate_metrics = Channel.empty().mix(GATK4_MARKDUPLICATES.out.metrics)

        PICARD_COLLECTINSERTSIZEMETRICS(ch_bam_sorted)
        ch_versions = ch_versions.mix(PICARD_COLLECTINSERTSIZEMETRICS.out.versions)
        ch_insertsize_metrics = Channel.empty().mix(PICARD_COLLECTINSERTSIZEMETRICS.out.metrics)

        SAMTOOLS_FLAGSTAT(ch_bam_sorted_indexed)
        ch_versions = ch_versions.mix(SAMTOOLS_FLAGSTAT.out.versions)
        ch_flagstat_metrics = Channel.empty().mix(SAMTOOLS_FLAGSTAT.out.flagstat)


    emit:
        versions            = ch_versions
        rnaseq_metrics      = ch_rnaseq_metrics
        duplicate_metrics   = ch_duplicate_metrics
        insertsize_metrics  = ch_insertsize_metrics
        samtools_metrics    = ch_flagstat_metrics
        fastqc_zip          = ch_fastqc_zip

}


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    PRINT PARAMS SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryLog; paramsSummaryMap } from 'plugin/nf-validation'

def logo = NfcoreTemplate.logo(workflow, params.monochrome_logs)
def citation = '\n' + WorkflowMain.citation(workflow) + '\n'
def summary_params = paramsSummaryMap(workflow)

// Print parameter summary log to screen
log.info logo + paramsSummaryLog(workflow) + citation

WorkflowRnaqc.initialise(params, log)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { QC_WORKFLOW } from '../subworkflows/local/qc_workflow'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
include { SAMTOOLS_INDEX              } from '../modules/nf-core/samtools/index/main'
include { MULTIQC                     } from '../modules/nf-core/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/custom/dumpsoftwareversions/main'


//
// PARAMETERS: Given by user
//
// Check mandatory parameters
 if (file(params.input).exists() || params.build_references) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet does not exist or was not specified!' }

 ch_fasta = Channel.fromPath(params.fasta).map { it -> [[id:it.Name], it] }.collect()
 ch_fai = Channel.fromPath(params.fai).map { it -> [[id:it.Name], it] }.collect()
 ch_gtf = Channel.fromPath(params.gtf).map { it -> [[id:it.Name], it] }.collect()
 ch_refflat = Channel.fromPath(params.refflat).map { it -> [[id:it.Name], it] }.collect()
 ch_rrna_interval = Channel.fromPath(params.rrna_intervals).map { it -> [[id:it.Name], it] }.collect()


 def checkPathParamList = [
     params.fasta,
     params.fai,
     params.gtf,
     params.ch_refflat,
     params.ch_rrna_interval,
 ]

 for (param in checkPathParamList) if ((param) && !params.build_references) file(param, checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow RNAQC {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //

    // Branch out input channel depending on bai presence
    INPUT_CHECK (
        file(params.input)
    )
    .reads
    .branch {
        meta, bam_bai ->
            indexed  : meta.indexed == true
                return [ meta, bam_bai[0], bam_bai[1] ]
            noindexed: meta.indexed == false
                return [ meta, bam_bai[0] ]
    }
    .set { ch_bam }
	ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)

    SAMTOOLS_INDEX(ch_bam.noindexed)

    ch_bam.noindexed
        .join(SAMTOOLS_INDEX.out.bai, by: [0], remainder: true)
        .join(SAMTOOLS_INDEX.out.csi, by: [0], remainder: true)
        .map {
            meta, bam, bai, csi ->
                if (bai) {
                    [ meta, bam, bai ]
                } else {
                    [ meta, bam, csi ]
                }
        }
        .set { ch_bam_bai }

    ch_bam_bai = ch_bam.indexed.mix(ch_bam_bai)

    ch_bam = ch_bam_bai.map{meta, bam,bai -> [meta, bam]}

    ch_versions = ch_versions.mix(INPUT_CHECK.out.versions)


    // RUN QC on BAMs

     QC_WORKFLOW (
         ch_bam,
         ch_bam_bai,
         ch_refflat,
         ch_fasta,
         ch_fai,
         ch_rrna_interval
     )
     ch_versions = ch_versions.mix(QC_WORKFLOW.out.versions)


     CUSTOM_DUMPSOFTWAREVERSIONS (
         ch_versions.unique().collectFile(name: 'collated_versions.yml')
     )

    //
    // MODULE: MultiQC
    //
     workflow_summary    = WorkflowRnaqc.paramsSummaryMultiqc(workflow, summary_params)
     ch_workflow_summary = Channel.value(workflow_summary)

     methods_description    = WorkflowRnaqc.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description, params)
     ch_methods_description = Channel.value(methods_description)

     ch_multiqc_files = Channel.empty()
     ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
     ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
     ch_multiqc_files = ch_multiqc_files.mix(QC_WORKFLOW.out.rnaseq_metrics.collect{it[1]}.ifEmpty([]))
     ch_multiqc_files = ch_multiqc_files.mix(QC_WORKFLOW.out.duplicate_metrics.collect{it[1]}.ifEmpty([]))
     ch_multiqc_files = ch_multiqc_files.mix(QC_WORKFLOW.out.insertsize_metrics.collect{it[1]}.ifEmpty([]))
     ch_multiqc_files = ch_multiqc_files.mix(QC_WORKFLOW.out.samtools_metrics.collect{it[1]}.ifEmpty([]))
     ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
     ch_multiqc_files = ch_multiqc_files.mix(QC_WORKFLOW.out.fastqc_zip.collect{it[1]}.ifEmpty([]))

     MULTIQC (
         ch_multiqc_files.collect(),
         ch_multiqc_config.toList(),
         ch_multiqc_custom_config.toList(),
         ch_multiqc_logo.toList()
     )
     multiqc_report = MULTIQC.out.report.toList()
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.dump_parameters(workflow, params)
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.IM_notification(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

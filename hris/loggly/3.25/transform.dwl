%dw 2.0 import * from dw::core::Strings import * from intellihr

var hp: String                = 'envt-mitre10-hris-process'
var ha: String                = 'envt-mitre10-hris-api'
var m10c: String              = 'envt-m10-common-services'

var se_Event_Search: String   = ' AND ("Received webhook event to process for intelliHR" OR "Started webhook event from intellihr event: " OR "environment HR Event is" OR "Completed webhook event from intellihr event: " OR "dynamic_template_data")'
var se_Papi: String           = ' AND ("Received webhook event to process for intelliHR" OR "Completed webhook event from intellihr event: ")'

var se_Webhooks_Del: String   = [
"form.completed",
"person.updated",
"job.created",
"job.update_scheduled",
"job.company_start_date_upcoming",
"job.timeline_updated",
"job.end_date_finalised",
"job.ended",
"job.end_date_adjusted",
"job.end_date_cancelled",
"job.end_date_finalised",
] map wrapWith($, "'") joinBy " OR "

var se_Papi_Webhooks : String = ' AND ("Received webhook event to process for intelliHR" AND ("form.completed" OR "person.updated" OR "job.created" OR "job.update_scheduled" OR "job.company_start_date_upcoming" OR "job.timeline_updated" OR "job.end_date_finalised" OR "job.ended" OR "job.end_date_adjusted" OR "job.end_date_cancelled" OR "job.end_date_finalised"))'

var se_Azure_AD: String       = ' AND ("starting to process hr event for Azure AD" OR "completed hr event processing to Azure AD" OR "completed DLQ hr event processing to Azure AD")'

var se_HF: String             = ' AND ("starting to process HR Event for Humanforce" OR "completed processing HR Event to Humanforce" OR "completed DLQ hr event processing to Humanforce")'

var se_OnPrem_AD: String      = ' AND ("starting to process hr event for On Prem AD" OR "completed hr event processing to On Prem AD" OR "completed DLQ hr event processing to On Prem AD" OR "PowerShell script execution failure")'

var se_Hris_Api: String       = ' AND ("POST request to Mitre10 HRIS Process API started" OR "POST request to Mitre10 HRIS Process API ended")'

var se_PG: String             = ' AND ("starting to process hr event for Payglobal" OR "completed hr event processing to Payglobal" OR "completed DLQ hr event processing to Payglobal" OR "successfully transferred CSV file with filename")'

var se_IDM: String            = ' AND ("Starting to process HRIS outbound message for SAP IdM" OR "Finishing to process HRIS outbound message to SAP IdM for employee id" OR " Create Payload for IdM is " OR "Skipping Employee Update as the employee found to not exist in IdM and in this process is created in IdM for employee id" OR " Data from IdM is " OR " Update Payload for IdM for combined call is " OR "Starting flow to process HRIS outbound message DLQ Amazon SQS to raise alert" OR "Finishing flow to process HRIS outbound message DLQ Amazon SQS to raise alert successfully")'

var integ_completed           = '("Completed webhook event from intellihr event: " OR "completed processing HR Event to Humanforce" OR "completed hr event processing to Azure AD" OR "completed hr event processing to On Prem AD" OR "Finishing to process HRIS outbound message to SAP IdM for employee id " OR "completed hr event processing to Payglobal" OR "Completed processing HR Event to Learning Management System (LMS). HR Event received with action ")'

var job: String               = jobUrl as String default ''

var empId: String             = (if ( sizeOf (employeeId as String default '') < 2) (if ( substringAfter ( job, 'https://' ) contains ':') ( substringAfter ( substringAfter ( job, 'https://' ), ':') ) else '') else employeeId) as String default ''

var corrId: String            = correlationId as String default ''

var mode: String              = env as String default 'p'

var envt: String              = if ( lower (mode) startsWith 'p') 'prod' else if ( lower (mode) startsWith 't') 'test' else 'prod'

var personId: String          = substringBefore ( substringAfter ( job, 'intellihr.net/spa/people/' ), '/jobs/' )

var jobId: String             = substringBefore ( substringAfter ( job, '/jobs/' ), '/' )

var heading: String           = '    Loggly queries for:   '++ (if (lower(mode) startsWith 'p') 'Production' else if (lower(mode) startsWith 't') 'Test' else '') ++'\n========================================\n'++'     Person Id:  '++ personId ++'\n' ++ '        Job Id:  '++ jobId ++'\n' ++ 'Form Design Id:  '++ jobId ++'\n'++'   Employee Id:  '++ empId ++'\n'++'Correlation Id:  '++ corrId ++'\n'

fun c(): String               = if(isBlank(corrId)) '' else (' AND "'++ corrId ++'"')

fun p (arg1, arg2): String    = '\n' ++ '   ' ++ arg1 ++ ':\n----------------------------------------\n' ++ (arg2 replace 'envt' with envt) ++ '\n'

fun parr (arg1, arg2: Array<String>): String = '\n' ++ '>   ' ++ arg1 ++ ':\n----------------------------------------\n' ++ ((arg2 joinBy '') replace 'envt' with envt) ++ '\n'

fun pje (): String            = do { if ( isBlank (empId) or ( sizeOf (empId) < 2 )) ('"'++ personId ++'" OR "'++ jobId ++'" OR "'++ formDesignId ++'"') else ('"'++ personId ++'" OR "'++ jobId ++'" OR "'++ formDesignId ++'" OR "'++ empId ++'"') }

fun f(footer: String): String = do {if (lower(se) startsWith 'n') '' else footer}

fun appendix1(): String       = do {
"\n"
++ "\n\t'<': '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< d1 start',"
++ "\n\t'd1_a0': 0,"
++ "\n\t'd1_a1': 1,"
++ "\n\t'd1_a2': 2,"
++ "\n\t'd1_a3': 3,"
++ "\n\t'd1_a4': 4,"
++ "\n\t'd1_a5': 5,"
++ "\n\t'd1_a6': 6,"
++ "\n\t'd1_a7': 7,"
++ "\n\t'd1_a8': 8,"
++ "\n\t'd1_a9': 9,"
++ "\n\t'd1_b0': 0,"
++ "\n\t'd1_b1': 1,"
++ "\n\t'd1_b2': 2,"
++ "\n\t'd1_b3': 3,"
++ "\n\t'd1_b4': 4,"
++ "\n\t'd1_b5': 5,"
++ "\n\t'd1_b6': 6,"
++ "\n\t'd1_b7': 7,"
++ "\n\t'd1_b8': 8,"
++ "\n\t'd1_b9': 9,"
++ "\n\t'>': '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   d1 end',"

++ "\n"
++ "\n\t'___'                           :   '_________________________________________________',"
++ "\n\t'---'                           :   '-------------------------------------------------',"
++ "\n\t'==='                           :   '=================================================',"
++ "\n\t'~~~'                           :   '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',"
++ "\n\t'***'                           :   '*************************************************',"
++ "\n\t'###'                           :   '#################################################',"
++ "\n\t'+++'                           :   '+++++++++++++++++++++++++++++++++++++++++++++++++',"
++ "\n\t'^^^'                           :   '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^',"
++ "\n\t'```'                           :   '`````````````````````````````````````````````````',"
++ "\n\t'...'                           :   '.................................................',"
++ "\n\t'<<<'                           :   '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<',"
++ "\n\t'>>>'                           :   '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>',"
++ "\n\t'((('                           :   '(((((((((((((((((((((((((((((((((((((((((((((((((',"
++ "\n\t')))'                           :   ')))))))))))))))))))))))))))))))))))))))))))))))))',"
++ "\n\t'[[['                           :   '[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[',"
++ "\n\t']]]'                           :   ']]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]',"
++ "\n\t'//'                            :   '/////////////////////////////////////////////////',"
++ "\n\t'\\\\'                            :   '\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\',"
++ "\n\t'|||'                           :   '|||||||||||||||||||||||||||||||||||||||||||||||||',"
++ "\n\t'111'                           :   '1111111111111111111111111111111111111111111111111',"
++ "\n\t'222'                           :   '2222222222222222222222222222222222222222222222222',"
++ "\n\t'333'                           :   '3333333333333333333333333333333333333333333333333',"
++ "\n\t',,,'                           :   ',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,',"
++ "\n\t';;;'                           :   ';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;',"
++ "\n\t':::'                           :   ':::::::::::::::::::::::::::::::::::::::::::::::::',"
    
++ "\n"
++ "\n\t'-': '------------------------------------------------- d1 start',"
++ "\n\t'-': '-------------------------------------------------   d1 end',"
    
++ "\n"
++ "\n\t'_': '_________________________________________________ d1 start',"
++ "\n\t'_': '_________________________________________________   d1 end',"
++ "\n\t'^': '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   d1 end',"
    
++ "\n"
++ "\n\t'=': '================================================= d1 start',"
++ "\n\t'=': '=================================================   d1 end',"
    
++ "\n"
++ "\n\t'<': '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< d1 start',"
++ "\n\t'>': '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   d1 end',"
    
++ "\n"
++ "\nIntelliHR Webhooks are:"
++ "\n-----------------------"
++ "\n'form.completed'"
++ "\n'person.updated'"
++ "\n'job.created'"
++ "\n'job.update_scheduled'"
++ "\n'job.company_start_date_upcoming'"
++ "\n'job.timeline_updated'"
++ "\n'job.end_date_finalised'"
++ "\n'job.ended'"
++ "\n'job.end_date_adjusted'"
++ "\n'job.end_date_cancelled'"
++ "\n'job.end_date_finalised'"
}

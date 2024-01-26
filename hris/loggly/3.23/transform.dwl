//-------------------------------------------------------------------------------------------- Input Start
var jobUrl        = ''
var employeeId    = 0
var correlationId = ''
var env           = 'production'    // env - starts with p or t (default p == production)
var se            = 'yes'    // se == starts with y or n (default y == yes) - to add start and end strings from target system integration logs added in the end of loggly search string via footer function f(footer)
//-------------------------------------------------------------------------------------------- Input End
/*
var jobUrl        = 'https://mitre10nz-uat3.intellihr.net/spa/people/4026d00c-945c-4e43-8fe8-61fecaa93211/jobs/15ccedeb-7c02-4d1f-9612-4bc93fd1c63b/current:720089'
var jobUrl        = 'intellihr.net/people/Person-Id/jobs/Job-Id/current:<intelliHR-Id>'
*/
import * from dw::core::Strings output text/plain //output application/json
var hp                = 'envt-mitre10-hris-process'
var ha                = 'envt-mitre10-hris-api'
var m10c              = 'envt-m10-common-services'
var se_Event_Search   = ' AND ("Started webhook event from intellihr event: " OR "Received webhook event to process" OR "environment HR Event is" OR "Completed webhook event from intellihr event: " OR "dynamic_template_data")'
var se_Papi           = ' AND ("Received webhook event to process" OR "Completed webhook event from intellihr event: ")'
var se_Azure_AD       = ' AND ("starting to process hr event for Azure AD" OR "completed hr event processing to Azure AD" OR "completed DLQ hr event processing to Azure AD")'
var se_HF             = ' AND ("starting to process HR Event for Humanforce" OR "completed processing HR Event to Humanforce" OR "completed DLQ hr event processing to Humanforce")'
var se_OnPrem_AD      = ' AND ("starting to process hr event for On Prem AD" OR "completed hr event processing to On Prem AD" OR "completed DLQ hr event processing to On Prem AD" OR "PowerShell script execution failure")'
var se_Hris_Api       = ' AND ("POST request to Mitre10 HRIS Process API started" OR "POST request to Mitre10 HRIS Process API ended")'
var se_PG             = ' AND ("starting to process hr event for Payglobal" OR "completed hr event processing to Payglobal" OR "completed DLQ hr event processing to Payglobal" OR "successfully transferred CSV file with filename")'
var se_IDM            = ' AND ("Starting to process HRIS outbound message for SAP IdM" OR "Finishing to process HRIS outbound message to SAP IdM for employee id" OR " Create Payload for IdM is " OR "Skipping Employee Update as the employee found to not exist in IdM and in this process is created in IdM for employee id" OR " Data from IdM is " OR " Update Payload for IdM for combined call is " OR "Starting flow to process HRIS outbound message DLQ Amazon SQS to raise alert" OR "Finishing flow to process HRIS outbound message DLQ Amazon SQS to raise alert successfully")'
var integ_completed   = '("Completed webhook event from intellihr event: " OR "completed processing HR Event to Humanforce" OR "completed hr event processing to Azure AD" OR "completed hr event processing to On Prem AD" OR "Finishing to process HRIS outbound message to SAP IdM for employee id " OR "completed hr event processing to Payglobal" OR "Completed processing HR Event to Learning Management System (LMS). HR Event received with action ")'
var job               = jobUrl as String default ''
var empId             = (if ( sizeOf (employeeId as String default '') < 2) (if ( substringAfter ( job, 'https://' ) contains ':') ( substringAfter ( substringAfter ( job, 'https://' ), ':') ) else '') else employeeId) as String default ''
var corrId            = correlationId as String default ''
var mode              = env as String default 'p'
var envt              = if ( lower (mode) startsWith 'p') 'prod' else if ( lower (mode) startsWith 't') 'test' else 'prod'
var personId          = substringBefore ( substringAfter ( job, 'intellihr.net/spa/people/' ), '/jobs/' )
var jobId             = substringBefore ( substringAfter ( job, '/jobs/' ), '/' )
var heading           = '    Loggly queries for:   '++ (if (lower(mode) startsWith 'p') 'Production' else if (lower(mode) startsWith 't') 'Test' else '') ++'\n========================================\n'++'     Person:  '++ personId ++'\n' ++ '        Job:  '++ jobId ++'\n'++'   Employee:  '++ empId ++'\n'++'Correlation:  '++ corrId ++'\n'
fun c()               = if(isBlank(corrId)) '' else (' AND "'++ corrId ++'"')
fun p (arg1, arg2)    = '\n' ++ '   ' ++ arg1 ++ ':\n----------------------------------------\n' ++ (arg2 replace 'envt' with envt) ++ '\n'
fun parr (arg1, arg2: Array<String>)    = '\n' ++ '   ' ++ arg1 ++ ':\n----------------------------------------\n' ++ ((arg2 joinBy '') replace 'envt' with envt) ++ '\n'
fun pje ()            = do { if ( isBlank (empId) or ( sizeOf (empId) < 2 )) ('"'++ personId ++'" OR "'++ jobId ++'"') else ('"'++ personId ++'" OR "'++ jobId ++'" OR "'++ empId ++'"') }
fun f(footer: String) = do {if (lower(se) startsWith 'n') '' else footer}
---
heading ++

parr('Person or Job Event Search Started Completed to get Correlation ID', ['"', hp, '" AND (', pje(), ')', f(se_Papi)]) ++ 

parr('Event Search with Person or Job Event', ['"', hp, '" AND (', pje(), ')', f(se_Event_Search)]) ++ 

parr('Event Search with Correlation Id', ['"', hp, '"', c(), f(se_Event_Search)]) ++ 

parr('Get HR Event with Person or Job Event', ['"', hp, '" AND "hris-webhook:" AND "environment HR Event is" AND (', pje(), ')']) ++ 

parr('Get HR Event with Correlation Id', ['"', hp, '" AND "hris-webhook:" AND "environment HR Event is"', c()]) ++ 

parr('SendGrid Email Template', ['"', hp, '" AND ("dynamic_template_data" AND "errorCode")', c()]) ++ 

parr('Integrations Completed', ['"', hp, '" AND ', integ_completed, c()]) ++ 

parr('Event Search Old', ['"', hp, '" AND (', pje(), ')', f(se_Event_Search)]) ++ 

parr('Papi', ['"', hp, '"', c(), f(se_Papi)]) ++ 

parr('Azure AD', ['"', hp, '" AND "hris-azure-ad:" AND (', pje(), ')', f(se_Azure_AD)]) ++ 

parr('OnPrem AD', ['"', hp, '" AND "hris-on-prem-ad:"', c(), f(se_OnPrem_AD)]) ++ 

parr('Common Service', ['"', m10c, '" AND "', empId, '" AND "] action for ["']) ++ 

parr('HF', ['"', hp, '" AND "hris-humanforce:" AND (', pje(), ')', f(se_HF)]) ++ 

parr('PG', ['"', hp, '" AND "hris-payglobal:" AND (', pje(), ')', f(se_PG)]) ++ 

parr('IdM', ['"', hp, '" AND "hris-idm:" AND (', pje(), ')', f(se_IDM)]) ++ 

parr('Hris Api', ['"', ha, '"', c(), f(se_Hris_Api)])

++ '\n========================================'

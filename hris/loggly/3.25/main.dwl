%dw 2.0 import * from dw::core::Strings import * from transform output text/plain //output application/json
---
heading ++

parr('Event Search for Webhook', ['"', hp, '" AND (', pje(), ')', f(se_Papi_Webhooks)]) ++ 

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

//++ appendix1()

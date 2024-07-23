%dw 2.0

//-------------------------------------------------------------------------------------------- Input Start

var jobUrl        = ''
var employeeId    = 0
var correlationId = ''
var formDesignId  = '82f8982f-e5d2-4f86-b7eb-81884eb480d8'
var env           = 'production'	// env - starts with p or t (default p == production)
var se            = 'yes'		// se == starts with y or n (default y == yes) - to add start and end strings from target system integration logs added in the end of loggly search string via footer function f(footer)

//-------------------------------------------------------------------------------------------- Input End

/*
var jobUrl        = 'https://mitre10nz-uat3.intellihr.net/spa/people/4026d00c-945c-4e43-8fe8-61fecaa93211/jobs/15ccedeb-7c02-4d1f-9612-4bc93fd1c63b/current:720089'
var jobUrl        = 'intellihr.net/people/Person-Id/jobs/Job-Id/current:<intelliHR-Id>'
*/

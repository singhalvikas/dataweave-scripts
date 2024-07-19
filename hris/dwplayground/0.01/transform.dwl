%dw 2.0
//import * from modules::hris::commonUtil
//import * from modules::hris::hrEventUtil
//import * from modules::hris::idmUtil
//import * from modules::hris::humanForceUtil
//import * from modules::hris::EskerUtil

// Not done -> import p from Mule
// Not done -> import replaceAll from dw::core::Strings
// Not done -> import try,orElseTry,orElse from dw::Runtime
// Not done -> import from modules::hris::activeDirectoryUtil
// Not done -> import from modules::hris::payglobalUtil
// Not done -> import from modules::hris::lmsUtil
// Not done -> https://docs.mulesoft.com/dataweave/2.4/dataweave-selectors
// Not done -> https://docs.mulesoft.com/dataweave/2.4/dataweave-cookbook-extract-data
// Not done -> https://jsongrid.com/json-parser

import substringBefore,substringBeforeLast,substringAfter,substringAfterLast from dw::core::Strings
import readLinesWith from dw::core::Binaries
output application/json

var propData = prop
/*
fun p(text: String): String = do {
    var textin = text
    ---
    log('P - PROPERTIES FUN', textin)
}
*/
var propDataSepator = '='
var propDataArray = 
write (propData, 'application/octet-stream') as Binary readLinesWith (propData.^encoding as String default 'UTF-8') 
filter ((propDataArrayItem, propDataArrayIndex) -> not isBlank(propDataArrayItem))
filter ((propDataArrayItem, propDataArrayIndex) -> (propDataArrayItem contains propDataSepator))
map ((propDataArrayItem, propDataArrayIndex) -> {
    key: substringBefore(propDataArrayItem, propDataSepator),
    value: substringAfter(propDataArrayItem, propDataSepator)
})
fun p(key: String): String = (propDataArray filter ((propDataArrayItem, propDataArrayIndex) -> key ~= propDataArrayItem.key))[0].value default ''

fun substring(text: String, start: Number, until: Number): String = do {
    if(isBlank(text)) ''
    else if(start >= until) ''
    else (text splitBy '')[start to until-1] joinBy '' default ''
}
fun first(text: String, amount: Number): String = do {
    if(amount < 1) ''
    else substring(text, 0, amount)
}
fun replaceAll(text: String, regex: String, replacement: String) = do {
    text replace regex with replacement
}

fun getArrayFromProperty(propertyKey: String, separator: String = ','): Array = do {
	splitBy(p(propertyKey), separator) default []
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Common_Util_DW_Start

fun containsInvalidChars(string: String | Null, regex: Regex = /[A-Za-z0-9]/): Boolean = not isBlank(string default '' replace regex with '')

fun getArrayFromProperty(propertyKey: String, separator: String = ','): Array = do {
	splitBy(p(propertyKey), separator) default []
}

fun isSameDate(date1: String | Date | Null, date2: String | Date | Null): Boolean =  do {
	((date1 as Date {mode: "SMART"}) == (date2 as Date {mode: "SMART"})) 
	default ( (isBlank(date1) == isBlank(date2))) 
	default false
}

fun getGreaterEqualDate(firstDate: Date, secondDate: Date): Date = if (firstDate > secondDate) firstDate else secondDate

fun randomisedStringGenerator(characterSet: String, numOfChars: Number): Array<String> = do {
	var MAX_LENGTH = numOfChars - 1
	---
	((0 to MAX_LENGTH) as Array) reduce ((item, accumulator = []) -> accumulator + characterSet[sizeOf(characterSet) * random()])
}

fun generateTemporaryPassword(): String = do {
	var MAX_UPPERCASE: Number = 4
	var MAX_LOWERCASE: Number = 4
	var MAX_DIGITS: Number = 3
	var MAX_SPECIAL_CHARS: Number = 3

	var UPPER_CASE_CHARS: String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	var LOWER_CASE_CHARS: String = 'abcdefghijklmnopqrstuvwxyz'
	var DIGIT_CHARS: String = '0123456789'
	var SPECIAL_CHARS: String = '!@#%^&*-_+='

	var uppercaseCharLength = sizeOf(UPPER_CASE_CHARS)
	var lowercaseCharLength = sizeOf(LOWER_CASE_CHARS)
	var digitsLength = sizeOf(DIGIT_CHARS)
	var specialCharLength = sizeOf(SPECIAL_CHARS)

	var random_upper: Array<String> = randomisedStringGenerator(UPPER_CASE_CHARS, MAX_UPPERCASE)
	var random_lower: Array<String> = randomisedStringGenerator(LOWER_CASE_CHARS, MAX_LOWERCASE)
	var random_digit: Array<String> = randomisedStringGenerator(DIGIT_CHARS, MAX_DIGITS)
	var random_symbol: Array<String> = randomisedStringGenerator(SPECIAL_CHARS, MAX_SPECIAL_CHARS)
	---
	((random_digit ++ random_upper ++ random_lower ++ random_symbol) orderBy random()) joinBy ""
}

fun calculateRosterHours(concurrentJobs: Array):Number = do {
	var primaryJobPayPeriodCode: String = (concurrentJobs filter ((job, index) -> job.data.isPrimaryJob == true))[0].data.location.customFields.pay_period_code.value as String default ''
	var week1Total: Number = sum(concurrentJobs map ((job, index) -> job.data.customFields.week_1_total.value as Number default 0)) 
	var week2Total: Number = sum(concurrentJobs map ((job, index) -> job.data.customFields.week_2_total.value as Number default 0))
	var averageWeeklyTotal = if(week2Total > 0 ) ((week1Total + week2Total)/2) else week1Total
	var rosterHours = primaryJobPayPeriodCode match {
		case WEEKLY matches /^W.*/ -> averageWeeklyTotal
		case FORTNIGHTLY matches /^F.*/ -> averageWeeklyTotal * 2
		case MONTHLY matches /^M.*/ -> averageWeeklyTotal * 4.33
		else -> 0
	}
	---
	rosterHours as String { format: ".00"} as Number
}

fun getWeeklyTotalOrDayHours(week: Number, day: String, job: Object) = do {
	var customFieldName = 'week_'++ week ++ '_'
	var customFields = job.customFields
	---
	day match {
		case 'sunday' -> customFields[customFieldName ++ $].value default 0
		case 'monday' -> customFields[customFieldName ++ $].value default 0
		case 'tuesday' -> customFields[customFieldName ++ $].value default 0
		case 'wednesday' -> customFields[customFieldName ++ $].value default 0
		case 'thursday' -> customFields[customFieldName ++ $].value default 0
		case 'friday' -> customFields[customFieldName ++ $].value default 0
		case 'saturday' -> customFields[customFieldName ++ $].value default 0
		case 'total' -> customFields[customFieldName ++ $].value default 0
		else -> 0
	}
}

fun replaceSpecialCharacters(inputString: String | Null, startIndex = 0): String = do {
	var specialChars: Array = ['`', '@', '\$', '\'', '"']
	var replacementSpecialChars: Array = ['``', '`@', '`\$', '`\'', '`"']
	var result: String = replaceAll(inputString, specialChars[startIndex], replacementSpecialChars[startIndex])
	---
	if (startIndex >= sizeOf(specialChars) - 1)
		result
	else
		replaceSpecialCharacters(result, startIndex + 1)
}

fun getUnwrappedCode(prefix: String = '<', suffix: String = '>', code: String | Null = null): String = do {
	if(isBlank(code)) 
		'' 
	else 
		substringBeforeLast(substringAfter(code default '', prefix), suffix)
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Common_Util_DW_End

// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< HREvent_Util_DW_Start

fun getDatetimeTypeOriginal(value: String | Null) : DateTime | Null = do {
	if ( isBlank(value) ) null
	else
		((value as DateTime {mode: "SMART", format: 'uuuu-MM-dd'}))
		default ( ((value as DateTime {mode: "SMART", format: 'uuuu-MM-dd\'T\'HH:mm:ssXXX'}) >> "NZ")) 
		default ( ((value as DateTime {mode: "SMART", format: 'uuuu-MM-dd\'T\'HH:mm:ss.SSSXXX'}) >> "NZ")) 
		default ( ((value as DateTime {mode: "SMART", format: 'uuuu-MM-dd\' \'HH:mm:ssXXX'}) >> "NZ")) 
		default ( ((value as DateTime {mode: "SMART", format: 'uuuu-MM-dd\' \'HH:mm:ss.SSSXXX'}) >> "NZ")) 
		default null
}

fun getDatetimeType(value) : DateTime = do {
	if ( isBlank(value) ) value as DateTime
	else
		((value as DateTime {mode: "SMART", format: 'uuuu-MM-dd'}))
		default ( ((value as DateTime {mode: "SMART", format: 'uuuu-MM-dd\'T\'HH:mm:ssXXX'}) >> "NZ")) 
		default ( ((value as DateTime {mode: "SMART", format: 'uuuu-MM-dd\'T\'HH:mm:ss.SSSXXX'}) >> "NZ")) 
		default ( ((value as DateTime {mode: "SMART", format: 'uuuu-MM-dd\' \'HH:mm:ssXXX'}) >> "NZ")) 
		default ( ((value as DateTime {mode: "SMART", format: 'uuuu-MM-dd\' \'HH:mm:ss.SSSXXX'}) >> "NZ")) 
		default value as DateTime
}

fun applyTestPrefixIfConfigured(aStringValue: String | Null): String = do {
	var applyTestFlag: Boolean = true as Boolean // p('hris.mapping.apply.test-flag') as Boolean
	var testFlagValue: String = 'HRIS' as String // p('hris.mapping.apply.test-flag.value') as String
	---
	if ( (not isBlank(aStringValue)) and applyTestFlag and (not startsWith(lower(aStringValue as String default ''), lower(testFlagValue))) ) 
		(testFlagValue ++ (aStringValue as String default ''))
	else 
		aStringValue as String default ''
}

fun getLocationType(job: Object | Null): String = do {
	var locationType: String = job.data.location.customFields.location_type.value.label as String default ''
	var storeTypeList: Array = splitBy(('Store,Frame and Truss,Shared Services,Distribution Centre,Cafe' as String default ''), ',')
	var supportCentreTypeList: Array = splitBy(('Support Centre' as String default ''), ',')
	var mimpTypeList: Array = splitBy(('Global Sourcing Office' as String default ''), ',')
	---
	if (contains(supportCentreTypeList, locationType))
		'SUPPORT_CENTRE'
	else if (contains(storeTypeList, locationType))
		'STORE'
	else if (contains(mimpTypeList, locationType))
		'MIMP'
	else
		'UNKNOWN-' ++ locationType
}

fun deriveFirstName(person: Object | Null): String = do {
	var preferredName: String = person.data.preferredName as String default ''
	var firstName: String = person.data.firstName as String default ''
	---
	if (isEmpty(preferredName)) 
		applyTestPrefixIfConfigured(firstName)
	else 
		applyTestPrefixIfConfigured(preferredName)
}

fun cleanseStringForUPN(samAccount: String | Null): String = do {
	var allowedCharsRegex: Regex = '[^a-z0-9A-Z\\-]' as Regex
	var safeSamAccount: String = samAccount default ''
	---
	if(isBlank(safeSamAccount))
		safeSamAccount
	else
		safeSamAccount replace allowedCharsRegex with ''
}

fun deriveSAMAccountName(person: Object | Null): String = do {
    var MAX_SIZE: Number = 20 as Number
	var preferredName: String = cleanseStringForUPN(person.data.preferredName as String default '')
	var firstName: String = cleanseStringForUPN(person.data.firstName as String default '')
	var lastName: String = cleanseStringForUPN(person.data.lastName as String default '')
	var lastNameInital: String = first(lastName, 1)
    
    var firstNameDerivedUPN: String = applyTestPrefixIfConfigured('$firstName.$lastName')
    var firstNameLastNameInitialDerivedUPN: String = applyTestPrefixIfConfigured('$firstName.$lastNameInital')
    var preferredNameDerivedUPN: String = applyTestPrefixIfConfigured('$preferredName.$lastName')
    var preferredNameLastNameInitialDerivedUPN: String = applyTestPrefixIfConfigured('$preferredName.$lastNameInital')
    
	---
    if(isEmpty(preferredName)) 
        (if(sizeOf(firstNameDerivedUPN) <= MAX_SIZE)
            firstNameDerivedUPN
        else
            firstNameLastNameInitialDerivedUPN)
    else
        (if(sizeOf(preferredNameDerivedUPN) <= MAX_SIZE)
            preferredNameDerivedUPN
        else
            preferredNameLastNameInitialDerivedUPN)
}

fun deriveSAMAccountNameWithMiddleNameInitial(person: Object | Null): String = do {
    var MAX_SIZE: Number = 20 as Number
	var preferredName: String = cleanseStringForUPN(person.data.preferredName as String default '')
	var firstName: String = cleanseStringForUPN(person.data.firstName as String default '')
	var middleNameInitial: String = first(cleanseStringForUPN(person.data.middleName as String default ''), 1)
	var lastName: String = cleanseStringForUPN(person.data.lastName as String default '')
	var lastNameInital: String = first(lastName, 1)
	
    var firstNameDerivedUPN: String = applyTestPrefixIfConfigured('$firstName.$middleNameInitial.$lastName')
    var firstNameLastNameInitialDerivedUPN: String = applyTestPrefixIfConfigured('$firstName.$middleNameInitial.$lastNameInital')
    var preferredNameDerivedUPN: String = applyTestPrefixIfConfigured('$preferredName.$middleNameInitial.$lastName')
    var preferredNameLastNameInitialDerivedUPN: String = applyTestPrefixIfConfigured('$preferredName.$middleNameInitial.$lastNameInital')
	---
    if(isEmpty(preferredName)) 
        (if(sizeOf(firstNameDerivedUPN) <= MAX_SIZE)
            firstNameDerivedUPN
        else
            firstNameLastNameInitialDerivedUPN)
    else
        (if(sizeOf(preferredNameDerivedUPN) <= MAX_SIZE)
            preferredNameDerivedUPN
        else
            preferredNameLastNameInitialDerivedUPN)
}

fun derivedUPN(person: Object | Null, job: Object | Null): String = do {
	var samAccountName: String = deriveSAMAccountName(person)
	var domainNameSuffix: String = job.data.location.customFields.email_domain.value.label as String default 'mitre10.co.nz'
	---
	samAccountName ++ '@' ++ (domainNameSuffix)
}

fun derivedUPNWithMiddleNameInitial(person: Object | Null, job: Object | Null): String = do {
	var samAccountName: String = deriveSAMAccountNameWithMiddleNameInitial(person)
	var domainNameSuffix: String = job.data.location.customFields.email_domain.value.label as String default 'mitre10.co.nz'
	---
	samAccountName ++ '@' ++ (domainNameSuffix)
}

fun getValidEmailDomains(): Array = getArrayFromProperty('microsoft.graph.api.valid.email_domains')

fun isEmailInValidDomain(emailAddress: String): Boolean = do {
	var VALID_DOMAINS: Array = getValidEmailDomains()
	var emailDomain: String = getEmailDomain(emailAddress)
	---
	VALID_DOMAINS contains emailDomain
}

fun getUPN(person: Object | Null): String = do {
	var emailAddresses: Array = getArrayFieldFromPerson(person default {}, 'emailAddresses')
	var workEmail: String = getWorkEmailFromHREvent(emailAddresses)
	---
	if(not isBlank(workEmail))
		applyTestPrefixIfConfigured(workEmail)
	else
		''
}

fun getSAMAccountName(person: Object | Null): String = do {
	var existingUPN: String = getUPN(person)
	---
	splitBy(existingUPN, '@')[0] as String default ''
}

fun getEmailDomain(emailAddress: String): String = do {
	var emailComponents: Array = splitBy(emailAddress, '@')
	---
	if(sizeOf(emailComponents) == 2)
		emailComponents[1] as String default ''
	else
		''
}

fun getPeopletechEmail(): String = 'vikas.singhal@mitre10.co.nz' as String // 'HRISSupport+Peopletech@mitre10.co.nz' as String default 'peopletech@mitre10.co.nz'

fun determineUPNChangeEvent(requestWebevent: Object): Boolean = do {
  var personNameFieldArray: Array = ["first_name", "last_name", "preferred_name"]
  var fieldsChangedArray: Array = requestWebevent.updated_attributes as Array default []
  var isPersonUpdateEvent: Boolean = ("person.updated" == (requestWebevent.event default ''))
  var isNameChangeEvent: Boolean = (sizeOf(personNameFieldArray map ((item, index) -> {(item as String): fieldsChangedArray contains item}) filter ((item, index) -> item[0]== true)) > 0)
  ---
  if (isPersonUpdateEvent and isNameChangeEvent)
  	true
  else
  	false
}

fun determineUPNForADUpdate(eventAction:String, derivedUPNValue: String | Null, existingUPNValue: String | Null, requestWebevent: Object | Null, azureSearchResult: String | Null): String = do {
	var derivedUPN: String = derivedUPNValue default ''
	var existingUPN: String = existingUPNValue default ''
	var isUPNChangeEvent: Boolean = determineUPNChangeEvent(requestWebevent default {})
	var hasUPNClashed: Boolean = 'ERROR_UPN_CLASH' == (azureSearchResult default '')
	---
	if (hasUPNClashed)
		derivedUPN
	else if ('update' == eventAction and isUPNChangeEvent)
		derivedUPN
	else if (isBlank(existingUPN))
		derivedUPN
	else
		existingUPN
}

fun determineSAMAccountForADUpdate(upnForAdUpdate:String): String = do {
	splitBy(upnForAdUpdate, '@')[0] as String default ''
}

fun hasHumanforceLabel(labels: Array): Boolean = do {
	var HUMANFORCE_LABEL_NAME: String = 'Humanforce Mobile App'
	---
	labels contains HUMANFORCE_LABEL_NAME
}

fun hasPayslipLabel(labels: Array): Boolean = do {
	var PAYSLIP_LABEL_NAME: String = 'Store Pay Slip'
	---
	labels contains PAYSLIP_LABEL_NAME
}

fun hasMobileLabel(label: String): Boolean = do {
	var MOBILE_LABEL_NAME: String = 'Mobile'
	---
	MOBILE_LABEL_NAME == label 
}

fun hasLandlineLabel(label: String): Boolean = do {
	var LANDLINE_LABEL_NAME: String = 'Landline'
	---
	LANDLINE_LABEL_NAME == label
}

fun emailHasHumanforceOrPayslipLabel(person: Object): Boolean = do {
	var emailAddresses: Array = getArrayFieldFromPerson(person, 'emailAddresses') default []
	var humanforceOrPayslipEmailArr: Array = emailAddresses filter (emailAddress) -> (hasHumanforceLabel(emailAddress.customFields.usage.value.labels default []) or hasPayslipLabel(emailAddress.customFields.usage.value.labels default []))
	---
	not isEmpty(humanforceOrPayslipEmailArr)
}

fun getObjectFieldFromPerson(person: Object, fieldName: String):Object = do {
	var personDataPath: Object = person.data.'$fieldName' as Object default {}
	var personPath: Object = person.'$fieldName' as Object default {}
    ---
    if (sizeOf(personDataPath) > 0) 
    	personDataPath 
    else 
    	personPath
}

fun getArrayFieldFromPerson(person: Object, fieldName: String):Array = do {
	var personDataPath: Array = person.data.'$fieldName' as Array default []
	var personPath: Array = person.'$fieldName' as Array default []
    ---
    if (sizeOf(personDataPath) > 0) 
    	personDataPath 
    else 
    	personPath
}

fun getWorkEmailFromHREvent(emailAddresses: Array): String = do {
	var workEmailArr: Array = emailAddresses filter (emailEntry, index) -> (isEmailInValidDomain(emailEntry.email) and (!emailEntry.isPersonal and (emailEntry.isPrimary or !emailEntry.isPrimary)))
	---
	if ( sizeOf(workEmailArr) == 1 ) 
		workEmailArr[0].email as String default ''
	else if ( sizeOf(workEmailArr) > 1 ) do {
		var filtered = workEmailArr filter (email, index) -> (email.isPrimary)
		---
		if ( sizeOf(filtered) == 1 ) 
			filtered[0].email as String default ''
		else if ( sizeOf(filtered) == 0 and sizeOf(workEmailArr) > 0 ) 
			workEmailArr[0].email as String default ''
		else
			filtered[0].email as String default ''
	}
	else
		''
}

fun getHumanForceEmailFromPerson(person: Object): String = do {
	var emailAddresses: Array = getArrayFieldFromPerson(person, 'emailAddresses')
	var humanforceEmailArr: Array = emailAddresses filter (email, index) -> (hasHumanforceLabel(email.customFields.usage.value.labels default []))
	---
	if ( sizeOf(humanforceEmailArr) >= 1 ) 
		humanforceEmailArr[0].email as String default ''
	else
		''
}

fun getPaySlipEmailFromPerson(person: Object): String = do {
	var emailAddresses: Array = getArrayFieldFromPerson(person, 'emailAddresses')
	var payslipEmailArr: Array = emailAddresses filter (email, index) -> (hasPayslipLabel(email.customFields.usage.value.labels default []))
	---
	if ( sizeOf(payslipEmailArr) >= 1 ) 
		payslipEmailArr[0].email as String default ''
	else
		''
}

fun getPrimaryWorkPhoneFromPerson (person: Object): String = do {
	var phoneNumbers: Array = getArrayFieldFromPerson(person, 'phoneNumbers')
	var workPhoneArr: Array = phoneNumbers filter (phoneNumber, index) -> (!phoneNumber.isPersonal)
	var primaryWorkPhone: Array = workPhoneArr filter (phoneNumber, index) -> (phoneNumber.isPrimary)
	---
	if ( sizeOf(workPhoneArr) == 1 ) 
		workPhoneArr[0].fullNumber as String default ''
	else if (sizeOf(workPhoneArr) > 1 )
		if (sizeOf(primaryWorkPhone) == 1 )
			primaryWorkPhone[0].fullNumber as String default ''
		else
			workPhoneArr[0].fullNumber as String default ''
	else
		''
}

fun getWorkMobileFromPerson(person): String = do {
	var phoneNumbers: Array = getArrayFieldFromPerson(person, 'phoneNumbers')
	var workMobileArr: Array = phoneNumbers filter (phone, index) -> (!phone.isPersonal and hasMobileLabel(phone.customFields.'type'.value.label as String default ''))
	---
	if ( sizeOf(workMobileArr) >= 1 ) 
		workMobileArr[0].fullNumber as String default ''
	else
		''
}

fun getPersonalMobileFromPerson(person): String = do {
	var phoneNumbers: Array = getArrayFieldFromPerson(person, 'phoneNumbers')
	var personalMobileArr: Array = phoneNumbers filter (phone, index) -> (phone.isPersonal and hasMobileLabel(phone.customFields.'type'.value.label as String default ''))
	---
	if ( sizeOf(personalMobileArr) >= 1 ) 
		personalMobileArr[0].fullNumber as String default ''
	else
		''
}

fun getPersonalLandlineFromPerson(person): String = do {
	var phoneNumbers: Array = getArrayFieldFromPerson(person, 'phoneNumbers')
	var personalLandlineArr: Array = phoneNumbers filter (phone, index) -> (phone.isPersonal and hasLandlineLabel(phone.customFields.'type'.value.label as String default ''))
	---
	if ( sizeOf(personalLandlineArr) >= 1 ) 
		personalLandlineArr[0].fullNumber as String default ''
	else
		''
}

fun getPrimaryAddressFromPerson(person: Object): Object | Null = do {
	var addresses: Array = getArrayFieldFromPerson(person, 'addresses')
	var primaryAddressArr: Array = addresses filter (address, index) -> (address.isPrimary)
	---
	if ( sizeOf(primaryAddressArr) == 1 ) 
		primaryAddressArr[0] as Object
	else
		null
}

fun getPostalAddressFromPerson(person: Object): Object | Null = do {
	var addresses: Array = getArrayFieldFromPerson(person, 'addresses')
	var primaryAddress: Object = getPrimaryAddressFromPerson(person) default {}
	var postalAddressArr: Array = addresses filter (address, index) -> ('Postal' == address.addressType)
	---
	if ('Postal' == primaryAddress.addressType)
		primaryAddress
	else if ( sizeOf(postalAddressArr) >= 1 ) 
		postalAddressArr[0] as Object
	else
		null
}

fun getConcurrentJobsFromPerson(person: Object | Null): Array = do {
    var personJobs: Array = getArrayFieldFromPerson(person default {}, 'jobs')
	---
	(personJobs filter ((value, index) -> (['Current Job', 'Ending Job'] contains value.jobStatus))) default [] 
}

fun hasActiveConcurrentJobsFromPerson(person: Object | Null): Boolean = do {
	var jobs: Array = getConcurrentJobsFromPerson(person)
	---
	sizeOf(jobs) >= 2
}

fun hasActiveConcurrentJobsFromPersonAndJob(person: Object | Null, job: Object | Null): Boolean = do {
	var jobs: Array = getConcurrentJobsFromPerson(person)
	var JobId: String = job.data.id as String default ''
	---
	sizeOf(jobs filter (jobItem, jobIndex) -> (jobItem.id != JobId)) > 0
}

fun hasActiveJobsFromPerson(person: Object | Null): Boolean = do {
	var jobs: Array = getConcurrentJobsFromPerson(person)
	---
	sizeOf(jobs) >= 1
}

fun hasFutureJobs(person: Object | Null): Boolean = do {
	var personJobs: Array = getArrayFieldFromPerson(person default {}, 'jobs')
	var jobs = if ( personJobs != null ) 
		(personJobs filter ((value, index) -> (['Future Job'] contains value.jobStatus))) default [] 
	else 
		[]
	---
	sizeOf(jobs) > 0
}

fun getCompanyStartDate(person: Object) = do {
	var personJobs: Array = getArrayFieldFromPerson(person, 'jobs')
	var jobsArr = ((personJobs) update {
		case startDate at .startDate -> getDatetimeType(startDate)
		case endDate at .endDate -> getDatetimeType(endDate)
	})
	---
	((jobsArr orderBy ($.startDate))[-1]).startDate
}

fun getPlannedTerminationDate(person: Object): DateTime | Null = do {
	var personJobs: Array = getArrayFieldFromPerson(person, 'jobs')
	var jobsWithEndDates: Array = personJobs filter ((job, index) -> ((['Current Job', 'Ending Job', 'Future Job'] contains job.jobStatus) and job.endDate != null))
    var jobsWithoutEndDates: Array = personJobs filter ((job, index) -> ((['Current Job', 'Ending Job', 'Future Job'] contains job.jobStatus) and job.endDate == null))
    var jobsWithPastJobStatus: Array = personJobs filter ((job, index) -> (['Past Job'] contains job.jobStatus))
    var jobsWithFutureJobStatus: Boolean = hasFutureJobs(person)
	---
	if (sizeOf(jobsWithoutEndDates) > 0 ) 
		null
	else if (sizeOf(jobsWithEndDates) == 0 and sizeOf(jobsWithoutEndDates) == 0 and !jobsWithFutureJobStatus and sizeOf(jobsWithPastJobStatus) > 0)
    	getDatetimeType(((jobsWithPastJobStatus orderBy ($.endDate))[-1]).endDate)
    else
        getDatetimeType(((jobsWithEndDates orderBy ($.endDate))[-1]).endDate)
}

fun getLocationCode(job: Object | Null): String = job.data.location.code as String default ''

fun getLocationCodeLegacy(job: Object | Null): String = do {
	var locationType: String = getLocationType(job)
	---
	if (job == null)
		''
	else if ('SUPPORT_CENTRE' == locationType)
		'1'
	else
		getLocationCode(job)
}

fun getDepartment(departmentDetails: Object | Null): String = do {
	if (departmentDetails == null)
		''
	else
		departmentDetails.data.customFields.business_unit_code.value as String default ''
}

fun getSubDepartment(subDepartmentDetails: Object | Null): String = do {
	if (subDepartmentDetails == null)
		''
	else
		subDepartmentDetails.data.customFields.business_unit_code.value as String default ''
}

fun getTeam(teamDetails: Object | Null): String = do {
	if (teamDetails == null)
		''
	else
		teamDetails.data.customFields.business_unit_code.value as String default ''
}
fun extractBusinessRoleParts(businessRole: String | Null): Array = splitBy(businessRole default '', ':') default []

fun isValidBusinessRoleFormat(businessRole: String | Null): Boolean = do {
	var roleParts: Array = extractBusinessRoleParts(businessRole)
	---
	sizeOf(roleParts) == 3
}

fun extractLocationTypeFromBusinessRole(businessRole: String | Null): String = do {
	var roleParts: Array = extractBusinessRoleParts(businessRole)
	var locationType: String = roleParts[0] as String default ''
	---
	if (sizeOf(roleParts) <= 1)
		''
	else if (sizeOf(roleParts) == 3)
		if (upper(locationType) == 'SC')
			'SUPPORT_CENTRE'
		else if (upper(locationType) == 'STORE')
			'STORE'
		else
			'UNKNOWN-' ++ locationType
	else
		''
}

fun extractRoleNameFromBusinessRole(businessRole: String | Null): String = do {
	var roleParts: Array = extractBusinessRoleParts(businessRole)
	---
	if (sizeOf(roleParts) <= 1)
		''
	else if (sizeOf(roleParts) == 3)
		roleParts[1] as String default ''
	else
		''
}

fun extractPositionCodeFromBusinessRole(businessRole: String | Null): String = do {
	var roleParts: Array = extractBusinessRoleParts(businessRole)
	---
	if (sizeOf(roleParts) <= 1)
		''
	else if (sizeOf(roleParts) == 3)
		roleParts[2] as String default ''
	else
		''
}

fun getPosition(job: Object | Null, locationType: String): String = do {
	var scBusinessRole: String = job.data.customFields.business_role.value.label as String default ''
	var storeBusinessRole: String = job.data.customFields.business_role_store.value.label as String default ''
	---
	if(['SUPPORT_CENTRE','MIMP'] contains locationType)
		extractPositionCodeFromBusinessRole(scBusinessRole)
	else
		extractPositionCodeFromBusinessRole(storeBusinessRole)	
}

fun getOrg(departmentDetails: Object | Null, subDepartmentDetails: Object | Null, teamDetails: Object | Null): String = do {
	var departmentCode: String = getDepartment(departmentDetails)
	var subDepartmentCode: String = getSubDepartment(subDepartmentDetails)
	var teamCode: String = getTeam(teamDetails)
	---
	departmentCode ++ subDepartmentCode ++ teamCode
}

fun getOrgPosition(departmentDetails: Object | Null, subDepartmentDetails: Object | Null, teamDetails: Object | Null, job: Object | Null, locationType: String): String = do {
	var org: String = getOrg(departmentDetails, subDepartmentDetails, teamDetails)
	var position: String = getPosition(job, locationType)
	---
	org ++ position
}

fun getWAP(departmentDetails: Object | Null, subDepartmentDetails: Object | Null, teamDetails: Object | Null, job: Object | Null, locationType: String): String = do {
	var orgPosition: String = getOrgPosition(departmentDetails, subDepartmentDetails, teamDetails, job, locationType)
	var locationCode: String = getLocationCodeLegacy(job)
	---
	locationCode ++ orgPosition
}

fun getBusinessEntityCode(job: Object | Null): String = do {
	if (job == null)
		''
	else
		job.data.businessEntity.code as String default ''
}

fun getPrimaryJobId(person: Object | Null): String = do {
	var primaryJobArr: Array = getArrayFieldFromPerson(person default {}, 'jobs') filter ((value, index) -> ((value.isPrimaryJob as Boolean == true))) default []
	---
	if(sizeOf(primaryJobArr) == 1)
		primaryJobArr[0].id as String default ''
	else
		''
}

fun getConfiguredStartDateUpcomingOffset(): String = '-1 month|-14 days|-7 days|-3 days|-1 days|0 days' as String default "-3 days|-1 days|0 days"

fun isJobStartDateUpcomingOffsetAllowed(webHookOffSort: String | Null): Boolean = do {
	var offsetProperty: String = getConfiguredStartDateUpcomingOffset()
	var allowedOffsetList: Array = splitBy(offsetProperty, '|')
	---
	if(isBlank(webHookOffSort))
		false
	else
		(allowedOffsetList contains webHookOffSort)
}

fun getTRMUsingLocationName(locationList: Array, locationName: String): String = do {
    ((locationList filter ((item, index) -> item.name == locationName)) map (location, index) -> (location.customFields.trm_code.value default ''))[0] as String default ''
}

fun getTRMFromJob(locationsList: Array, job: Object): Array = do {
	var GROUP_NAME: String = 'Store-Code_'
    var jobStoreCode: String = GROUP_NAME ++ (job.data.location.customFields.trm_code.value as String default '')
    var additionalStoreResponsibilities: Array = job.data.customFields.additional_store_responsibilities.value.labels as Array default []
    var additionalStoreCodes: Array = (additionalStoreResponsibilities map (location, index) -> (GROUP_NAME ++ getTRMUsingLocationName(locationsList,location)))
    ---
    [jobStoreCode] ++ additionalStoreCodes
}

fun getStoreCodeGroupsForTeamMember(locationsList: Array, job: Object, concurrentJobs = []): Array = do {
    var allJobs: Array = job >> concurrentJobs
	---
	(allJobs flatMap ((job, index) -> getTRMFromJob(locationsList,job)) distinctBy ((item) -> item) default []) filter (storeCode,index) -> (sizeOf(storeCode)> 11)
}

fun getAllJobsFromEvent(hrEvent: Object): Array = do {
	var concurrentJobs: Array = hrEvent.event.header.variables.concurrentJobs as Array default []
	var eventJob: Object = hrEvent.event.payload.job as Object default {}
	---
	concurrentJobs << eventJob
}

fun getPrimaryJobFromList(allJobs: Array): Object = do {
	var primaryJob: Array = allJobs filter (job, index) -> (job.data.isPrimaryJob == true)
	---
	if (isEmpty(primaryJob))
		{}
	else
		primaryJob[0] as Object default {}
}

fun getPrimaryJobFromEvent(hrEvent: Object): Object = do {
	var allJobs: Array = getAllJobsFromEvent(hrEvent)
	---
	getPrimaryJobFromList(allJobs)
}

fun calculateCompanyEndDate(value: String | Null): DateTime | Null = do {
	if(isEmpty(value))
		null
	else
		(value as DateTime) - |P1D|
}

fun isIntelliHrUserAccountAllowed(hrEvent: Object): Boolean = do {
	var primaryJob: Object = getPrimaryJobFromEvent(hrEvent)
	var create_intelli_hr_account: String = primaryJob.data.location.customFields.create_intelli_hr_account.value.label as String default ''
	---
	'yes' == lower(create_intelli_hr_account)
}

fun isLocationIsPartOfBusinessEntity(job: Object): Boolean = do {
	var bizEntityLocations: Array = job.data.businessEntity.customFields.store_groups.value.labels as Array default []
	var locationName: String = job.data.location.name as String default ''
	---
	if(isEmpty(locationName) or isEmpty(bizEntityLocations))
		false
	else
		contains(bizEntityLocations, locationName)
}

fun getInvalidAdditionalStoreResponsibility(job: Object):Array = do {
	var bizEntityLocations: Array = job.data.businessEntity.customFields.store_groups.value.labels as Array default []
	var additionalStores: Array = job.data.customFields.additional_store_responsibilities.value.labels as Array default []
	---
	additionalStores filter ((locationName, index) -> not contains(bizEntityLocations, locationName)) default []
}

fun isAdditionalStoreResponsibilityIsPartOfBusinessEntity(job: Object): Boolean = do {
	var bizEntityLocations: Array = job.data.businessEntity.customFields.store_groups.value.labels as Array default []
	var invalidLocations: Array = getInvalidAdditionalStoreResponsibility(job)
	---
	if(isEmpty(bizEntityLocations))
		false
	else
		isEmpty(invalidLocations)
}

fun isValidSupervisorAssigned(hrEvent: Object, supervisorJob: Object): Boolean = do {
	var job: Object = hrEvent.event.payload.job as Object default {}
	var jobBusinessEntity: String = job.data.businessEntity.name as String default ''
	var supervisorBusinessEntity: String = supervisorJob.data.businessEntity.name as String default ''
	---
	jobBusinessEntity == supervisorBusinessEntity
}

fun getBusinessRole(job: Object | Null, locationType: String | Null): String = do {
    if(isEmpty(job) or isEmpty(locationType))
        ''
	else if(['SUPPORT_CENTRE','MIMP'] contains locationType)
		job.data.customFields.business_role.value.label as String default ''
	else
		job.data.customFields.business_role_store.value.label as String default ''
}

fun isSupervisorAssigned(supervisorJob: Object): Boolean = do {
	not isEmpty(supervisorJob.data)
}

fun addErrorCode(targetSystem: String | Null, errorCode: Number | Null): String = (if(isEmpty(targetSystem)) '' else ((targetSystem default '') ++ ' ')) ++ '(Error Code: ' ++ (errorCode as String default 'Invalid value') ++ ')'

fun getAlertEmail(hrEvent: Object | Null, alertType: String | Null): String = do {
	if (['Business'] contains alertType)
		getPrimaryJobFromEvent(hrEvent default {}).data.location.customFields.store_hr_representative.value as String default p('common-alert.' ++ lower(alertType default 'Technical') ++ '-error-notification.email') as String default ''
	else if (['Technical'] contains alertType)
		getPrimaryJobFromEvent(hrEvent default {}).data.location.customFields.store_it_representative.value as String default p('common-alert.' ++ lower(alertType default 'Technical') ++ '-error-notification.email') as String default ''
	else
		p('common-alert.' ++ lower(alertType default 'Technical') ++ '-error-notification.email') as String default ''
}

fun isNoLocationSelected(job: Object | Null): Boolean = do {
	var noLocationName: String = 'No Location' as String default 'No Location'
	var locationName: String = job.data.location.name as String default ''
	---
	locationName == noLocationName
}

fun getEmployeeHireDate(person: Object): String = do {
	if (isEmpty(person))
		''
	else
        (getDatetimeType(getCompanyStartDate(person)) as String {format: "yyyy-MM-dd'T'HH:mm:ss'Z'"}) default ''
}

fun getAddressPart(address: Object | Null, partName: String, partIndex: Number): String | Null = do {
	if (isEmpty(address))
		null
	else if (isBlank(address.'$partName' as String | Null) or (['N/A'] contains address.'$partName'))
		trim(splitBy(address.fullAddress as String | Null default '', ',')[partIndex])
	else 
		address.'$partName' as String | Null
}

fun getAddressStreet(address: Object | Null): String | Null = do {
	getAddressPart(address, 'street', 0)
}

fun getAddressSuburb(address: Object | Null): String | Null = do {
	getAddressPart(address, 'suburb', 1)
}

fun getAddressState(address: Object | Null): String | Null = do {
	getAddressPart(address, 'state', 2)
}

fun getNewLeavingDate(formDetails: Object): String = do {
    var formDetailsNewLeavingDate = ((formDetails.data.answers filter ((item, index) -> item.question == 'New leaving date'))[0].value[0]) as String default null
    ---
    ((substring(formDetailsNewLeavingDate default '', 0, 10) as Date + |P1D|) ++ 'T12:00:00+00:00') as String default ''
}

fun getJobsFromPerson(person: Object | Null): Array = do {
    var personJobs: Array = getArrayFieldFromPerson(person default {}, 'jobs')
	---
	(personJobs filter ((value, index) -> (['Current Job', 'Ending Job', 'Past Job'] contains value.jobStatus))) default [] 
}

// <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< HREvent_Util_DW_DW_End

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> IDM_Util_DW_Start


// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> IDM_Util_DW_End

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> HumanForce_Util_DW_Start

fun isHREventHumanforceIntegrated(hrEvent: Object): Boolean = do {
	var primaryJob = getPrimaryJobFromEvent(hrEvent)
	---
	isJobHumanforceIntegrated(primaryJob)
}

fun isJobHumanforceIntegrated(job: Object): Boolean = do {
	var humanForceAllowedConfig = getArrayFromProperty('humanforce.location.uses-pg.payroll-type')
	var payrollType = job.data.location.customFields.payroll_type.value.label as String default ''
	var mappedWorkClass = mapWorkClassToEmploymentType(job)
	---
	contains(humanForceAllowedConfig, payrollType) and !isBlank(mappedWorkClass)
}

fun checkJobLocationUpdateRequired(job: Object, currentLocationCodeList: Array): Boolean = do {
	isJobHumanforceIntegrated(job) and (not contains(currentLocationCodeList, getLocationExportCodeFromJob(job)))
}

fun checkJobDepartmentUpdateRequired(job: Object, currentDepartmentCodeList: Array): Boolean = do {
	isJobHumanforceIntegrated(job) and (not contains(currentDepartmentCodeList, getDepartmentExportCodeFromJob(job)))
}

fun checkJobRoleUpdateRequired(job: Object, currentRoleCodeList: Array): Boolean = do {
	isJobHumanforceIntegrated(job) and (not contains(currentRoleCodeList, getRoleExportCodeFromJob(job)))
}

fun mapWorkClassToEmploymentType(job: Object): String | Null = do {
	var workClass = job.data.workClass
	---
	workClass match {
		case 'Store Permanent Salaried - F/T' -> 'SALARY_FT'
		case 'Store Permanent Salaried - P/T' -> 'SALARY_PT'
		case 'Store Permanent Waged - F/T' -> 'PERM_FT'
		case 'Store Permanent Waged - P/T' -> 'PERM_PT'
		case 'Store Fixed Term Salaried - F/T' -> 'SAL_FIXED_FT'
		case 'Store Fixed Term Salaried - P/T' -> 'SAL_FIXED_PT'
		case 'Store Fixed Term Waged - F/T' -> 'FIXED_FT'
		case 'Store Fixed Term Waged - P/T' -> 'FIXED_PT'
		case 'SC Permanent - F/T' -> null
		case 'SC Permanent - P/T' -> null
		case 'SC Fixed Term - F/T' -> null
		case 'SC Fixed Term - P/T' -> null
		case 'SC Secondment - F/T' -> null
		case 'SC Secondment - P/T' -> null
		case 'SC Contractor - Payroll' -> null
		case 'Casual' -> 'CAS'
		case 'Director' -> 'DIR'
		case 'Store Contractor' -> null
		case 'SC Contractor' -> null
		case 'SC Contractor - SoW' -> null
		case 'SC Contractor - Agency' -> null
		case 'SC Contractor - ICA' -> null
		case 'Work Experience' -> null
		case 'Intern' -> null
		else ->	null
	}
}

fun mapVisaRequired(person: Object): String = do {
	var noVisaRequiredList: Array = getArrayFromProperty('hris.visa.not.required.list')
	var personVisa: String = lower(person.workRights.name as String default '')
	---
	if ( isBlank(personVisa) or (noVisaRequiredList contains personVisa) ) 
		''
	else
		'Visa Required'
}

fun mapVisaExpiryDate(person: Object): String = do {
	var visaRequired = mapVisaRequired(person)
	var DEFAULT_NULL_VISA_EXPIRY_DATE: String = '0001-01-01'
	---
	if (isBlank(visaRequired))
		DEFAULT_NULL_VISA_EXPIRY_DATE
	else
		person.workRights.expirationDate as String default DEFAULT_NULL_VISA_EXPIRY_DATE
}

fun mapVisaType(visaRequired: String): Object = do {
	if (isBlank(visaRequired))
		{
			ExportCode: null
		}
	else
		{
			Name: visaRequired
		}
}

fun mapToHumanforceGenderCode(value: String): String = value match {
	case 'Male'        -> 'M'
	case 'Female'      -> 'F'
	case 'Non-binary'  -> 'AG'
	case 'Other'       -> 'AG'
	case 'Undisclosed' -> 'PS'
	else               -> ''
}

fun getPayCompanyExportCode(job: Object): String = do {
	job.data.location.customFields.human_force_pay_company_export_code.value as String default ''
}

fun getLocationExportCodeFromJob(job: Object): String = do {
	job.data.location.code as String default ''
}

fun getDepartmentExportCodeFromJob(job: Object): String = do {
	job.data.businessUnit.customFields.business_unit_code.value as String default ''
}

fun getBusinessRole(job: Object): String = do {
	job.data.customFields.business_role_store.value.label as String default ''
}

fun isStoreNonSAPBusinessRole(businessRole: String): Boolean = do {
	not (businessRole contains 'Store:SAP')
}

fun getRoleExportCodeFromJob(job: Object): String = do {
	var businessRole: String = getBusinessRole(job)
	---
	extractPositionCodeFromBusinessRole(businessRole)
}

fun getShortName(person: Object):String = do {
	var firstName: String = deriveFirstName(person)
	var lastNameInitial: String = first(person.data.lastName, 1)
	var attempt1: String = firstName ++ ' ' ++ lastNameInitial
	var attempt2: String = first(firstName, 13) ++ ' ' ++ lastNameInitial
	---
	if (sizeOf(attempt1) <= 15)
		attempt1
	else
		attempt2
}

fun mapIntelliHRTitleToHumanforceTitle(value: String | Null): String = do {
	value match {
		case 'Miss' -> 'Miss'
		case 'Mrs' -> 'Mrs'
		case 'Mr' -> 'Mr'
		case 'Ms' -> 'Ms'
		else -> ''
	}
}

fun checkIfRoleUpdateRequired(roleRevision: Object): Boolean = do {
	isEmpty(roleRevision.Role) or isBlank(roleRevision.Role.ExportCode)
}

fun checkIfRoleRevisionUpdateRequired(roleRevision: Object): Boolean = do {
	isEmpty(roleRevision.Profile) or isBlank(roleRevision.Profile.ExportCode)
}

fun checkIfDateEffectiveUpdateRequired(roleRevision: Object): Boolean = do {
	isBlank(roleRevision.DateEffective)
}

fun checkIfUpdateRequired(roleRevision: Object): Boolean = do {
	checkIfRoleUpdateRequired(roleRevision) or checkIfRoleRevisionUpdateRequired(roleRevision) or checkIfDateEffectiveUpdateRequired(roleRevision)
}

fun findJobByBusinessRoleCode(concurrentJobs: Array, roleCode: String): Object = do {
	var filteredJobs = concurrentJobs filter ((job, index) -> endsWith(job.customFields.business_role_store.value.label, roleCode))
	---
	if(sizeOf(filteredJobs) > 0)
		filteredJobs[0] as Object
	else
		{}
}

fun adjustDate(value: Any): Date | Null = do {
	if(isEmpty(value))
		null
	else
		value as Date default null
}

fun filterForSameLegalEntityJobs(hrEvent: Object): Array = do {
	var primaryJob: Object = getPrimaryJobFromEvent(hrEvent)
	var concurrentJobs: Array = getAllJobsFromEvent(hrEvent)
	---
	concurrentJobs filter ((job, index) -> job.data.businessEntity.id == primaryJob.data.businessEntity.id)
}
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> HumanForce_Util_DW_End

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Esker_Util_DW_Start

fun getFirstName(person: Object): String = do {
    var firstName: String = person.data.firstName as String default ''
    var preferredName: String = person.data.preferredName as String default ''
	---
    if (isBlank(preferredName)) firstName else preferredName
}

fun getDisplayName(person: Object, action: String): String = do {
    var firstName: String = getFirstName(person) as String default ''
    var lastName: String = person.data.lastName as String default ''
    var displayName: String = (firstName ++ ' ' ++ lastName) as String default ''
	---
    if (action == 'disable') ('ZZ_' ++ displayName) else displayName
}

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Esker_Util_DW_End

// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> XXX_Util_DW_Start
// >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> XXX_Util_DW_End

var hrEvent = 
vars.hrEvent update {
    //case header at                              .event.header ->  {}
    
    case person_customFields at                 .event.payload.person.data.customFields ->  {}
    case person_medicalConditions at            .event.payload.person.data.medicalConditions ->  {}
    
    case job_timeline at                        .event.payload.job.timeline ->  {}
    case job_customFields at                    .event.payload.job.data.customFields ->  {}
    case job_payGrade at                        .event.payload.job.data.payGrade ->  {}
    case job_businessEntity_customFields at     .event.payload.job.data.businessEntity.customFields ->  {}
    case job_remunerationSchedule at            .event.payload.job.data.remunerationSchedule ->  {}
    
    case supervisor at                          .event.payload.supervisor ->  {}
    
    case jobs0_timeline at                      .event.payload.jobs[0].timeline ->  {}
    case jobs0_customFields at                  .event.payload.jobs[0].data.customFields ->  {}
    
    case jobs1_timeline at                      .event.payload.jobs[1].timeline ->  {}
    case jobs1_customFields at                  .event.payload.jobs[1].data.customFields ->  {}
    
    case jobs2_timeline at                      .event.payload.jobs[2].timeline ->  {}
    case jobs2_customFields at                  .event.payload.jobs[2].data.customFields ->  {}
    
    case jobs3_timeline at                      .event.payload.jobs[3].timeline ->  {}
    case jobs3_customFields at                  .event.payload.jobs[3].data.customFields ->  {}
    
    case jobs_timeline1 at                      .event.payload.jobs[1].timeline ->  {}
    case jobs_timeline2 at                      .event.payload.jobs[2].timeline ->  {}
    case jobs_timeline3 at                      .event.payload.jobs[3].timeline ->  {}
}

var queueName = payload.dlqName default 'payload.dlqName is N/A'
//var webhook = intelliHr.webhook default vars.hrEvent.event.header.variables.requestWebevent
var webhook = vars.hrEvent.event.header.variables.requestWebevent
var intelliHrWebhooks = sizeOf(webhook)

var person: Object = vars.hrEvent.event.payload.person.data as Object default {}
var job: Object = vars.hrEvent.event.payload.job.data as Object default {}
var hasConcurrentJobs: Boolean = hasActiveConcurrentJobsFromPerson(person)
var plannedTerminationDate = calculateCompanyEndDate(getPlannedTerminationDate(person) as String default '')
// var allJobs: Array<Object> = getAllJobsFromEvent(vars.hrEvent default {})
var allJobs: Array = getAllJobsFromEvent(vars.hrEvent default {})
var locationType: String = getLocationType(vars.hrEvent.event.payload.job default {})

fun concat(value1: String, value2: String): String = value1 ++ value2
fun concat(value1: Number, value2: Number): String = (value1 as String) ++ (value2 as String)
fun concat(value1: Any, value2: Any): String = "Other types"

var d1 = "2024-12-01T11:00:00+00:00"
var d2 = "2024-04-07T12:00:00+00:00"
var d3 = "2024-12-01T23:59:00+00:00"

var sd = "2024-06-30T12:00:00+00:00"
var ed = "2024-09-01T12:00:00+00:00"

---

{
    '<': '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< d1 start',
    d1_a0: 0,
    d1_a1: 1,
    d1_a2: 2,
    d1_a3: 3,
    d1_a4: 4,
    d1_a5: 5,
    d1_a6: 6,
    d1_a7: 7,
    d1_a8: 8,
    d1_a9: 9,
    d1_b0: 0,
    d1_b1: 1,
    d1_b2: 2,
    d1_b3: 3,
    d1_b4: 4,
    d1_b5: 5,
    d1_b6: 6,
    d1_b7: 7,
    d1_b8: 8,
    d1_b9: 9,
    '>': '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   d1 end',

    '<': '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< d2 start',
    d2_a0: 0,
    d2_a1: 1,
    d2_a2: 2,
    d2_a3: 3,
    d2_a4: 4,
    d2_a5: 5,
    d2_a6: 6,
    d2_a7: 7,
    d2_a8: 8,
    d2_a9: 9,
    d2_b0: 0,
    d2_b1: 1,
    d2_b2: 2,
    d2_b3: 3,
    d2_b4: 4,
    d2_b5: 5,
    d2_b6: 6,
    d2_b7: 7,
    d2_b8: 8,
    d2_b9: 9,
    '>': '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   d2 end',

    '-------': '------------------------------------------- d1',
    a1: d1,
    a2: d1 >> "NZ",
    a2: d1 as DateTime >> "NZ",
    a3: ((d1 as DateTime {mode: "SMART", format: 'uuuu-MM-dd\'T\'HH:mm:ssXXX'}) >> "NZ"),
    '-------': '------------------------------------------- d2',
    a1: d2,
    a2: d2 >> "NZ",
    a2: d2 as DateTime >> "NZ",
    a3: ((d2 as DateTime {mode: "SMART", format: 'uuuu-MM-dd\'T\'HH:mm:ssXXX'}) >> "NZ"),
    '-------': '------------------------------------------- d3',
    a1: d3,
    a2: d3 >> "NZ",
    a2: d3 as DateTime >> "NZ",
    a3: ((d3 as DateTime {mode: "SMART", format: 'uuuu-MM-dd\'T\'HH:mm:ssXXX'}) >> "NZ") as Date,
    '-------': '------------------------------------------- sd',
    a1: sd,
    a2: sd >> "NZ",
    a2: sd as DateTime >> "NZ",
    a3: ((sd as DateTime {mode: "SMART", format: 'uuuu-MM-dd\'T\'HH:mm:ssXXX'}) >> "NZ"),
    HF: "2024-07-01T00:00:00+12:00",
    '-------': '------------------------------------------- ed',
    a1: ed,
    a2: ed >> "NZ",
    a2: ed as DateTime >> "NZ",
    a3: ((ed as DateTime {mode: "SMART", format: 'uuuu-MM-dd\'T\'HH:mm:ssXXX'}) >> "NZ"),
    HF: "2024-09-02T00:00:00+12:00",
    '-------': '------------------------------------------- >>',

    strings: concat("Hello", " World!"), // Hello World!"
    numbers: concat(20, 20), // "2020"
    other: concat({},[]), // "Other types"
    
    /*
    payload_message                 : payload.message,
    queueName                       : "DLQ '[$queueName]'.",
    'size of intellihr webhook'     : (if ('$intelliHrWebhooks' > 1) "There are '[$intelliHrWebhooks]' webhooks." else "There is '[$intelliHrWebhooks]' webhook."),
    "p('A')"                        : p('A'),
    'p("B")'                        : p("B"),
    'p("C)'                         : p('C'),
    'p(D")'                         : p('D'),
    'p(An unrgistered random key)'  : p('An unrgistered random key'),
    */
    
    '___'                           :   '_________________________________________________',
    '---'                           :   '-------------------------------------------------',
    '==='                           :   '=================================================',
    '~~~'                           :   '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~',
    '***'                           :   '*************************************************',
    '###'                           :   '#################################################',
    '+++'                           :   '+++++++++++++++++++++++++++++++++++++++++++++++++',
    '^^^'                           :   '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^',
    '```'                           :   '`````````````````````````````````````````````````',
    '...'                           :   '.................................................',
    '<<<'                           :   '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<',
    '>>>'                           :   '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>',
    '((('                           :   '(((((((((((((((((((((((((((((((((((((((((((((((((',
    ')))'                           :   ')))))))))))))))))))))))))))))))))))))))))))))))))',
    '[[['                           :   '[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[',
    ']]]'                           :   ']]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]',
    '//'                           :   '/////////////////////////////////////////////////',
    '\\'                           :   '\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\',
    '|||'                           :   '|||||||||||||||||||||||||||||||||||||||||||||||||',
    '111'                           :   '1111111111111111111111111111111111111111111111111',
    '222'                           :   '2222222222222222222222222222222222222222222222222',
    '333'                           :   '3333333333333333333333333333333333333333333333333',
    ',,,'                           :   ',,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,',
    ';;;'                           :   ';;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;',
    ':::'                           :   ':::::::::::::::::::::::::::::::::::::::::::::::::',
    
    '-': '------------------------------------------------- d1 start',
    '-': '-------------------------------------------------   d1 end',

    '_': '_________________________________________________ d1 start',
    '_': '_________________________________________________   d1 end',
    '^': '^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   d1 end',

    '=': '================================================= d1 start',
    '=': '=================================================   d1 end',

    '<': '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< d1 start',
    '>': '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>   d1 end',
    
}

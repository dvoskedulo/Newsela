/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-15-2021
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   01-25-2021   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public class skedEmailUtil {
    public static Messaging.SingleEmailMessage setEmailWithTemplate(string subject, String[] toRecipients, String[] ccRecipients, String[] bccRecipients, String fromAddress, Id templateId, Id targetObjId, Id whatId, Id orgWideEmailId, Boolean saveAsActivity, Messaging.EmailFileAttachment[] attachList, string htmlBody) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        email.setSubject(subject);
        email.setToAddresses(toRecipients);
        if (ccRecipients != NULL && ccRecipients.size() > 0) {
            email.setCcAddresses(ccRecipients);
        }
        if (bccRecipients != NULL && bccRecipients.size() > 0) {
            email.setBccAddresses(bccRecipients);
        }
        if (targetObjId != NULL) {
            email.setTargetObjectId(targetObjId);
        }
        if (whatId != NULL) {
            email.setWhatId(whatId);
        }
        if (string.isNotBlank(templateId)) {
            email.setTemplateId(templateId);
        }
        if (string.isNotBlank(htmlBody)) {
            email.htmlBody = htmlBody;
        }
        
        if (!String.isBlank(fromAddress)) {
            List<OrgWideEmailAddress> orgEmailResult = [SELECT Id, Address 
                                                        FROM OrgWideEmailAddress
                                                        WHERE Address =: fromAddress];
            if (orgEmailResult != NULL && orgEmailResult.size() > 0) {
                OrgWideEmailAddress fromAddressEmail = orgEmailResult.get(0);
                email.setorgWideEmailAddressId(fromAddressEmail.Id);
            }
        }
        
        if(attachList != null) {
            email.setFileAttachments(attachList);
        }        
        email.setSaveAsActivity(saveAsActivity);
        System.debug(LoggingLevel.INFO,'** entered sendTemplatedEmail, to:' + toRecipients + ' cc:' + ccRecipients +  ' templateId:' + templateId + ' tagetObjId:' + targetObjId +
                     ' whatId:' + whatId + ' orgWideEmailId: ' + orgWideEmailId);
        try {
            return email;
        }
        catch (EmailException e) {
            return null;
        }
    }

    public static Blob buildInvitation(String fromAddress, List<String> emails, List<String> attendees, string summary, string location, DateTime start, DateTime finish, String timezoneSidId) {
        String calendarTemplate = skedSetting.instance.defaultSiteSetting.calendarTemplate;
        
        calendarTemplate = calendarTemplate.replace('[TIMEZONEID]', timezoneSidId);
        calendarTemplate = calendarTemplate.replace('[STARTTIME]', start.format(skedDateTimeUtils.DATE_TIME_FLOATING, timezoneSidId));
        calendarTemplate = calendarTemplate.replace('[ENDTIME]', finish.format(skedDateTimeUtils.DATE_TIME_FLOATING, timezoneSidId));
        calendarTemplate = calendarTemplate.replace('[STAMPTIME]', DateTime.now().format(skedDateTimeUtils.DATE_TIME_FLOATING, timezoneSidId));
        calendarTemplate = calendarTemplate.replace('[ORGANIZEREMAIL]', fromAddress);
        calendarTemplate = calendarTemplate.replace('[CREATEDTIME]', DateTime.now().format(skedDateTimeUtils.DATE_TIME_FLOATING, timezoneSidId));
        calendarTemplate = calendarTemplate.replace('[LASTMODIFIED]', DateTime.now().format(skedDateTimeUtils.DATE_TIME_FLOATING, timezoneSidId));
        calendarTemplate = calendarTemplate.replace('[UID]', start.format('yyyyMMddHHmmss') + DateTime.now().format('yyyyMMddHHmmss') + 'sked@skedulo.com');
        calendarTemplate = calendarTemplate.replace('[SUMMARY]', summary);
        calendarTemplate = calendarTemplate.replace('[LOCATION]', string.isNotBlank(location) ? location : '');

        Integer i = 0;
        String attendeeText = '';
        for(String attendee : attendees) {
            attendeeText += 'ATTENDEE;CUTYPE=INDIVIDUAL;ROLE=REQ-PARTICIPANT;PARTSTAT=NEEDS-ACTION;RSVP=TRUE;CN=' + attendees[i] + ';X-NUM-GUESTS=0:mailto:' + emails[i++] + '\n';
        }
        calendarTemplate = calendarTemplate.replace('[ATTENDEES]', attendeeText);
        system.debug('#calendarTemplate '+calendarTemplate);        
        return Blob.valueOf(calendarTemplate);
    }

    public static void sendEmailCustomer(List<string> jobIds) {
        String strInvite = '';
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<Task> emailTasks = new List<Task>();
        List<string> htmls = new List<string>();
        skedCommonServices cmService = new skedCommonServices();
        EmailTemplate virtualTemplate = [SELECT Id, Name, HtmlValue, Body, Subject 
                                         FROM EmailTemplate 
                                         WHERE DeveloperName = 'Skedulo_Customer_Virtual_Appointment' LIMIT 1];
        EmailTemplate inpersonTemplate = [SELECT Id, Name, HtmlValue, Body, Subject 
                                          FROM EmailTemplate 
                                          WHERE DeveloperName = 'Skedulo_Customer_In_Person_Appointment' LIMIT 1];
        EmailTemplate callTemplate = [SELECT Id, Name, HtmlValue, Body, Subject 
                                      FROM EmailTemplate 
                                      WHERE DeveloperName = 'Skedulo_Customer_Call_Appointment' LIMIT 1];

        List<sked__Job__c> skedJobs = [SELECT Id, sked__Contact__c, sked__Start__c, sked__Finish__c, sked__Timezone__c, sked__Virtual_Meeting_URL__c, 
                                            sked__Type__c, sked__Address__c, sked_Additional_Details__c, sked_Appointment_Type__c, sked_Customer_Email__c, 
                                            Activity_Medium__c, sked__Account__c, sked__Account__r.Name, 
                                            (SELECT Id, sked__Resource__r.Name, sked__Resource__r.sked__Email__c, sked__Resource__r.sked__User__r.Email,
                                                sked__Resource__r.sked__Primary_Phone__c, sked__Resource__r.sked__Mobile_Phone__c
                                             FROM sked__Job_Allocations__r
                                             WHERE sked__Status__c != :skedConstant.JOB_ALLOCATION_STATUS_DELETED
                                                AND sked__Status__c != :skedConstant.JOB_ALLOCATION_STATUS_DECLINED)
                                        FROM sked__Job__c
                                        WHERE Id IN :jobIds];
        for (sked__Job__c skedJob : skedJobs) {
            List<string> attendees = new List<string>();
            List<string> attendeeEmails = new List<string>();
            List<string> toRecipients = new List<string>();

            if (string.isNotBlank(skedJob.sked_Customer_Email__c)) {
                toRecipients.add(skedJob.sked_Customer_Email__c);
            }

            for (sked__Job_Allocation__c ja : skedJob.sked__Job_Allocations__r) {
                attendees.add(ja.sked__Resource__r.Name);
                attendeeEmails.add(string.isNotBlank(ja.sked__Resource__r.sked__Email__c) ? ja.sked__Resource__r.sked__Email__c : ja.sked__Resource__r.sked__User__r.Email);
            }
            
            Messaging.EmailFileAttachment[] attachList = new Messaging.EmailFileAttachment[]{};
            string subject = cmService.getEventSubject(skedJob);                
            Blob invite = skedEmailUtil.buildInvitation('prolearning@newsela.com', attendeeEmails, attendees, subject, skedJob.sked__Type__c.contains('Virtual') ? skedJob.sked__Virtual_Meeting_URL__c : skedJob.sked__Address__c, skedJob.sked__Start__c, skedJob.sked__Finish__c, skedJob.sked__Timezone__c);
            strInvite = invite.toString();
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName('appointmentinvite.ics');
            efa.setBody(invite);
            efa.setContentType('text/calendar');
            attachList.add(efa);
            System.debug('skedJob.sked_Appointment_Type__c@' + skedJob.sked_Appointment_Type__c);
            Id templateId = skedJob.sked_Appointment_Type__c.contains(skedConstants.APPOINTMENT_TYPE_VIRTUAL) 
                                ? virtualTemplate.Id 
                                : (skedJob.sked_Appointment_Type__c.contains(skedConstants.APPOINTMENT_TYPE_IN_PERSON) ? inpersonTemplate.Id : callTemplate.Id);
            string template = skedJob.sked_Appointment_Type__c.contains(skedConstants.APPOINTMENT_TYPE_VIRTUAL) 
                                ? virtualTemplate.HtmlValue 
                                : (skedJob.sked_Appointment_Type__c.contains(skedConstants.APPOINTMENT_TYPE_IN_PERSON) ? inpersonTemplate.HtmlValue : callTemplate.HtmlValue);
            string htmlBody = buildHtmlBody(template, skedJob);
            
            Messaging.SingleEmailMessage email = skedEmailUtil.setEmailWithTemplate(subject, toRecipients, attendeeEmails, null, 'prolearning@newsela.com', templateId, toRecipients.isEmpty() ? skedJob.sked__Contact__c : null, null, null, false, attachList, htmlBody);
            emails.add(email);
            htmls.add(htmlBody);
            //emailTasks.add(logTask(skedJob, subject, htmlBody));
        }
        if (!emails.isEmpty()) {
            //Messaging.SendEmailResult[] results = Messaging.sendEmail(emails);

            for (integer i = 0; i < emails.size(); i++) {
                List<Messaging.SingleEmailMessage> sendEmails = new List<Messaging.SingleEmailMessage>();
                sendEmails.add(emails[i]);
                Messaging.SendEmailResult[] results = Messaging.sendEmail(sendEmails);
                system.debug('#send mail '+results);
                if (results != NULL && results[0].isSuccess() == TRUE) {
                    string comment = htmls[i].replace('<br/>', '');
                    comment = comment.replace('<p>', '');
                    comment = comment.replace('</p>', '');
                    emailTasks.add(logTask(skedJobs[i], 'Sending Email Successfully', htmls[i]));
                }
            }

            if (!emailTasks.isEmpty()) {
                insert emailTasks;
                insert new sked__Debug_Log__c(sked__Message__c= strInvite + ' user timezone ' + UserInfo.getTimeZone().getID() + ' start time ' + skedJobs[0].sked__Start__c.format(skedDatetimeUtils.DATE_TIME_FORMAT, skedJobs[0].sked__Timezone__c));
            }
        }
    }

    static string buildHtmlBody(string body, sked__Job__c session) {
        string emailBody = body;
        emailBody = emailBody.replace('[SESSION TYPE]', session.sked__Type__c);
        emailBody = emailBody.replace('[DATE]', session.sked__Start__c.format(skedDateTimeUtils.DATE_FORMAT, session.sked__Timezone__c));
        emailBody = emailBody.replace('[TIME DURATION]', session.sked__Start__c.format(skedDateTimeUtils.TIME_FORMAT, session.sked__Timezone__c));
        emailBody = emailBody.replace('[RESOURCE NAME]', session.sked__Job_Allocations__r[0].sked__Resource__r.Name);
        emailBody = emailBody.replace('[QUESTIONS AND ANSWERS]', session.sked_Additional_Details__c);
        emailBody = emailBody.replace('[ZOOM LINK]', session.sked__Virtual_Meeting_URL__c != NULL ? session.sked__Virtual_Meeting_URL__c : '');
        emailBody = emailBody.replace('[LOCATION]', session.sked__Address__c);
        emailBody = emailBody.replace('[PHONE NUMBER]', string.isNotBlank(session.sked__Job_Allocations__r[0].sked__Resource__r.sked__Primary_Phone__c) ? 
                                                session.sked__Job_Allocations__r[0].sked__Resource__r.sked__Primary_Phone__c : 
                                                (string.isNotBlank(session.sked__Job_Allocations__r[0].sked__Resource__r.sked__Mobile_Phone__c) ?
                                                    session.sked__Job_Allocations__r[0].sked__Resource__r.sked__Mobile_Phone__c : ''));
        emailBody = emailBody.replace('[RESOURCE EMAIL]', session.sked__Job_Allocations__r[0].sked__Resource__r.sked__Email__c);

        return emailBody;
    }

    static Task logTask(sked__Job__c job, string subject, string htmlBody) {
        Task newTask = new Task();
        newTask.OwnerId = UserInfo.getUserId();
        newTask.Subject = subject;
        newTask.Description = htmlBody;
        newTask.ActivityDate = Date.today();
        newTask.ReminderDateTime = Datetime.now();
        newTask.WhoId = job.sked__Contact__c;
        newTask.WhatId = job.Id;

        return newTask;
    }

    /****************Nested Class******************/
    public class emailModel {
        public string htmlBody;
        public Id orgWideEmailId;
        public Id targetObjId;
        public string templateApiName;
        public List<string> toList;
        public Id whatId;
        public string subject;
        
        public emailModel() {
            this.toList = new List<string>();
        }
    }
}
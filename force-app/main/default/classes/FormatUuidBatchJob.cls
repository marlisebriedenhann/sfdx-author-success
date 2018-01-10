global class FormatUuidBatchJob implements
    Database.Batchable<SObject>, Database.Stateful {
    
    global Integer updatedAccountsCount = 0;
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id,UUID__c FROM Account WHERE UUID__c <> NULL');
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accounts) {
        List<Account> updatedAccounts = new List<Account>();
        
        for (Account a : accounts) {
            if (a.UUID__c.length() == (8+4+4+4+12)) {
                String formattedUuid = a.UUID__c.toLowerCase();
                
                formattedUuid = String.format('{0}-{1}-{2}-{3}-{4}', new List<String> {
                    formattedUuid.substring(0,8),
                    formattedUuid.substring(8,12),
                    formattedUuid.substring(12,16),
                    formattedUuid.substring(16,20),
                    formattedUuid.substring(20)
                });
                    
                a.UUID__c = formattedUuid;
                
                updatedAccounts.add(a);
            }
        }
        
        this.updatedAccountsCount = updatedAccounts.size();
        
        update updatedAccounts;
    }
    
    global void finish(Database.BatchableContext bc) {

        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];
        
        String subject = 'UUID Formatting Job ' + job.Status;
        
        String message = String.format('The UUID Formatting Job processed {0} items out of {1} with {2} failures.',
            new List<String> {
                this.updatedAccountsCount.format(),
                job.TotalJobItems.format(),
                job.NumberOfErrors.format()
            });
        
        System.debug(subject + ': ' + message);
        
        /*
        List<SystemSettings__c> settingList = [
            SELECT NotificationEmail__c, EnableNotificationEmails__c
            FROM SystemSettings__c
            LIMIT 1
        ];
        
        if (!settingList.isEmpty()) {
            SystemSettings__c cfg = settingList[0];
            
            if (cfg.EnableNotificationEmails__c == true) {
	            String toAddress = cfg.NotificationEmail__c;
	            
	            System.debug('Notification emails are enabled, will be sent to ' + toAddress);
	            
	            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	            
	            String[] toAddresses = new String[] { toAddress };
	            
	            mail.setToAddresses(toAddresses);
	            mail.setSubject(subject);
	            mail.setPlainTextBody(message);
	            
	            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	        }
        }
        */
    }
}
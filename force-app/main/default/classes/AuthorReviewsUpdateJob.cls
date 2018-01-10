global class AuthorReviewsUpdateJob implements
    Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    
    private static final String PHOTOQC_SYS_NAME = 'PhotoQC';
    private PhotoQCClient client = null;
    
    private Integer targetAccountsCount = 0;
    private Integer updatedAccountsCount = 0;
    private Integer failedAccountsCount = 0;
    
    global AuthorReviewsUpdateJob() {
        this([
            SELECT Host__c, KeyId__c, PrivateKey__c
            FROM SystemSettings__c
            WHERE Name = :PHOTOQC_SYS_NAME
        ]);
    }
    
    global AuthorReviewsUpdateJob(SystemSettings__c conn) {
        this(conn.Host__c, conn.KeyId__c, conn.PrivateKey__c);
    }
    
    global AuthorReviewsUpdateJob(String host, String keyId, String privateKey) {
        this.client = new PhotoQCClient(host, keyId, privateKey);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id,UUID__c,TotalReviewedItems__c,TotalAcceptableItems__c ' +
            'FROM Account ' + 
            'WHERE UUID__c LIKE \'________-____-____-____-____________\''
        );
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accounts) {
        this.targetAccountsCount += accounts.size();
        
        List<Account> accountsToUpdate = new List<Account>();
        
        for (Account a : accounts) {
            try {
                PhotoQCClient.AuthorReviews reviews = this.client.getReviewsForAuthor(a.UUID__c);
                
                a.TotalReviewedItems__c = reviews.seen;
                a.TotalAcceptableItems__c = reviews.seen - reviews.negatively_flagged;
                
                accountsToUpdate.add(a);
                
                this.updatedAccountsCount++;
            }
            catch (PhotoQCClient.RequestException ex) {
                this.failedAccountsCount++;
                
                System.debug('Error while retrieving data for account ' + a.Id);
                System.debug(ex);
            }
        }
        
        update accountsToUpdate;
    }
    
    global void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];
        
        String subject = 'Author Reviews Update Job ' + job.Status;
        
        String message = String.format(
            'Author Reviews Update Job has processed {0} account(s) in {1} batch(es), resulting in {2} account(s) updated successfully, {3} batch-processing failure(s) and {4} integration failure(s).',
            new List<String> {
                this.targetAccountsCount.format(),
                job.TotalJobItems.format(),
                this.updatedAccountsCount.format(),
                job.NumberOfErrors.format(),
                this.failedAccountsCount.format()
            });
        
        System.debug(subject + ': ' + message);
    }
}
@isTest
public class FormatUuidBatchJobTest {
    @isTest
    public static void ignores_accounts_with_no_uuid() {
        Integer testAccountsCount = 100;
        
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < testAccountsCount; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                UUID__c = null
            ));
        }
        
        insert testAccounts;
        
        Test.startTest();
        
        FormatUuidBatchJob batchJob = new FormatUuidBatchJob();
        
        ID jobId = Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        System.AssertEquals(testAccountsCount, [SELECT COUNT() FROM Account WHERE UUID__c = NULL]);
    }
    
    @isTest
    public static void ignores_accounts_with_formatted_uuid() {
        Integer testAccountsCount = 100;
        String testUuidPrefix = '10000000-7e57-7e57-7e57-000000000';
        
        List<Account> testAccounts = new List<Account>();
        List<String> testUuids = new List<String>();
        
        for (Integer i = 0; i < testAccountsCount; i++) {
            String testUuid = i < 10
                    ? testUuidPrefix + '00' + i
                    : i < 100
                        ? testUuidPrefix + '0' + i
                        : testUuidPrefix + i;
            
            testUuids.add(testUuid);
            
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                UUID__c = testUuid 
            ));
        }
        
        insert testAccounts;
        
        Test.startTest();
        
        FormatUuidBatchJob batchJob = new FormatUuidBatchJob();
        
        ID jobId = Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        System.assertEquals(testAccountsCount, [SELECT COUNT() FROM Account WHERE UUID__c IN :testUuids]);
    }
    
    @isTest
    public static void updates_accounts_with_unformatted_uuid() {
        Integer testAccountsCount = 100;
        String testUuidPrefix = '100000007e577e577e57000000000';
        
        List<Account> testAccounts = new List<Account>();
        List<String> testUuids = new List<String>();
        
        for (Integer i = 0; i < testAccountsCount; i++) {
            String testUUid = i < 10
                    ? testUuidPrefix + '00' + i
                    : i < 100
                        ? testUuidPrefix + '0' + i
                        : testUuidPrefix + i;
            
            testUuids.add(testUuid);
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                UUID__c = testUuid
            ));
        }
        
        insert testAccounts;
        
        /*
        SystemSettings__c cfg = new SystemSettings__c(
            NotificationEmail__c = 'samss@envato.com',
            EnableNotificationEmails__c = true
        );
        
        insert cfg;
        */
        
        Test.startTest();
        
        FormatUuidBatchJob batchJob = new FormatUuidBatchJob();
        
        ID jobId = Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE UUID__c IN :testUuids]);
    }
}
@isTest
public class AuthorReviewsUpdateJobTest {    
    @isTest
    public static void account_item_counts_update_successfully() {
        Test.setMock(HttpCalloutMock.class, new PhotoQCClientTest.AuthorDataResponder());
        
        Integer testAccountsCount = 100;
        
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < testAccountsCount; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                UUID__c = generateTestUuidForIndex(i)
            ));
        }
        
        insert testAccounts;
        
        Test.startTest();
        
        AuthorReviewsUpdateJob batchJob = new AuthorReviewsUpdateJob(TestUtil.TEST_HOST, TestUtil.TEST_KEY_ID, TestUtil.TEST_PRIVATE_KEY);
        
        ID jobId = Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        System.assertEquals(testAccountsCount, [SELECT COUNT() FROM Account WHERE TotalReviewedItems__c > 0 AND TotalAcceptableItems__c > 0]);
    }
    
    @isTest
    public static void accounts_failed_to_update_dont_abort_job() {
        Test.setMock(HttpCalloutMock.class, new PhotoQCClientTest.UnreliableAuthorDataResponder(2));
        
        Integer testAccountsCount = 100;
        Integer expectedUpdatedTestAccountsCount = 50;
        
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < testAccountsCount; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                UUID__c = generateTestUuidForIndex(i)
            ));
        }
        
        insert testAccounts;
        
        Test.startTest();
        
        AuthorReviewsUpdateJob batchJob = new AuthorReviewsUpdateJob(TestUtil.TEST_HOST, TestUtil.TEST_KEY_ID, TestUtil.TEST_PRIVATE_KEY);
        
        ID jobId = Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        System.assertEquals(expectedUpdatedTestAccountsCount, [SELECT COUNT() FROM Account WHERE TotalReviewedItems__c > 0 AND TotalAcceptableItems__c > 0]);
    }
    
    @isTest
    public static void accounts_with_invalid_uuids_are_ignored() {
        Integer testAccountsCount = 100;
        
        List<Account> testAccounts = new List<Account>();
        
        for (Integer i = 0; i < testAccountsCount; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                UUID__c = generateTestUuidForIndex(i) + '-ThisIsNotValid'
            ));
        }
        
        insert testAccounts;
        
        Test.startTest();
        
        AuthorReviewsUpdateJob batchJob = new AuthorReviewsUpdateJob(TestUtil.TEST_HOST, TestUtil.TEST_KEY_ID, TestUtil.TEST_PRIVATE_KEY);
        
        ID jobId = Database.executeBatch(batchJob);
        
        Test.stopTest();
        
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE TotalReviewedItems__c > 0 AND TotalAcceptableItems__c > 0]);
    }
    
    @isTest
    public static void throws_when_no_system_settings_exist() {
        Exception expectedException = null;
        
        try {
            new AuthorReviewsUpdateJob();
        }
        catch (Exception e) {
            expectedException = e;
        }
        
        System.assertNotEquals(null, expectedException);
    }
    
    private static String generateTestUuidForIndex(Integer index) {
        Map<Integer,String> uuidPrefixes = new Map<Integer,String>{
            3 => '00000000-0000-0000-0000-000000000',
            2 => '00000000-0000-0000-0000-0000000000',
            1 => '00000000-0000-0000-0000-00000000000'
        };
        
        String suffix = index.format();
        
        return uuidPrefixes.get(suffix.length()) + suffix;
    }
}
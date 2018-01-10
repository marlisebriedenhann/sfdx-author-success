@isTest
public class AuthorReviewsUpdateSchedulerTest {
    @isTest
    public static void account_item_counts_update_successfully() {
        Test.setMock(HttpCalloutMock.class, new PhotoQCClientTest.AuthorDataResponder());
        
        String schedule = '00 00 12 * * ?';
        
        List<Account> testAccounts = new List<Account>{
            new Account(
                Name = 'Test Account',
                UUID__c = '00000000-7357-7357-7357-000000000000'
            )
        };
        
        insert testAccounts;
        
        SystemSettings__c conn = new SystemSettings__c(
            Name = 'PhotoQC',
            Host__c = TestUtil.TEST_HOST,
            KeyId__c = TestUtil.TEST_KEY_ID,
            PrivateKey__c = TestUtil.TEST_PRIVATE_KEY
        );
        
        insert conn;
        
        Test.startTest();
        
        AuthorReviewsUpdateScheduler job = new AuthorReviewsUpdateScheduler();
        ID jobId = System.schedule('Test Author Reviews Update Batch Job', schedule, job);
        
        Test.stopTest();
        
        System.assertNotEquals(null, jobId);
    }
}
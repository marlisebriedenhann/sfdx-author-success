@isTest
public class PhotoQCClientTest {
    @isTest
    public static void throws_when_no_host_specified() {
        PhotoQCClient.InvalidArgumentException expectedException = null;
        
        try {
            new PhotoQCClient(null, TestUtil.TEST_KEY_ID, TestUtil.TEST_PRIVATE_KEY);
        }
        catch (PhotoQCClient.InvalidArgumentException e) {
            expectedException = e;
        }
        
        System.assertNotEquals(null, expectedException);
    }
    
    @isTest
    public static void throws_when_no_keyid_specified() {
        PhotoQCClient.InvalidArgumentException expectedException = null;
        
        try {
            new PhotoQCClient(TestUtil.TEST_HOST, null, TestUtil.TEST_PRIVATE_KEY);
        }
        catch (PhotoQCClient.InvalidArgumentException e) {
            expectedException = e;
        }
        
        System.assertNotEquals(null, expectedException);
    }
    
    @isTest
    public static void throws_when_no_private_key_specified() {
        PhotoQCClient.InvalidArgumentException expectedException = null;
        
        try {
            new PhotoQCClient(TestUtil.TEST_HOST, TestUtil.TEST_KEY_ID, null);
        }
        catch (PhotoQCClient.InvalidArgumentException e) {
            expectedException = e;
        }
        
        System.assertNotEquals(null, expectedException);
    }
    
    @isTest
    public static void throws_when_author_not_found() {
        Test.setMock(HttpCalloutMock.class, new AuthorNotFoundResponder());
        
        String testUuid = '10000000-7e57-7e57-7e57-000000000001';
        
        PhotoQCClient.RequestException expectedException = null;
        
        try {
            PhotoQCClient client = new PhotoQCClient(TestUtil.TEST_HOST, TestUtil.TEST_KEY_ID, TestUtil.TEST_PRIVATE_KEY);
            client.getReviewsForAuthor(testUuid);
        }
        catch (PhotoQCClient.RequestException e) {
            expectedException = e;
        }
        
        System.assertNotEquals(null, expectedException);
        System.assertEquals('404 Not Found', expectedException.getMessage());
    }
    
    @isTest
    public static void throws_when_internal_error() {
        Test.setMock(HttpCalloutMock.class, new InternalErrorResponder());
        
        String testUuid = '10000000-7e57-7e57-7e57-000000000001';
        
        PhotoQCClient.RequestException expectedException = null;
        
        try {
            PhotoQCClient client = new PhotoQCClient(TestUtil.TEST_HOST, TestUtil.TEST_KEY_ID, TestUtil.TEST_PRIVATE_KEY);
            client.getReviewsForAuthor(testUuid);
        }
        catch (PhotoQCClient.RequestException e) {
            expectedException = e;
        }
        
        System.assertNotEquals(null, expectedException);
        System.assertEquals('500 Internal Server Error', expectedException.getMessage());
    }
    
    @isTest
    public static void returns_author_reviews() {
        Test.setMock(HttpCalloutMock.class, new AuthorDataResponder());
        
        String testUuid = '10000000-7e57-7e57-7e57-000000000001';
        
        PhotoQCClient client = new PhotoQCClient(TestUtil.TEST_HOST, TestUtil.TEST_KEY_ID, TestUtil.TEST_PRIVATE_KEY);
        PhotoQCClient.AuthorReviews reviews = client.getReviewsForAuthor(testUuid);
        
        System.assertEquals(1000, reviews.uploaded);
        System.assertEquals(800, reviews.seen);
        System.assertEquals(200, reviews.negatively_flagged);
        System.assertEquals(100, reviews.flags.outstanding);
        System.assertEquals(200, reviews.flags.unacceptable);
        System.assertEquals(300, reviews.flags.legal);
    }
    
    public class AuthorNotFoundResponder implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatus('Not Found');
            res.setStatusCode(404);
            return res;
        }
    }
    
    public class InternalErrorResponder implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatus('Internal Server Error');
            res.setStatusCode(500);
            return res;
        }
    }
    
    public class AuthorDataResponder implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('Found');
            res.setStatusCode(200);
            res.setBody('{"data":{"author":{"uploaded":1000,"seen":800,"negatively_flagged":200,"flags":{"outstanding":100,"unacceptable":200,"legal":300}}}}');
            return res;
        }
    }
    
    public class UnreliableAuthorDataResponder implements HttpCalloutMock {
        Integer failEvery = null;
        Integer callCount = 0;
        
        public UnreliableAuthorDataResponder(Integer failEvery) {
            this.failEvery = failEvery;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            
            this.callCount++;
            
            if (Math.mod(this.callCount, this.failEvery) == 0) {
                res.setStatus('Internal Server Error');
                res.setStatusCode(500);
            }
            else {
                res.setHeader('Content-Type', 'application/json');
                res.setStatus('Found');
                res.setStatusCode(200);
                res.setBody('{"data":{"author":{"uploaded":1000,"seen":800,"negatively_flagged":200,"flags":{"outstanding":100,"unacceptable":200,"legal":300}}}}');
            }

            return res;
        }
    }
}
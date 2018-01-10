public class PhotoQCClient {
    private static Blob emptyBlob = Blob.valueOf('');

    private String host;
    private String keyId;
    private Blob privateKey;

    public PhotoQCClient(String host, String keyId, String privateKey) {
        if (host == null) {
            throw new InvalidArgumentException('host');
        }
        
        if (keyId == null) {
            throw new InvalidArgumentException('keyId');
        }
        
        if (privateKey == null) {
            throw new InvalidArgumentException('privateKey');
        }
        
        this.host = host;
        this.keyId = keyId;
        this.privateKey = EncodingUtil.base64decode(privateKey);
    }

    public AuthorReviews getReviewsForAuthor(String uuid) {
        String method = 'GET';
        String path = '/authors/' + uuid;
        
        Map<String,String> signatureHeaders = new Map<String,String>{
            'kid' => this.keyId,
            'alg' => 'RS256',
            'typ' => 'JWT'
        };
        
        Map<String, String> headers = new Map<String,String>{
            'Content-Type' => 'application/json'
        };
        
        Map<String,Object> signaturePayload = new Map<String,Object> {
            'headers' => JSON.serialize(headers),
            'method' => method,
            'path' => path,
            'body_sha' => generateBodySha(''),
            'exp' => (DateTime.now().getTime()/1000)+60
        };
        
        HttpRequest request = new HttpRequest();
        request.setMethod(method);
        request.setEndpoint(this.host + path);
        
        for (String header : headers.keySet()) {
            request.setHeader(header, headers.get(header));
        }
        
        request.setHeader('Authorization', jwt(signatureHeaders, signaturePayload, privateKey));
        
        Http httpClient = new Http();
        
        HttpResponse response = httpClient.send(request);
        
        String responseBody = response.getBody();
        
        System.debug(responseBody);
        
        if (response.getStatusCode() != 200) {
            throw new RequestException('' + response.getStatusCode() + ' ' + response.getStatus());
        }
        
        AuthorsResponse authorsResponse = (AuthorsResponse)JSON.deserialize(responseBody, Type.forName('PhotoQCClient.AuthorsResponse'));
        
        return authorsResponse.data.author;
    }
    
    private static String jwt(Map<String,String> header, Map<String,Object> payload, Blob privateKey) {
        String serializedHeader = JSON.serialize(header);
        String serializedPayload = JSON.serialize(payload);
        
        String unsignedJwt = base64URLEncode(Blob.valueOf(serializedHeader)) + '.' + base64URLEncode(Blob.valueOf(serializedPayload));
        
        Blob signature = Crypto.sign('RSA-SHA256', Blob.valueOf(unsignedJwt), privateKey);

        String jwt = unsignedJwt + '.' + base64URLEncode(signature);
        
        return jwt;
    }
    
    private static String base64URLEncode(Blob input) {
        String encoded = EncodingUtil.base64Encode(input);
        encoded = encoded.replace('+', '-');
        encoded = encoded.replace('/', '_');
        
        while (encoded.endsWith('=')) {
            encoded = encoded.subString(0, encoded.length()-1);
        }
        
        return encoded;
    }
    
    private static String generateBodySha(String body) {        
        Blob binaryHash = Crypto.generateDigest('SHA-256', Blob.valueOf(body));        
        return EncodingUtil.convertToHex(binaryHash);
    }
    
    public class AuthorsResponse {
        public AuthorsResponseData data;
    }
    
    public class AuthorsResponseData {
        public AuthorReviews author;
    }
    
    public class AuthorReviews {
        public Integer uploaded;
        public Integer seen;
        public Integer negatively_flagged;
        public Flags flags;
    }
    
    public class Flags {
        public Integer outstanding;
        public Integer unacceptable;
        public Integer legal;
    }
    
    public class RequestException extends Exception {  }
    public class InvalidArgumentException extends Exception { }
}
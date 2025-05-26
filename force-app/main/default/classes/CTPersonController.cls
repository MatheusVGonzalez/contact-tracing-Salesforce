public class CTPersonController {
    public static String getToken(String mobileNo){
        Blob mobileCrypto = Blob.valueOf(mobileNo); //generating a crpto value using mobile no that user provided
        Blob hash = Crypto.generateDigest('MD5', mobileCrypto); //method that takes a string and returns a hash using generateDigest
        String token = EncodingUtil.base64Encode(hash); // transforming the hash value into String value
        return token; //return this value

    }
}
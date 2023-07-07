public  class skedExceptionHandler {
    // Wrapper class for my custom exception data
    public class CustomException extends Exception {
        public String name;
        public String message;        
        public integer statusCode;
        public string status;
        public string response;
        public CustomException(String name, String message) {
            this.name = name;
            this.message = message;            
        }

        public CustomException(integer statusCode, string status, string response) {
            this.statusCode = statusCode;
            this.status = status;
            this.response = response;
        }
    }

    //insert debug log record to track error later - useful for batch debugging
    // public static void logError(String type, String message) {
    //     insert new sked__Debug_Log__c(
    //         sked__Type__c = type,
    //         sked__Message__c = message
    //     );
    // }
}
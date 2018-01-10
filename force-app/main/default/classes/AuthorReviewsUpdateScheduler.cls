global class AuthorReviewsUpdateScheduler implements Schedulable {
    private static final Integer MAX_ACCOUNTS_PER_BATCH = 100;
    
    global void execute(SchedulableContext sc) {
        AuthorReviewsUpdateJob batchJob = new AuthorReviewsUpdateJob();
        ID batchJobId = Database.executeBatch(batchJob, MAX_ACCOUNTS_PER_BATCH);
        System.debug('Author Reviews Update Job scheduled for execution with ID ' + batchJobId);
    }
}
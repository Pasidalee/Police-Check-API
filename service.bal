import ballerina/http;
import ballerinax/postgresql;
import ballerina/log;
import ballerina/sql;

configurable string host = ?;
configurable string username = ?;
configurable string password = ?;
configurable string database = ?;
configurable int port = ?;

const APPROVED = "approved";
const DECLINED = "declined";
const PENDING = "pending";
const NO_ROWS_ERROR_MSG = "Query did not retrieve any rows.";
const USER_NOT_FOUND = "User not found";

isolated service / on new http:Listener(9093) {
    private final postgresql:Client dbClient;

    public isolated function init() returns error? {
        // Initialize the database
        self.dbClient = check new (host, username, password, database, port);
    }

    isolated resource function get policecheck(string userId) returns error? {
        log:printInfo("Received request for police check for user: ", userId = userId);
        boolean policeClearance = check getPoliceStatus(userId, self.dbClient);
        if policeClearance {
            _ = check updateValidation(userId, self.dbClient);
        }
        _ = check updateStatus(userId, PENDING, self.dbClient);
    }
}

isolated function getPoliceStatus(string userId, postgresql:Client dbClient) returns boolean|error {
    sql:ParameterizedQuery query = `SELECT police_check FROM user_details WHERE user_id = ${userId}`;
    return dbClient->queryRow(query);
}

isolated function updateValidation(string userId, postgresql:Client dbClient) returns error? {
    sql:ParameterizedQuery query = `UPDATE certificate_requests SET police_check = true WHERE user_id = ${userId} AND status != ${APPROVED} 
            AND status != ${DECLINED}`;
    _ = check dbClient->execute(query);
}

isolated function updateStatus(string userId, string status, postgresql:Client dbClient) returns error? {
    sql:ParameterizedQuery query = `UPDATE certificate_requests SET status = ${status} WHERE user_id = ${userId} AND 
            status != ${APPROVED} AND status != ${DECLINED}`;
    _ = check dbClient->execute(query);
}

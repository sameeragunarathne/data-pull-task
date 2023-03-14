import ballerina/http;
import ballerina/log;


configurable string raapidAIServiceUrl = "http://localhost:9092";
configurable string dataSyncServiceUrl = "http://localhost:9091";

final http:Client raapidAIAPI = check new (raapidAIServiceUrl);
final http:Client dataSyncAPI = check new (dataSyncServiceUrl);

public function main() returns error? {
    json payload = {id: "1"};
    do {
        http:Response data = check dataSyncAPI->post("/v2tofhir/transform", payload);
        json dataJson = check data.getJsonPayload();
        http:Response patientAPIResponse = check raapidAIAPI->post("/r4/Patient", dataJson);
        if patientAPIResponse.statusCode == http:STATUS_CREATED {
            log:printInfo("Patient created successfully");
        } else {
            log:printError("Error while creating patient");
        }
    } on fail error e {
        log:printError("Error while executing the data pull task", err = e.message());
    }

}

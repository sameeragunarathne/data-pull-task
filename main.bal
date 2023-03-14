import ballerina/http;
import ballerina/log;

// configurable string raapidAIServiceUrl = "http://localhost:9092";
// configurable string dataSyncServiceUrl = "http://localhost:9091";


configurable DataSyncConfig dataSyncConfig = {
    raapidAIServiceUrl: "http://localhost:9092",
    dataSyncServiceUrl: "http://localhost:9091",
    raapidAIAPIConfig: {
        "Patient": "/r4/Patient"
    },
    payloadConfig: {
        "Patient": "{\"id\": \"1\", \"resourceType\": \"Patient\"}"
    }
};

final http:Client raapidAIAPI = check new (dataSyncConfig.raapidAIServiceUrl);
final http:Client dataSyncAPI = check new (dataSyncConfig.dataSyncServiceUrl);

public function main() returns error? {
    do {
        foreach var [key, value] in dataSyncConfig.raapidAIAPIConfig.entries() {
            http:Response data = check dataSyncAPI->post("/sync", dataSyncConfig.payloadConfig[key]);
            json dataJson = check data.getJsonPayload();
            log:printInfo("Data received from data sync service", data = dataJson.toString());
            http:Response fhirAPIResponse = check raapidAIAPI->post(value, dataJson);
            if fhirAPIResponse.statusCode == http:STATUS_CREATED {
                log:printInfo(string`${key} Resource created successfully`);
            } else {
                log:printError(string`Error while creating ${key} FHIR Resource`);
            }
        }
    } on fail error e {
        log:printError("Error while executing the data pull task", err = e.message());
    }

}

public type DataSyncConfig record {
    string raapidAIServiceUrl;
    string dataSyncServiceUrl;
    map<string> raapidAIAPIConfig;
    map<string> payloadConfig;
};

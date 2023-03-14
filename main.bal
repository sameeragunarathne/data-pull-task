import ballerina/http;
import ballerina/log;

configurable DataSyncConfig dataSyncConfig = {
    raapidAIServiceUrl: "http://localhost:9092",
    dataSyncServiceUrl: "http://localhost:9091",
    raapidAIAPIConfig: {
        "Patient": "/r4/Patient",
        "Encounter": "/r4/Encounter"
    },
    payloadConfig: {
        "Patient": "{\"id\": \"eBZnFnAwp8rVbEJP1yHg7rw3\", \"resourceType\": \"Patient\"}",
        "Encounter": "{\"id\": \"elC.GW.gA0.Ex86-vRDqmlw3\", \"resourceType\": \"Encounter\"}" 
    }
};

final http:Client raapidAIAPI = check new (dataSyncConfig.raapidAIServiceUrl);
final http:Client dataSyncAPI = check new (dataSyncConfig.dataSyncServiceUrl);

public function main() returns error? {
    do {

        foreach var [key, value] in dataSyncConfig.raapidAIAPIConfig.entries() {
            string payloadStr = <string>dataSyncConfig.payloadConfig[key];
            log:printInfo("Payload received from config", payload = payloadStr);
            json payload = check payloadStr.fromJsonString();
            http:Response data = check dataSyncAPI->post("/sync", payload);
            json dataJson = check data.getJsonPayload();
            log:printInfo("Data received from data sync service", data = dataJson.toString());
            http:Response patientAPIResponse = check raapidAIAPI->post(value, dataJson);
            if patientAPIResponse.statusCode == http:STATUS_CREATED {
                log:printInfo(string `${key} created successfully`);
            } else {
                log:printError(string `Error while creating ${key}`);
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

public type FHIRAPIConfig record {
    string 'type;
    string rapidAIAPIContext;
    json payload;
};

import ballerina/http;
import ballerina/log;

// configurable string raapidAIServiceUrl = "http://localhost:9092";
// configurable string dataSyncServiceUrl = "http://localhost:9091";
// configurable map<string> raapidAIAPIConfig = {
//     "Patient": "/r4/Patient",
//     "Encounter": "/r4/Encounter"
// };
// configurable json payload = {id: "1"};
configurable DataSyncConfig dataSyncConfig = {
    raapidAIServiceUrl: "http://localhost:9092",
    dataSyncServiceUrl: "http://localhost:9091",
    fhirAPIConfig: {
        "Patient": {
            rapidAIAPIContext: "/r4/Patient",
            payload: {
                id: "eBZnFnAwp8rVbEJP1yHg7rw3",
                resourceType: "Patient"
            }
        },
        "Encounter": {
            rapidAIAPIContext: "/r4/Encounter",
            payload: {
                id: "elC.GW.gA0.Ex86-vRDqmlw3",
                resourceType: "Encounter"
            }
        }
    }
};

final http:Client raapidAIAPI = check new (dataSyncConfig.raapidAIServiceUrl);
final http:Client dataSyncAPI = check new (dataSyncConfig.dataSyncServiceUrl);

public function main() returns error? {
    do {
        foreach var [key, value] in dataSyncConfig.fhirAPIConfig.entries() {
            http:Response data = check dataSyncAPI->post("/sync", value.payload);
            json dataJson = check data.getJsonPayload();
            log:printInfo("Data received from data sync service", data = dataJson.toString());
            http:Response patientAPIResponse = check raapidAIAPI->post(value.rapidAIAPIContext, dataJson);
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
    map<FHIRAPIConfig> fhirAPIConfig;
};

public type FHIRAPIConfig record {
    string rapidAIAPIContext;
    json payload;
};

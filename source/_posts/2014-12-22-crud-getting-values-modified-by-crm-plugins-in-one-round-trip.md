---
layout: post
published: true
title: "CRUD - getting values modified by CRM plugins in one round trip."
comments: true
categories: Dynamics CRM
---

## Scenario

Say you have a plugin on the `account` entity that:

- Runs synchronously
- Generates a reference number for the account.

Now assume we have an application that's on a seperate server to the CRM server (so latency and network traffic are a concern).

The application needs to:

1. Create a contact in crm
2. Get the reference number that was generated for the contact.

## The Multiple Roundtrip Way
The most common way I have seen this dealt with is to do 2 seperate roundtrips with CRM:

1. Create the account
2. Retrieve the account

## The Modern Approcah
For quite some time now - as of `CRM 2011 Update Rollup 12 - (SDK 5.0.13)` you can utilise the [Execute Multiple](http://msdn.microsoft.com/en-gb/library/jj863604(v=crm.5).aspx) request to do this kind of thing in one roundtrip with the CRM server.

For example:

``` csharp
 				IOrganizationService orgService = GetOrganizationService();

                // Create an ExecuteMultipleRequest object.
                var requestWithResults = new ExecuteMultipleRequest()
                {
                    // Assign settings that define execution behavior: continue on error, return responses. 
                    Settings = new ExecuteMultipleSettings()
                    {
                        ContinueOnError = false,
                        ReturnResponses = true                        
                    },
                    // Create an empty organization request collection.
                    Requests = new OrganizationRequestCollection()
                };

				// Create a new account entity.
                var entity = new Entity("account");
                entity.Id = Guid.NewGuid();
                entity["name"] = "experimental test";

                CreateRequest createRequest = new CreateRequest { Target = entity };
                RetrieveRequest retrieveRequest = new RetrieveRequest { Target = new EntityReference(entity.LogicalName, entity.Id), ColumnSet = new ColumnSet(true) };

                requestWithResults.Requests.Add(createRequest);
                requestWithResults.Requests.Add(retrieveRequest);

                // Execute all the requests in the request collection using a single web method call.
                ExecuteMultipleResponse responseWithResults =
                    (ExecuteMultipleResponse)orgService.Execute(requestWithResults);


                // Display the results returned in the responses.
                foreach (var responseItem in responseWithResults.Responses)
                {
                    // A valid response.
                    if (responseItem.Response != null)
                        DisplayResponse(requestWithResults.Requests[responseItem.RequestIndex], responseItem.Response);

                    // An error has occurred.
                    else if (responseItem.Fault != null)
                        DisplayFault(requestWithResults.Requests[responseItem.RequestIndex],
                            responseItem.RequestIndex, responseItem.Fault);

                }            

```



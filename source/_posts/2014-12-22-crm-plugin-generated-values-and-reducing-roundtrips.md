---
layout: post
published: true
title: "CRM / Plugin Generated Values - and Reducing Roundtrips!"
comments: true
categories: Dynamics CRM
---

Just a short post this week, with a little CRM development pro tip for you!

## Scenario
Say you have a plugin on the `account` entity that:

- Runs synchronously on create
- Generates a reference number for the account.

Now assume we have an application that's on a seperate server to the CRM server (where latency and network traffic are a concern).

The application needs to:

1. Create a contact in crm
2. Get the reference number that was generated for the contact.

## The Multiple Roundtrip Way
The most common way (the historical way) I have seen this dealt with is to do 2 seperate roundtrips with CRM:

1. Create the account
2. Retrieve the account

This obviously incurs the penalty of making two roundtrips with the server.

## The Pro Way!
For quite some time now - as of `CRM 2011 Update Rollup 12 - (SDK 5.0.13)` you can utilise the [Execute Multiple](http://msdn.microsoft.com/en-gb/library/jj863604(v=crm.5).aspx) request to do this kind of thing in one roundtrip with the CRM server.

Here is an example:

``` csharp
 				 // Create an ExecuteMultipleRequest object.
                var multipleRequests = new ExecuteMultipleRequest()
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

                var entity = new Entity("account");
                entity.Id = Guid.NewGuid();
                entity["name"] = "experimental test";

                CreateRequest createRequest = new CreateRequest
                {
                    Target = entity
                };

                RetrieveRequest retrieveRequest = new RetrieveRequest
                {
                    Target = new EntityReference(entity.LogicalName, entity.Id),
                    ColumnSet = new ColumnSet("createdon")
                };

                multipleRequests.Requests.Add(createRequest);
                multipleRequests.Requests.Add(retrieveRequest);

                // Execute all the requests in the request collection using a single web method call.
                ExecuteMultipleResponse responseWithResults = (ExecuteMultipleResponse)orgService.Execute(multipleRequests);
                             
                var createResponseItem = responseWithResults.Responses[0];
                CreateResponse createResponse = null;
                if (createResponseItem.Response != null)
                {
                    createResponse = (CreateResponse)createResponseItem.Response;
                }

                var retrieveResponseItem = responseWithResults.Responses[1];

                RetrieveResponse retrieveResponse = null;
                if (retrieveResponseItem.Response != null)
                {
                    retrieveResponse = (RetrieveResponse)retrieveResponseItem.Response;
                }

                Console.Write(retrieveResponse.Entity["createdon"]);

```

## What happened?
Both the CreateRequest, and the RetrieveRequest (for the created entity) are batched up into a single Request and shipped off to the CRM server for processing.

CRM processed them in that order, collated the responses together, and returned them in a single batch.

## Caveats
One caveat of this approach is that, if you intend to grab the generated values for an entity that is being created, then you need to know in advance what the ID will be.

This means you have to specify the ID of the entity when you create it. 

For updates / deletes this isn't an issue, as the ID is allready known.

## Any SQL Guru's out there?
Specifying your own ID's _might be a bad thing_ if you don't use Sequential Guid's.
When CRM generates Id's, it generates them sequentially. I beleive there are SQL performance benefits to this in terms of index optimisation etc. 

When you specify your own Id's, if you don't specify them sequentially, i.e  Guid.NewGuid(), this could well have a negative overhead on the DB - that's purely my suspicion - I am no SQL expert, - I'd love to see someone look into that further!
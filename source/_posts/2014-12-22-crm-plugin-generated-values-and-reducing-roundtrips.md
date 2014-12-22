---
layout: post
published: true
title: "CRM / Plugin Generated Values - and Reducing Roundtrips!"
comments: true
categories: Dynamics CRM
---

## Setting the Scene
Let's imagine we have an application that's on a seperate server to the CRM web server, and that latency between our server and the CRM web server is not negligible. 

We want our application to perform lightning fast, and so we look at ways we can minimise the number of request / response (roundtrips) that our application makes to CRM. 

## SuperDuper CRM Solution
As part of our `SuperDuper` CRM solution, we have a plugin on the `account` entity that:

- Runs synchronously on create
- Generates a reference number for the account.

## The Goal

Now, using the SDK, how can you create a new `account` and get access to the newly generated reference number, all in one round trip to the CRM server? I'll show you.

<!-- more -->
Now 

The application needs to:

1. Create a contact in crm
2. Get the reference number that was generated as a result of the create (perhaps it displays it in a UI).

## Multiple Roundtrips - The 'Historical' Way!
The historical way of dealing with this is to do 2 seperate roundtrips with CRM:

1. Create the account
2. Retrieve the account (with the generated values that you need)

This approach is now no longer optimal where latency is a concern, as it incurs the penalty of making two roundtrips accross the network to the CRM server.

## Enter ~~the Dragon~~ this weeks pro tip!
For quite some time now - as of `CRM 2011 Update Rollup 12 - (SDK 5.0.13)` you can utilise the [Execute Multiple](http://msdn.microsoft.com/en-gb/library/jj863604(v=crm.5).aspx) request to do this kind of thing in one roundtrip with the CRM server.

Here is an example of doing this:

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
                    ColumnSet = new ColumnSet("createdon") // list the fields that you want here
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

                Console.Write(retrieveResponse.Entity["createdon"]); // yup - we got the value we needed!

```

## What happened?
Both the CreateRequest, and the RetrieveRequest (for the created entity) are batched up into a single Request and shipped off to the CRM server for processing.

CRM processed them in that order, collated the responses together, and returned them in a single batch.

## Caveats
One caveat of this approach is that, if you intend to grab the generated values for an entity that is being created, then you need to know in advance what the ID will be.

This means you have to specify the ID of the entity when you create it. 

For updates / deletes this isn't an issue, as the ID is allready known.

## Is there a SQL Optimisation Guru present?
I speculate that specifying your own ID's _might be a bad thing_ if you don't use Sequential Guid's.

When CRM generates Id's, it generates them sequentially, and I beleive there may be SQL performance benefits to this in terms of index optimisation etc. So if using Guid.NewGuid() you may want to check with a SQL guru first to understand any impact of using random Guid's as Id's! That said - Microsoft do support it.
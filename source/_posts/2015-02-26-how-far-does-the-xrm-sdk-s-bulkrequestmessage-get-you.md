---
layout: post
published: true
title: "How far does the XRM SDK's BulkRequestMessage get you?"
comments: true
---

## BulkRequestMessage

In this post, I will explore what kinds of things can be achieved using the SDK's BulkRequestMessage, by starting of with a simple SQL command, and implementing the equivalent using BulkRequestMessage, and then slowly introducing some additional complexity - until, as we will see - the SDK starts to fall short!

<!-- more -->

## Starting Simple
Consider this:

```sql
INSERT INTO contact (firstname, lastname) VALUES ('albert', 'einstein');
```

Well you hardly need a BulkRequestMessage for this, but if you really wanted to you could create one no problems. I am going to assume you are already familiar with the code to create a BulkRequestMessage - if not it's described [here.](https://msdn.microsoft.com/en-gb/library/jj863631.aspx)

This equates to the following:

Either:
1. A single CreateRequestMessage
2. A BulRequestMessage containing an single CreateRequestMessage.

I hope you are with me so far..

## Take It Up A Notch

Let's now imagine that when a contact is INSERTED, an `accountnumber` is generated on the server, and that we want to grab this value using a single roundtrip with the server.

Here's it is in T-SQL:

```sql
INSERT INTO contact (firstname, lastname) OUTPUT inserted.accountnumber VALUES ('albert', 'einstein');
```

This equates to the following using the SDK:

SORRRY DAVE. YOU CAN'T DO THAT.

The problem being, is that to do this in one roundtrip with the CRM server means building a BulRequestMessage that contains:-
1. A CreateRequestMessage (to insert / create the contact)
2. A RetrieveRequestMessage (to retrieve the accountnumber of the inserted contact)

However in order to construct the appropriate RetrieveRequestMessage we need to know the ID of what the inserted contact will be in advance. If you look at the SQL query - we are not specifying an ID in advance - therefore we cannot perform the equivalent to this query.

## A bit further..

With the previous example in mind, consider the following SQL

```sql
INSERT INTO contact (contactid, firstname, lastname) OUTPUT inserted.accountnumber VALUES ('2f4941ec-2f6f-4c7f-8adc-c6f4fb002d42', 'albert', 'einstein');
```

If you are quick, you've already cottoned on that this one is possible, and it equates to:

A BulRequestMessage:-
1. ContinueOnError = false
2. Containing a CreateRequestMessage (to insert / create the contact)
3. Containing a RetrieveRequestMessage - to retrieve the "accountnumber" of target entity: '2f4941ec-2f6f-4c7f-8adc-c6f4fb002d42' 

## Let's start pushing the boat out a bit.
Here is a batch of T-SQL commands:

```sql
INSERT INTO contact (firstname, lastname) VALUES ('albert', 'einstein');
UPDATE contact SET lastname = 'Johnson' WHERE contactid = '3a4941ec-2f6f-4c7f-8adc-c6f4fb002d42';
DELETE FROM contact WHERE contactid = '4b4941ec-2f6f-4c7f-8adc-c6f4fb002d42'
```

Now, we know that SQL Server would execute that SQL, by executing each sql command within that batch in sequence, and if there were any errors it will not continue to process the rest of the commands in the same batch. It would also not execute that batch within a transaction, so it would not roll back should errors occur half way through etc.

This equates to:

A BulRequestMessage:-
1. ContinueOnError = false

Containing the following messages:
1. A CreateRequestMessage (to insert / create the contact)
2. An UpdateRequestMessage(to update the contact) 
3. A DeleteRequestMessage

It seems like this is a good fit between SQL and usage of a BulkRequestMessage.

## The boat is now heading towards the open ocean
Let's add a bit of complexity to the previous T-SQL - consider this:

```sql
INSERT INTO contact (contactid, firstname, lastname) OUTPUT inserted.accountnumber VALUES ('2f4941ec-2f6f-4c7f-8adc-c6f4fb002d42', 'albert', 'einstein');
UPDATE contact SET lastname = 'Johnson' WHERE contactid = '3a4941ec-2f6f-4c7f-8adc-c6f4fb002d42';
DELETE FROM contact WHERE contactid = '4b4941ec-2f6f-4c7f-8adc-c6f4fb002d42'
```

The first command in that batch of SQL commands is this:

```sql 
INSERT INTO contact (contactid, firstname, lastname) OUTPUT inserted.accountnumber VALUES ('2f4941ec-2f6f-4c7f-8adc-c6f4fb002d42', 'albert', 'einstein');
```

And we know that this actually equates to 2 seperate RequestMessages, a CreateRequest and a RetrieveRequest. We then also need to do an Update and a then a Delete. So this equates to:

A BulRequestMessage (ContinueOnError = false)

Containing:
1. A CreateRequestMessage (to insert / create the contact)
2. A RetrieveRequestMessage - to retrieve the "accountnumber" of target entity: '2f4941ec-2f6f-4c7f-8adc-c6f4fb002d42' 
3. An UpdateRequestMessage
4. A DeleteRequestMessage

Ok good so far.

## Should look at Boat Breakdown cover
Now consider this one:

INSERT INTO contact (firstname, lastname) OUTPUT inserted.accountnumber VALUES ('albert', 'einstein');
GO
DELETE FROM contact WHERE contactid = '6f4941ec-2f6f-4c7f-8adc-c6f4fb002d42'

What this says is:

1. We want to Insert a Contact, output its account number. 
2. We want to Delete a contact. This is regardless of whether any previous statements succeed or fail. So in this instance, we allways want to perform the Delete. This is indicated by the fact this Delete statement is in a seperate batch (indicated by the GO keyword, which is used as a batch seperator)

What this translates into is:

1. A CreateRequest that allways needs to be executed.
2. A RetreiveRequest (to retrieve the "accountnumber") which should only be executed if the preceeding CreateRequest succeeds.
3. A DeleteRequest that allways needs to be executed.

Can we construct the equivalent BulkRequestMessage?

Well.. the answer is.. we could semantically construct an appropriate BulkRequestMessage, but it won't be supported by CRM - because you are not allowed to nest BulkRequestMessages inside BulkRequestMessages - if you do the CRM server will throw an error when you send it such a request.

Here is what that looks like though (if only it was supported by the server!)

1. A BulRequestMessage (ContinueOnError = true) Containing:
    1. A BulkRequestMessage (ContinueOnError = false) Containing:
        1. A CreateRequest to create the contact
        2. A RetrieveRequestMessage - to retrieve the "accountnumber" of created entity 
    2. A DeleteRequestMessage
    
As I say, constructing such a Request is possible, but the CRM server won't process it due to current runtime limitations that are imposed about not allowing nested BulkRequestMessages.

So - unfrotuantely such a query is not currently possible in one round trip with the server.

But what you could do, is, client side, split that SQL on the GO keyword, to get each batch of commands. Then for each batch, send an appropriate BulkRequestMessage for that batch.

## Conclusion

The BulkRequestMessage provides the ability to send a single "batch" of commands to the server. Thinking from a SQL perspective, this is like to sending all the statements upto a given "GO" keyword. It will not support sending multiple batches in a single message to the server for processing.

If you need to send multiple batches of commands, it seems you will need to implement your own client side functionality that submits each "batch" as seperate BulkRequestMessage, and then, to get the same behaviour as SQL server, you would submit each batche / BulkRequestMessage in the correct sequential order, and would handle / each result / BulkResponsetMessage in the same sequential order.

















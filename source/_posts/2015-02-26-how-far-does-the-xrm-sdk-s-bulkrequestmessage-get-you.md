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
3. Containing a RetrieveRequestMessage - with the target entity id set to: '2f4941ec-2f6f-4c7f-8adc-c6f4fb002d42' and "accountnumber" specified as as an attribute to retrieve.

## More delving






## Unit Testing Crm Plugins - There Is No ~~Spoon~~ Crm!

The purpose of this post will be to look at the code for a fairly typical looking crm plugin, and examine how to implement a unit test with the least possible effort. Reduced Effort == Reduced Person Hours == Reduced Cost.

## A plugin - and it's requirements

Firstly, let's look at a plugin that we will call the `ReclaimCreditPlugin`. Here are the requirements:
 
> 1. It must run only within a transaction with the database.
2. When a Contact entity is Updated, if the contact has a parent account, and that parent account is "on hold" then set the "taketheirshoes" flag on the contact record to true.

## Developer Jon Doe

Jon Doe immediately gets to work on writing the plugin for those requirements. He produces the following plugin:

``` csharp
  public class ReclaimCreditPlugin : IPlugin
    {

        public void Execute(IServiceProvider serviceProvider)
        {

            var executionContext = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));

            // 1. We must run only within a transaction
            if (!executionContext.IsInTransaction)
            {
                throw new InvalidPluginExecutionException("The plugin detected that it was not running within a database transaction. The plugin requires a database transaction.");
            }

            // 2. Get the contact, check its parent account.
            if (executionContext.InputParameters.Contains("Target") && executionContext.InputParameters["Target"] is Entity)
            {
                // Obtain the target entity from the input parameters.
                var contactEntity = (Entity)executionContext.InputParameters["Target"];
                // Get the parent account id.
                var parentAccountId = (EntityReference)contactEntity["parentaccountid"];

                // Get the parent account entity.
                var orgServiceFactory = (IOrganizationServiceFactory)serviceProvider.GetService(typeof(IOrganizationServiceFactory));
                var orgService = orgServiceFactory.CreateOrganizationService(executionContext.UserId);
                var parentAccountEntity = orgService.Retrieve("account", parentAccountId.Id, new ColumnSet("creditonhold"));

                var accountOnHold = (bool)parentAccountEntity["creditonhold"];

                if (accountOnHold)
                {
                    contactEntity["taketheirshoes"] = true;
                    var tracingService = (ITracingService)serviceProvider.GetService(typeof(ITracingService));
                    tracingService.Trace("Have indicated that we should take the shoes from contact: {0}", contactEntity.Id.ToString());
                }

            }

        }

    }
    ```
    
### Good Job?
Take a moment to peer review the above code. Would you vindicate Jon Doe's effort? It seems it has all the correct logic in all the correct places. It appears he has covered the list of requirements?

So.. does it actually work?

## Does it work?

Listen.. if you want to start haemorrhaging money as an organisation, one way to find out if this code works is to immediately go through the process of deploying it to a QA environment, getting someone to test it manually, and then repeating that cycle of Dev --> Deployment --> QA as often as necessary, until the tester gives the thumbs up. 

If you want to go that route, feel free to skip the rest of this article. Otherwise read on, where sanity awaits!

## Show me a Unit Test Already!

Bad news for you. I could.. but I won't.

## Why won't you show me a unit test? 

In short, because I value my time. Just look at that code again for crying out loud! It's littered with dependencies on things that are only provided at runtime by Dynamics CRM - things like:

1. IServiceProvider
2. IPluginExecutionContext
3. IOrganizationServiceFactory
4. IOrganizationService
5. ITracingService

**WHAT THE HELL ARE ANY OF THESE THINGS TO DO WITH THE ACTUAL REQUIREMENTS THAT I _NEED_ TO TEST???**

Listen.. I read those requirements for this plugin. I read them atleast one thousand times. And I wrote them in fact. Here they are again:

> 1. It must run only within a transaction with the database.
2. When a Contact entity is Updated, if the contact has a parent account, and that parent account is "on hold" then set the "taketheirshoes" flag on the contact record to true.

So with that in mind, can you please show me the requirement dictating: `When a contact is updated, it is of upmost importance to us as a business that it looks at the `IPluginExecutionContext` and grabs the `IOrganizationServiceFactory.`

Or please show me where the requirements state: `When a contact is updated, the plugin absolutely must interact with the `IServiceProvider` because otherwise you know.. Our business just won't function anymore.

No my friends. The requirements do not say _any of that_. 

### Why is that a problem?

The problem is not obvious at first glance. It is definately technically possible to mock / fake all of those services at unit test time. You can use something like RhinoMocks or another Mocking library to mock out `IServiceProvider` for the purposes of your test. You would then have to mock out all the calls to IServiceProvider that are made, so that it returns your other 'mocked' services like a mock 'IPluginExecutionContext' etc etc - and down the rabbit hole you go.

The problem, is about _effort_. This approach, although technically possible, requires significant _effort_. You would have to mock a tonne of runtime services and interactions. We have to ask ourselves, is all that effort really necessary? Sometimes it may be, but most of the time, it isn't. In this instance it definately isn't and I will explain why.

## Let's use the requirements to write the plugin, in pseudo code.

With those requirements - forget everything you know about Dynamics Crm and write your ideal pseudo code that would implement those requirements. This is the actual logic we care about testing.

PSEUDO CODE:

```
if (!IsRunningInTransaction)
{
	Throw "Plugin requires a transaction."
}

If (IsUpdateOf("contact"))
{

var contact = GetTargetEntity();
var account = GetAccountForContact(contact);

var isOnHold = (bool)account["creditonhold"];
if(isOnHold)
{
 	contact["taketheirshoes"] = true;
}
```

## Look at that Pseudo Code -  Do you see _any_ runtime services?
Notice how it contains only the logic we really care about testing - the logic as described by the requirements. It doesn't contain needless fluff. No `IServiceProvider`, No `IPluginExecutionContext`. It looks very simple, very basic. If we could actually write a CRM plugin like this, it would be about 1.5 million times easier to test. Well we can.

## Isolating out dependencies is the key to unit testing.

Yes it's true folks you heard it here first. The less dependencies you utilise directly in your methods, the easier they are to unit test.

With this principle in mind, let's revisit our plugin and refactor it to remove some dependencies.

## New and Improved Plugin

``` csharp
 public class ReclaimCreditPlugin2 : IPlugin
    {

        private IServiceProvider _ServiceProvider;

        public void Execute(IServiceProvider serviceProvider)
        {
            _ServiceProvider = serviceProvider;
            Execute();
        }

        /// <summary>
        /// This is the method containing the business logic that we want to be able to assert at unit test time.
        /// </summary>
        public void Execute()
        {
            // 1. We must run only within a transaction
            if (IsInTransaction())
            {
                throw new InvalidPluginExecutionException("The plugin detected that it was not running within a database transaction. The plugin requires a database transaction.");
            }

            // 2. Get the contact
            var contact = GetTargetEntity();

            // 3. Get the Parent Account for the contact.
            var parentAccount = GetAccountEntity(contact);
            if (parentAccount == null)
            {
                return;
            }

            // 4. If creidt on hold, set taketheirshoes.
            var accountOnHold = (bool)parentAccount["creditonhold"];
            if (accountOnHold)
            {
                contact["taketheirshoes"] = true;
            }

        }

        /// <summary>
        /// Returns the parent account entity for the contact.
        /// </summary>
        /// <param name="contact"></param>
        /// <returns></returns>
        protected virtual Entity GetAccountEntity(Entity contact)
        {
            // Get the p[arent account id.
            var parentAccountId = (EntityReference)contact["parentaccountid"];

            // Get an instance of the IOrganisationService.
            var orgServiceFactory = (IOrganizationServiceFactory)_ServiceProvider.GetService(typeof(IOrganizationServiceFactory));
            var executionContext = (IPluginExecutionContext)_ServiceProvider.GetService(typeof(IPluginExecutionContext));
            var orgService = orgServiceFactory.CreateOrganizationService(executionContext.UserId);
            
            // Get the account entity, with only the column / attribute that we need.
            var parentAccountEntity = orgService.Retrieve("account", parentAccountId.Id, new ColumnSet("creditonhold"));
            return parentAccountEntity;
        }

        /// <summary>
        /// Returns the current "Target" entity that the plugin is executing against.
        /// </summary>
        /// <returns></returns>
        protected virtual Entity GetTargetEntity()
        {
            var context = (IPluginExecutionContext)_ServiceProvider.GetService(typeof(IPluginExecutionContext));
            if (context.InputParameters.Contains("Target") && context.InputParameters["Target"] is Entity)
            {
                var contactEntity = (Entity)context.InputParameters["Target"];
                return contactEntity;
            }

            return null;
        }

        /// <summary>
        /// Returns whether the plugin is currently enrolled within a database transaction.
        /// </summary>
        /// <returns></returns>
        protected virtual bool IsInTransaction()
        {
            var context = (IPluginExecutionContext)_ServiceProvider.GetService(typeof(IPluginExecutionContext));
            return context.IsInTransaction;
        }

    }
```

## What just happened?

I applied a technique called the [Extract and Override](http://taswar.zeytinsoft.com/2009/03/08/extract-and-override-refactoring-technique/) technique, to remove the concrete references to all of those CRM runtime only services from within the Execute method, and instead they are now referenced within virtual methods which can be overriden at unit test time.

For example rather than having the following code directly within the execute method:

```
  var executionContext = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));

            // 1. We must run only within a transaction
            if (!executionContext.IsInTransaction)
            {
```

It has been replaced by a call to virtual method:

``` chsarp
  	        if (IsInTransaction())
            {
            
            }
```

The IsInTransaction() method is virtual, and so can easily be overriden at test time to return a True or False value.

This means during test time, we no longer need to mock up an `IPluginExecutionContext` - or indeed _any_ of the Crm runtime services. We just need to override the various virtual methods and return appropriate values. 

## Ok so - Now will you show me a Unit Test??

Certainly Sir / Madame. Now that I can write one within a few minutes as opposed to a few hours, your wish is my command:-

For the purpose of our unit tests all we do, is create a class that derives from our original plugin class, but overrides the various virtual methods to provide different values at test time. 

``` csharp
 public class UnitTestableReclaimCreditPlugin : ReclaimCreditPlugin2
    {

        public UnitTestableReclaimCreditPlugin()
        {
            AccountIsOnHold = false;
            IsRunningInTransaction = false;
            ContactEntity = new Entity("contact");
        }

        protected override Entity GetTargetEntity()
        {
            ContactEntity["parentaccountid"] = new EntityReference("account", Guid.NewGuid());
            return ContactEntity;
        }

        protected override Entity GetAccountEntity(Entity contact)
        {
            var accountEntity = new Entity("account");
            accountEntity["creditonhold"] = AccountIsOnHold;
            return accountEntity;
        }

        protected override bool IsInTransaction()
        {
            return IsRunningInTransaction;
        }

        public bool AccountIsOnHold { get; set; }

        public bool IsRunningInTransaction { get; set; }

        public Entity ContactEntity { get; set; }

    }
```

## And here are the Unit Tests

```

 [TestFixture]
    public class ReclaimCreditPluginUnitTests
    {
        public ReclaimCreditPluginUnitTests()
        {

        }

        [ExpectedException(typeof(InvalidPluginExecutionException),
            ExpectedMessage = "The plugin detected that it was not running within a database transaction",
            MatchType = MessageMatch.Contains)]
        public void Should_Only_Run_Within_Transaction()
        {
            // arrange
            var sut = new UnitTestableReclaimCreditPlugin();
            sut.IsRunningInTransaction = false;

            // act 
            sut.Execute();

        }


        public void Should_Take_Shoes_When_Credit_On_Hold()
        {
            // arrange
            var sut = new UnitTestableReclaimCreditPlugin();
            sut.IsRunningInTransaction = true;
            sut.AccountIsOnHold = true;

            // act 
            sut.Execute();

            //assert
            Assert.That(sut.ContactEntity["taketheirshoes"], Is.EqualTo(true));

        }

        public void Should_Not_Take_Shoes_When_Credit_Not_On_Hold()
        {
            // arrange
            var sut = new UnitTestableReclaimCreditPlugin();
            sut.IsRunningInTransaction = true;
            sut.AccountIsOnHold = false;

            // act 
            sut.Execute();

            //assert
            Assert.That(sut.ContactEntity["taketheirshoes"], Is.Not.EqualTo(true));

        }
    }
```

## Wrapping Up

Just because it's technically possible to write a unit test for a plugin, doesn't mean you should just immediately plough on and do so. Sometimes, the intelligent thing to do is to examine the requirements, examine the plugin code, and be absolutely clear on what it is you want to cover in your tests. With that in mind, refactor the plugin code to isolate out any dependencies on CRM runtime services that you do not want test coverage for. Doing this can take some time, but can save you a lot more, and make your tests much less fragile. I would aslo reccommend a book on unit testing such as [The Art of Unit Testing](http://artofunittesting.com/) 














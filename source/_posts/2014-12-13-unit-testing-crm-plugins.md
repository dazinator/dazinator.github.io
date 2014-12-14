## Unit Testing Crm Plugins, Effort = Person Hours = $$.

The purpose of this post will be to look at the code for a fairly typical looking crm plugin, and examine how to implement a unit test for that plugin. We will then look at how we could write / refactor the plugin, with unit testing "in mind" - so that the effort of writing the unit test is significantly reduced. Reducing effort, reduces Effort == Person Hours == Money.

## A plugin - and it's requirements

Firstly, let's look at a plugin that we will call the `ReclaimCreditPlugin`. Here are the requirements:
 
1. It must run only within a transaction with the database.
2. When a Contact entity is Updated, if the contact has a parent account, and that parent account is "on hold" then set the "taketheirshoes" flag on the contact record to true.

I beleive this ficticious plugin to be a pretty decent example of a plugin, because it carries out the following tasks which are fairly typical:

1. Has some conditional logic in it 
2. Get's the current entity from `IPluginExecutionContext`
3. Get's the `IOrganizationService` using the `IOrganizationServiceFactory`
3. Retrieves another entity using the `IOrganizationService`
3. Updates an entity using the `IOrganizationService`

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
A peer review of the above code may no doubt vindicate Jon Doe's effort. It seems he has covered all of the requirements. So.. does it actually work?

### So.. does it actually work?

Well, if you wanted to start haemorrhaging some money as an organisation, one way to find out is to immediately go through the process of deploying the above plugin to a CRM environment, getting someone to test it manually, and then repeat that cycle of Dev --> Deployment --> QA as often as necessary, until the the tester gives the thumbs up. 

### We are smarter than that

However, we are smarter than that. We will write a unit test so that we can establish a minimum level of confidence in our code before we waste QA's time testing it. Our unit test can also be run as part of all future builds to detect any regressions in the code. 

This doesn't replace the need for a QA process, but it will set a bar on code quality irrespective of QA processes. It will also reduce the number of Dev --> QA cycles that have to be performed, and it will allow regressions to be caught automatically.

### 

1

Without writing a unit test for this plugin, the only way to tell if it works would be to go through the process of deployment, and to actually get someone to test it running within a Dynamics CRM system. If any bugs were found you would have to repeat that process for every code change, until QA gave the thumbs up. 

It's absolutely littered with dependencies. 

Guess what... it's absolutely littered with dependencies. Dependencies on services that Dynamics CRM provides at runtime, such as:  

1. IServiceProvider
2. IPluginExecutionContext
3. IOrganizationServiceFactory
4. IOrganizationService
5. ITracingService

### Why is that a problem?

The problem is not obvious at first glance. It is definately technically possible to mock / fake all of those services at unit test time. You can use something like RhinoMocks or another Mocking library to mock out `IServiceProvider` for the purposes of your test. You would then have to mock out all the calls to IServiceProvider that are made, so that it returns your other 'mocked' services like a mock 'IPluginExecutionContext' etc etc.

The problem, is about effort. This approach, although technically possible, requires significant effort. You would have to mock a tonne of runtime services and interactions. We have to ask ourselves, is all that effort really necessary? Sometimes it is, sometimes it isn't. In this instance it isn't and I will explain why.

### How do we make the unit testing for this plugin easier then? 

Let's define the requirements of the plugin and making sure they are crystal clear. 

### The Requirements 
For this plugin these are the requirements:

1. It must only run within a transaction with the database.
2. When a Contact is Updated, if the contact has a parent account, and that parent account is "on hold" then set the "taketheirshoes" flag on the contact record to true.

### Pseudo Code - 

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

## Look at that Pseudo Code - I can't see any runtime services?
Notice how our pseudo code which encapsulates the logic we really care about, doesn't contain any fluff. No `IServiceProvider`, No `IPluginExecutionContext`. It looks simple. This is the way things should be. Simple.

## Isolating out dependencies makes for simpler and easier unit testing.

Yes it's true folks you heard it here first. The less dependencies you utilise in your methods, the easier they are to test.

With this principle in mind, let's revist our plugin and refactor it to remove some dependencies.

## New and Improved Version of our plugin.

```

 public class ReclaimCreditPlugin2 : IPlugin
    {

        private IServiceProvider _ServiceProvider;

        public void Execute(IServiceProvider serviceProvider)
        {
            _ServiceProvider = serviceProvider;
            Execute();
        }

        /// <summary>
        /// This is the method contianing the business logic that we want to test. Notice how it closes matches our pseudo code.
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

        protected virtual Entity GetAccountEntity(Entity contact)
        {
            var parentAccountId = (EntityReference)contact["parentaccountid"];

            var orgServiceFactory = (IOrganizationServiceFactory)_ServiceProvider.GetService(typeof(IOrganizationServiceFactory));
            var executionContext = (IPluginExecutionContext)_ServiceProvider.GetService(typeof(IPluginExecutionContext));
            var orgService = orgServiceFactory.CreateOrganizationService(executionContext.UserId);

            var parentAccountEntity = orgService.Retrieve("account", parentAccountId.Id, new ColumnSet("creditonhold"));
            return parentAccountEntity;
        }

        protected virtual Entity GetTargetEntity()
        {
            var context = (IPluginExecutionContext)serviceProvider.GetService(typeof(IPluginExecutionContext));
            if (context.InputParameters.Contains("Target") && context.InputParameters["Target"] is Entity)
            {
                var contactEntity = (Entity)context.InputParameters["Target"];
                return contactEntity;
            }

            return null;
        }

        protected virtual bool IsInTransaction()
        {
            var context = (IPluginExecutionContext)_ServiceProvider.GetService(typeof(IPluginExecutionContext));
            return context.IsInTransaction;
        }

    }

```

## Huh what about all that crap?



How would we unit test the above plugin?

Well we would have to supply "mock" objects for all of the runtime services that the above code accesses. These include:



We would then have to implement all of the methods on those fake objects so at test time when those methods were called, they actually do something. For example:

```
orgService.Retrieve("account", parentAccountId.Id, new ColumnSet("creditonhold"));
```

At test time, that would translate into having a mock implementation of IOrganizationService, that 





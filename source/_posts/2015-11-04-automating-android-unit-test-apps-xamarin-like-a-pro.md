---
layout: post
comments: true
categories: ""
published: true
title: Automating Android Unit Test Apps (Xamarin) Like A Pro
---


## First Off..
This article is for those of you out there who use Xamarin to write Android applications. Moreoever, it's for those of you who also like to run automated tests. Even more specifically, it's for those of you who want to run your automated tests actually on an Android device..

I spent a couple of days figuring out how to get my Xamarin "Unit Tests" to autoamically run on an Android device during a CI build (Team City) with the test results reported nicely.

Here is the process I wanted:

1. Check some code in
2. CI Build Begins
3. Produces the APK file containing my tests.
4. Starts up an Emulator and boots an AVD
5. Installs the tests APK onto the Android Device (Emulated)
6. Kicks of the tests
7. Reports back the test results.
8. The tests all nicely appear in Team City.


## Unit Test App (Android) - and it's shortcomings.
It all begins with adding the unit tests project itself.
Xamarin have provided a project type in Visual Studio called a "Unit Test App". Add one of those projects to your Solution and define some tests. 

![New Android Unit Test Project.PNG]({{site.baseurl}}/assets/posts/New Android Unit Test Project.PNG)

Here are some tests:

```csharp
  [TestFixture]
    public class TestsSample
    {

        [SetUp]
        public void Setup() { }


        [TearDown]
        public void Tear() { }

        [Test]
        public void Pass()
        {
            Console.WriteLine("test1");
            Assert.True(true);
        }

        [Test]
        public void Fail()
        {
            Assert.False(true);
        }

        [Test]
        [Ignore("another time")]
        public void Ignore()
        {
            Assert.True(false);
        }

        [Test]
        public void Inconclusive()
        {
            Assert.Inconclusive("Inconclusive");
        }
    }

```

## Shortcomings of Running these tests

Naturally, you may be thinking how do you now run these tests? Well by default you have to manually run them. This is an app. Starting the tests project in VSis like starting any other Android application - it should deploy the APK to your Android device, and launch the app, which then shows a UI, and you must click various buttons on said UI to run the various tests that you want to run MANUALLY.

## An enormous pain in the ass..

This ofcourse, is a rediculous way forward and we need to get these automated ASAP!

## The short answer

The short answer, is that we need to take a few steps to get these tests automated.. Read on..

## Step 1 - The NuGet Package

I created a NuGet package called [TestyDroid](https://www.nuget.org/packages/Xamarin.TestyDroid/). You will want to add it to your solution. This NuGet package just contains a command line executable that does the following when called with suitable arguments:

- Starts an Android Emulator and boots up a specified AVD 
- Detects when the AVD has finished booting, and then Deploys the specified Tests APK package
- Kicks of the Tests contained within that package
- Collates the Results of the tests, and reports them via Standard Output, with option to report in TeamCity friendly format so that Team City displays the tests in the UI when it calls this exe during a build.
- Ensures the emulator is killed afterwards.

In order to write this tool, it's fair to say it has taken a fair bit of research and testing!

So - [Install the NuGet package](https://www.nuget.org/packages/Xamarin.TestyDroid/)

## Step 2

After that is installed, we need to address how these tests get "launched" in the first place.

Android has the concept of "Instruments"

Instruments are special classes, that can be launched via an intent, and can run tests.

So, in order to "start" the tests running on the Android device (after the APK) has been installed, we need to create this "Instrument" class in our tests project, and ensure it gets "Registered" when our app is installed. This way we can later run all of our tests by simply "launching" this instrument from the command line. 

You don't need to worry about this "Launching" or anything though. TestyDroid handles all that for you. All you need to do is create the Instrument.

Add the following class to your Tests project:

```csharp
namespace Xamarin.TestyDroid.TestTests
{
    [Instrumentation(Name = "xamarin.testydroid.testtests.TestInstrumentation")]
    public class TestInstrumentation : TestSuiteInstrumentation
    {   

        public TestInstrumentation(IntPtr handle, JniHandleOwnership transfer) : base(handle, transfer)
        {
        }

        protected override void AddTests()
        {
            AddTest(Assembly.GetExecutingAssembly());
        }
    }

}

```

Imortant to note (adjust the Namespace appropriately) - the Instrumentation Attribute above the class has a "Name" property. THIS IS VERY IMPORTANT. Make sure it matches the following:

The lower case namespace of the TestInstrumentation class + the Class Name of the TestInstrumentation class (Case sensitive)

So if you changed the namespace of this class to MyCoolApp.Tests
And you changed the Class Name of this class to MyCoolTestInstrumentation
Then the Attribute above the MyCoolTestInstrumentation class should look like this:

```csharp
 [Instrumentation(Name = "mycoolapp.tests.MyCoolTestInstrumentation")]
    public class MyCoolTestInstrumentation : TestSuiteInstrumentation
    {   
```


## Step 3 - Jot things down

We now need to make a note of a few variables as we will need these to automatically launch our tests with TestyDroid.

The first thing we need is the "class path" for your tests Instrument. This is "Name" value of the [Instrumentation] attribute in the previous step. For example: 

`xamarin.testydroid.testtests.TestInstrumentation`

The next thing we need is the Package name of your tests package. This you can grab from the `AndroidManifest.xml` file.

Here is mine:

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="Xamarin.TestyDroid.TestTests" android:versionCode="1" android:versionName="1.0">
	<uses-sdk />
	<application android:label="Xamarin.TestyDroid.TestTests" android:icon="@drawable/Icon"></application>
</manifest>
```

So the package name for my tests app is `Xamarin.TestyDroid.TestTests`

Now we need some more general paramaters about where things are on our environment:

1. The path to `Adb.exe` (this is in your android-sdk\platform-tools directory)
2. The path to `Emulator.exe` (this is in your android-sdk\tools directory)
3. The path to your Tests.APK file (I will give you a clue - it will probably be in your bin/release/ folder :)
4. The name of the AVD that you would like to be launched in the emulator and used to run the tests on.

Once you have these things, you are ready to try out running the tests automatically, from your local machine.

## Step 4 - Running things locally.

Armed with the information in the previous step:

1. Open up a command prompt.
2. CD to the tools directory of the Xamarin.TestyDroid nuget package you added to your solution earlier. It should be something like "..path to you solution/packages/Xamarin.TestyDroid.0.1.10/tools/"

Run `Xamarin.TestyDroid.exe` with the arguments it needs. 
You can look here for a breakdown of all the arguments: https://github.com/dazinator/Xamarin.TestyDroid - or just execute it with the `--help` argument to see the help screen.

Here is an example:

```
Xamarin.TestyDroid.exe -e "C:\Program Files (x86)\Android\android-sdk\tools\emulator.exe" -d "C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe" -f "src\MyTests\bin\Release\MyTests.apk-Signed.apk" -i "AVD_GalaxyNexus_ToolsForApacheCordova" -n "MyTests" -c "mytests.TestInstrumentation" -w 120
```

Substitute the argument values accordingly.

You should see output similar to the following:

```
Starting emulator: D:\android-sdk\tools\emulator.exe -avd Xamarin_Android_API_15 -port 5554 -no-boot-anim -prop emu.uuid=013b8394-db8d-4224-a36f-889ce164f74e

Waiting until: 04/11/2015 19:21:29 for device to complete boot up..

INSTRUMENTATION_RESULT: passed=1

INSTRUMENTATION_RESULT: skipped=1

INSTRUMENTATION_RESULT: inconclusive=1

INSTRUMENTATION_RESULT: failed=1

INSTRUMENTATION_CODE: 0

Killing device: emulator-5554
Sending kill command.
OK: killing emulator, bye bye

Emulator killed.

```

so what just happened?

The TestyDroid exe, started an emulator instance. Used ADB to monitor when it had finished booting. Then it installed the APK containing your tests onto the device. It then used the `adb shell am instrument` command to launch your Instrumentation class discussed earlier. It then analyses the STDOUT to formulate the test results. 

During test execution, the Xamarin `TestSuiteInstrumentation` class puts some general information about number of tests passing, failing etc into a `Bundle`. This `Bundle` is returned when the Instrumentation finishes executing, and it's contents are ultimately written to the STDOUT of the `adb shell am instrument` process. The `INSTRUMENTATION_RESULT` messages you see in the log are basically entries from this `Bundle`. 

For the time being, you will notice there isn't much test detail in the report - just the number of tests that passed etc - it doesn't display each individual test. I will come back to this later - as this is a limitation we can overcome.

## Step 5 - Running On Team City

Once you check these changes in, you should have Team City set up to fetch your latest changes and build your solution. I won't go into the detail of that here as there is plenty of information online about how to get running with Team City.

However, the important step is that you will need to add a couple of build steps to your Team City build.

1. An MSBUILD step to build your Tests project (csproj file) such that it outputs the APK
2. A command line step that calls out to Xamarin.TestyDroid.exe with the necessary arguments, such that TestyDroid will laucnh the emulator, run your tests, report the results, and terminate the emulator.

The first step is easy, but the important thing to remember is to set the target to SignAndroidPackage

![tc commandlineparams testydroid.PNG]({{site.baseurl}}/assets/posts/tc commandlineparams testydroid.PNG)

That will now take care of producing the APK in the output directory for your project during your team city build.

The second step to create is the one that actually runs the tests using TestyDroid!
The follwing screenshot shows setting up a Command line step to do this:
![tc testydroid commandlinestep.PNG]({{site.baseurl}}/assets/posts/tc testydroid commandlinestep.PNG)

## Step 6 - Admire your tests in Team City.. with a catch.
Now you can run a build - and if all is well - you should see your tests results added to a tests tab in Team City.

But wait.. there is a catch. Only the "Failed" tests show, and the rest of the tests are just made up names "Test 1" passed, "Test 2" passed etc.

This goes back to the point earlier that Xamarin TestSuiteInstrumentation only provides test details for tests that fail. Therefore TestyDroid simply makes tests up to report to team city in order to satisfy the summary aggregate information that "X tests passes", "X tests skipped" etc. This is the summary information you saw in the log output from earlier - i.e this:

```
INSTRUMENTATION_RESULT: passed=1

INSTRUMENTATION_RESULT: skipped=1

INSTRUMENTATION_RESULT: inconclusive=1

INSTRUMENTATION_RESULT: failed=1

INSTRUMENTATION_CODE: 0
```

So how can we improve this situation?

Well TestyDroid needs to get more granular information. We can do by making some modifications to our `TestInstrumentation` class from earlier.

Go back to your tests project and modify your `TestInstrumentation` class to look like the following:

```csharp
 [Instrumentation(Name = "xamarin.testydroid.testtests.TestInstrumentation")]
    public class TestInstrumentation : TestSuiteInstrumentation
    {

        public TestInstrumentation(IntPtr handle, JniHandleOwnership transfer) : base(handle, transfer)
        {
        }

        protected override void AddTests()
        {
            AddTest(Assembly.GetExecutingAssembly());
        }

        public override void Finish(Result resultCode, Bundle results)
        {
            if (results == null)
            {
                throw new InvalidOperationException("could not get results.");
            }
            // There is an internal class "AndroidRunner" with a public static method that returns it's instance.
            // Get this using reflection to get at test results.
            try
            {
                IDictionary<string, NUnit.Framework.Internal.TestResult> testResults = EnsureTestResults();
                AddResultsToBundle(testResults, results);
                // results.PutBoolean("##TestyDroidResultFormat", true);
            }
            catch (Exception e)
            {
                Log.Error("error getting results", e.ToString());
                throw;
            }


            base.Finish(resultCode, results);
        }

        private void AddResultsToBundle(IDictionary<string, TestResult> testResults, Bundle results)
        {

            var testResultsDoc = new XmlDocument();
            var testResultsElement = testResultsDoc.CreateElement("TestResults");
            testResultsDoc.AppendChild(testResultsElement);

            // now output desired format in bundle.
            foreach (var testResult in testResults.Values)
            {
                if (!testResult.HasChildren)
                {
                    var testElement = testResultsDoc.CreateElement("TestResult");
                    testResultsElement.AppendChild(testElement);

                    var nameAtt = testResultsDoc.CreateAttribute("Name");
                    nameAtt.Value = testResult.FullName;
                    testElement.Attributes.Append(nameAtt);

                    var statusAtt = testResultsDoc.CreateAttribute("Status");
                    statusAtt.Value = testResult.ResultState.Status.ToString();
                    testElement.Attributes.Append(statusAtt);

                    var durationAtt = testResultsDoc.CreateAttribute("Duration");
                    durationAtt.Value = testResult.Duration.ToString();
                    testElement.Attributes.Append(durationAtt);

                    var messageAtt = testResultsDoc.CreateAttribute("Message");
                    messageAtt.Value = testResult.Message;
                    testElement.Attributes.Append(messageAtt);

                    var labelAtt = testResultsDoc.CreateAttribute("Label");
                    labelAtt.Value = testResult.ResultState.Label;
                    testElement.Attributes.Append(labelAtt);

                    testElement.InnerText = testResult.StackTrace;                   

                }
            }

            var reportContents = testResultsDoc.OuterXml;
            results.PutString("##TestyDroidTestsReport", reportContents);           

        }

        private IDictionary<string, TestResult> EnsureTestResults()
        {
            var aType = typeof(TestSuiteInstrumentation);
            if (aType == null)
            {
                throw new InvalidOperationException("could not get aType.");
            }
            var assembly = aType.Assembly;
            if (assembly == null)
            {
                throw new InvalidOperationException("could not get assembly of atype.");
            }

            var androidRunnerType = assembly.GetType("Xamarin.Android.NUnitLite.AndroidRunner");
            if (androidRunnerType == null)
            {
                throw new InvalidOperationException("could not get Runner type.");
            }

            var prop = androidRunnerType.GetProperty("Runner", BindingFlags.Public | BindingFlags.Static);
            if (prop == null)
            {
                throw new InvalidOperationException("could not get Runner property.");
            }

            var objRunner = prop.GetValue(null, null);
            if (objRunner == null)
            {
                throw new InvalidOperationException("could not get Runner instance.");
            }

            var resultsProperty = objRunner.GetType().GetProperty("Results", BindingFlags.Public | BindingFlags.Static);
            if (resultsProperty == null)
            {
                throw new InvalidOperationException("could not get Results property from Runner instance.");
            }

            var testResults = (IDictionary<string, TestResult>)resultsProperty.GetValue(objRunner);
            return testResults;


        }
    }

```


What we are doing here, is using Reflection to get at the Xamarin `AndroidRunner` and then interating over the tests to build a more detailed report.

We then dump that report in the `Bundle` which like I said earlier, shows up in the STDOUT of the command used to execute the Instrument on the Android device (`adb shell am instrument`)

TestyDroid has some code that checks for the presence of this additional report, and if it finds it, it parses its report data from this instead. All of this means, when you next run your Team City build - all of your tests show up correctly!


## Any Questions?
I have been someone limited by time so this was fairly rushed together! If there is anything you would like me to elaborate on, please leave a comment below.

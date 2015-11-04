---
layout: post
comments: true
categories: ""
published: true
title: Automating Android Unit Test Apps (Xamarin) Like A Pro
---

## First Off..
This article is for those of you out there who use Xamarin to write Android applications. Moreoever, it's for those of you who also like to run automated tests. Even more specifically, it's for those of you who want to run your automated tests actually on an Android device..

I spent a couple of days figuring out how to get my Xamarin "Unit Tests" to run on an actual Android device, automatically, during a CI build (Team City) with the test results reported back into Team City.

Here is the process I wanted:

1. Check some code in
2. CI Build Begins
3.  Produces the APK file containing my tests.
4. Starts up an Emulator and boots an AVD
5. Installs the tests APK onto the Android Device (Emulated)
6. Kicks of the tests
7. Reports back the test results.
4. The tests all nicely appear in Team City.


## Unit Test App (Android) - and it's shortcomings.
It all begins with adding the unit tests project itself.
Xamarin have provided a project type in Visual Studio called a "Unit Test App". Add one of those projects to your Solution and define some tests. 

![New Android Unit Test Project.PNG]({{site.baseurl}}/source/assets/posts/New Android Unit Test Project.PNG)

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

Naturally, you may be thinking how do you now run these tests? Well by default you have to manually run. Starting the tests project in VS should deploy the APK to your Android device, and launch the app, which then shows a UI, and you must click buttons on said UI to run the various tests that you want to run MANUALLY.


## An enormous pain in the ass..

This ofcourse, is a rediculous way forward and we need to get these automated ASAP.

## The short answer

The short answer, is that we need to take a few steps to get these tests automated.

## Step 1 - The NuGet Package

I created a NuGet package called [TestyDroid](https://www.nuget.org/packages/Xamarin.TestyDroid/). You will want to add it to your solution. This NuGet package just contains a command line executable that does the following when called with suitable arguments:

- Starts an Android Emulator and boots up a specified AVD 
- Detects when the AVD has finished booting, and then Deploys the specified Tests APK package
- Kicks of the Tests contained within that package
- Collates the Results of the tests, and reports them via Standard Output, with option to report in TeamCity friendly format so that Team City displays the tests in the UI when it calls this exe during a build.
- Ensures the emulator is killed afterwards.

In order to write this tool, it took a fair bit of research and testing over the past few days!

So - [Install the NuGet package](https://www.nuget.org/packages/Xamarin.TestyDroid/)

## Step 2

After that is installed, we need to address how these tests get "launched" in the first place.

Android has the concept of "Instruments"

Instruments are special classes, that can be launched via an intent, and can run tests.

So, in order to "start" the tests running on the Android device (after the APK) has been installed, we need to create this "Instrument" class in our tests project, and ensure it gets "Registered" when our app is installed. This way we can later run all of our tests by simply "launching" this instrument. 

You don't need to worry about this "Launching" or anything though. TestyDroid handled that for you. All you need to do is the following:

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

Next, (adjust the Namespace appropriately) - the Instrumentation Attribute above the class has a "Name" property. THIS IS VERY IMPORTANT. Make sure it matches:

The lower case namespace of TestInstrumentation class + the Class Name of the TestInstrumentation class

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

1. The path to `Adb.exe`
2. The path to `Emulator.exe`
3. The path to your Tests.APK file (I will give you a clue - it will probably be in your bin/release/ folder :)
4. The name of the AVD that you would like to be launched in the emulator and used to run the tests on

Once you have these things, you are ready to try out running the tests automatically, from your local machine.

## Step 4 - Running things locally.

Armed with the information in the previous step, simply Run `Xamarin.TestyDroid.exe` with the arguments it needs. You can look here for a breakdown of all the arguments: https://github.com/dazinator/Xamarin.TestyDroid - or just execute it with the `--help` argument to see the help screen.

Here is an example:

```
Xamarin.TestyDroid.exe -e "C:\Program Files (x86)\Android\android-sdk\tools\emulator.exe" -d "C:\Program Files (x86)\Android\android-sdk\platform-tools\adb.exe" -f "src\MyTests\bin\Release\MyTests.apk-Signed.apk" -i "AVD_GalaxyNexus_ToolsForApacheCordova" -n "MyTests" -c "mytests.TestInstrumentation" -w 120
```

You should see output similar to the following:












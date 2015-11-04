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
3  Produces the APK file containing my tests.
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

```
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

This ofcourse, is a rediculous way forward. 










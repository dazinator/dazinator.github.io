---
layout: post
comments: true
categories: ""
published: true
title: "DnnPackager - Getting Started"
---

## Dnn Packager

In this post, I am going to show you how to get up and running with your DotNetNuke module / extension development, using DnnPackager.


## Tools of the Trade
I am using VS2015 Community Edition, but this should would equally well with previous versions.

## Installing DotNetNuke Locally
You will need a local instance of DotNetNuke website installed so that you have somewhere to deploy / run and debug your modules. There are plenty of tutorials out there that cover how to install a Dnn website so i am not going to cover this here. Once you have a working Dnn Website installed under your local IIS - please read on!

## Create a Project

Open Visual Studio, and Create a New "ASP.NET Empty Web Application" project. Make sure you select ".NET 4" or ".NET 4.5" from the drop down at the top.

![New Project]({{site.baseurl}}/source/assets/posts/NewAspNetProject.PNG)

Note: Create your project wherever you like - it does not need to be created in a particular directory like other approaches I have seen.

## Tweak Web Project

The reason we choose to create a web project in the previous step, is just so that we have appropriate context menu options in visual studio for things like adding javascript and ascx files etc. This is generally handy for Dnn module development. However our project can not actually run as a "standalone website" though - as we are developing a Dnn module - which can only be run within the context of the Dnn website that is hosting it. This approach will work equally well if you create other types of projects - for example you could create a new "Library" project instead, but then you wouldn't have those familiar menu options so you would have to add things like javascript files to your project by hand.

Select the project in Solution Explorer window, then in the properties window, change "Always Start When Debugging" to false.

![alwaysstartwhendebuggingfalse.PNG]({{site.baseurl}}/source/assets/posts/alwaysstartwhendebuggingfalse.PNG)

This will help later as it will prevent Visual Studio from needlessly trying to host your module project as its own website whenever you try and debug your module - which will be running in your local Dnn website instead.

## Add DnnPackager NuGet Package

Open the Package Manager Console (Tools --> NuGet Package Manager) and (With your project selected in the "Default Project" dropdown, type into it the following command and hit enter to install the DnnPackager NuGet package:

```
Install-Package DnnPackager
```

![NuGetConsoleAddDnnPackagerNuGet.PNG]({{site.baseurl}}/source/assets/posts/NuGetConsoleAddDnnPackagerNuGet.PNG)

This will add some new items to your project, and to your solution. I will cover what these are for later.

![ProjectAfterAddingDnnPackager.PNG]({{site.baseurl}}/source/assets/posts/ProjectAfterAddingDnnPackager.PNG)

## Build

We haven't written any Dnn Module code yet, but go ahead and build your project.
DnnPackager will step in during the build process, and create a Dnn installation zip for your module. If you open up your solution directory in Windows Explorer you should notice that there is an InstallPackages\ folder, and inside that - a zip file. This is the zip file that can be installed into a Dnn Website and will be used later to deploy your module.

## Dnn Sdk Assemblies

In order to proceed with Dnn development, we will actually need to add references to the Dnn assemblies. Depending on the version of DotNetNuke you want your extension to be compatible with will often determine what version of the Dnn assemblies you will need to reference.

For the sake of this blog post I am going to assume that you are going to target the latest version of Dnn at the time of writing which is Dnn 7.

Using the Package Manager Console again:

```
Install-Package DotNetNuke.Core
```

This should add a reference to the DotNetNuke assembly to your projects references:

![ReferencesAfterAddingDnnCore.PNG]({{site.baseurl}}/source/assets/posts/ReferencesAfterAddingDnnCore.PNG)

## Let's Create a Module!

Now we have got most of the setup out of the way, it's time to get cracking on a module!

First add a new User Control to the project. This is going to be our UI for our super cool DNN module.

![AddUserControl.PNG]({{site.baseurl}}/source/assets/posts/AddUserControl.PNG)

We then need to change our new User Control to make it inherit from `PortalModuleBase` rather than `System.Web.UI.UserControl`

So change this:

```csharp
namespace MySuperModule
{
    public partial class Default : System.Web.UI.UserControl
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }
    }
}
```

To this:

```
namespace MySuperModule
{
    public partial class Default : PortalModuleBase
    {
        protected void Page_Load(object sender, EventArgs e)
        {

        }
    }
}
```

## Making an awesome module

Further development of this super awesome module is beyond the scope of this post, so I am just going to make it display something really simple for the time being. There are [plenty of other resources](http://www.dnnsoftware.com/community-blog/cid/141749/dotnetnuke-module-development-101-5--hello-world-3-using-visual-studio-to-create-a-module) out there for learning about Dnn module development. For now let's simple make it display a hello world!















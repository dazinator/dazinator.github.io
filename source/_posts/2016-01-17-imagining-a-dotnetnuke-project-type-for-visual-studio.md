---
layout: post
comments: true
categories: ""
published: true
title: Imagining a DotNetNuke Project Type for Visual Studio
---

## Overview

When developing DotNetNuke extensions, developers typically use one of the existing Visual Studio Project Type's, for example - an ASP.NET Web Application project.

Even when using a Project Template such as Christoc's, the project template is still based upon one of the standard Visual Studio project types - usually an ASP.NET Web Application project.

However these Project Types do not "gel" well with DotNetNuke development in a number of areas:

1. Running the project in VS (clicking play) - wants to run the extensions as a Web Application, but this makes no sense for a Dnn extension - which we need to be run within a DotNetNuke host.
2. Deploying the extension - there is no support for that in the project system - you have to manually deploy your extensions to the Dnn instance.
3. Debugging the extension - you have to manually attach to process.
4. Adding new items to your project - it would be nice if there were a standard set of items you can add to a DotNetNuke extension project, thinks such as a "Module View" etc. This is where templates do tend to work nicely. It would be even better though, if these templates brought in any required references (as NuGet packages) as they were needed.

## Introducing the "DnnProj"

I am currently developing a new VS Project System explicitly for DotNetNuke development. The rest of the blog will describe my vision for how this will work.

## Installing the Project System

You would start by installing the VSIX package from the VS gallery. This will install the DotNetNuke project type, and make this project type available to you when you create new projects in VS.

## Create a New Project

You can now create a new "DotNetNuke" project type using Visual Studio.

TODO: screenshot

This creates your new project, which has it's own ".dnnproj" file.

Straight away, you can build your project, and an installation zip for your extension is output to the Output directory.

Also, it has automatically included the "DnnPackager" NuGet package.

### Adding Content

You can now add items to your project. If you "Add new item" - you can select from a number of item types. For example "Module View". 

When you add the new item, not only do the files get added to your project, but any required dependencies also get added as a NuGet package. For example, adding a Module View will autoamtically add the DotNetNuke NuGet package to your project if it hasn;t allready been added, because this is required for your project to compile. 

### Running and Debugging

Next to the debug button in the toolbar is a drop down listing your local DNN Websites. You must select the website you want to run the extension with. Once you have selected a website, this website will now be used for running and debugging purposes for your extension.

Clicking "Play" will

1. Build your extension
2. Deploy your extension to the currently selected Dnn website.
3. Attach the debugger to the currently selected Dnn website's worker process.

This is way better than previous workflows for Dnn development. All you have to do is click play and your module will be running and ready to debug. 




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

1. Running the project in VS (clicking play) - wants to run the extensions as a Web Application, but this makes no sense for a Dnn extension - which has to be hosted by the DotNetNuke website.
2. Deploying the extension - there is no support for that in the project system - you have to manually deploy your extensions to the Dnn instance.
3. Debugging the extension - you have to manually attach to process.
4. Adding new items to your project - it would be nice if there were a standard set of items you could add to a DotNetNuke extension project by default, likewise you can always extend this by creating your templates and sticking them in your "ItemTemplates" folder, but those templates would target the "DnnProjectType". Things such as a "Module View" etc. This is where templates do tend to work nicely. It would be even better though, if these templates brought in any required dependencies / references (as NuGet packages) as they were added.

So.. what if there was a new Project Type, one that was purpose built for DotNetNuke development?

## Introducing the "DnnProj"

I am currently developing a new VS Project System explicitly for DotNetNuke development. The rest of the blog will describe my vision for how this will work.

## Installing the Project System

You would start by installing the VSIX package from the VS gallery. This will install the DotNetNuke project type, and make this project type available to you when you create new projects in VS.

## Create a New Project

You can now create a new "DotNetNuke" project using Visual Studio.

![new dnn project.PNG]({{site.baseurl}}/assets/posts/new dnn project.PNG)

This creates your new project. It also imports the "DnnPackager" NuGet package automatically - something I have blogged about seperately.

![adding DnnPackager.PNG]({{site.baseurl}}/assets/posts/adding DnnPackager.PNG)

Your new project, has it's own ".dnnproj" file. This is a new project type and that's why it has its own file extension ".dnnproj".

![SolutionExplorer1.PNG]({{site.baseurl}}/assets/posts/SolutionExplorer1.PNG)

### Adding Content

You can now add items to your project. If you "Add new item" - you can select from a number of standard item templates. For example a "Module View". 

![AddModuleView.png]({{site.baseurl}}/assets/posts/AddModuleView.png)

When you add the new item, not only do the files get added to your project, but any required dependencies also get broguth in by the magical power of NuGet:

![AddingDotNetNukeCoreNuget.PNG]({{site.baseurl}}/assets/posts/AddingDotNetNukeCoreNuget.PNG)

In other words, you don't need to worry about adding any references, they will be bought in for you as you add items. Ofcourse, you are still free to add references to other dependencies you might have as normal. 

### Running and Debugging

When you want to run and debug your extension, for those of you that have read my previous blog about DnnPackager, you may recall that this could be accomplished via a command that you could enter in the Package Manager Console window and DnnPackager would handle the deployment and attaching the debugger.

Well that approach was only ever necessary because there was not any first class support within VS itself - i.e from the project system. We can now do better than that.

In VS, I am going to extend the debugging toolbar (where the "play" button is)

![debug toolbar.PNG]({{site.baseurl}}/assets/posts/debug toolbar.PNG)

You can see in the screenshot there is an empty dropdown at present, but this will list your DotNetNuke websites that you have on your local IIS. The first one in that list will be selected by default.

You may also notice there a new Debugger selected in that screenshot "Local Dnn Website".

All you need to do it click "Play" and it will:

1. Build your project to output the deployment zip.
2. Deploy your install zip to the Dnn website selected in the dropdown.
3. Attach the debugger to Dnn website's worker process that is selected in the dropwdown.
4. Launch a new browser window, navigated to that dnn websites home page.

Therefore, to use a different Dnn website as the host for running and debugging your module, you would just select that website in the drop down instead, before you click the "play" button.

This is going to wayyyy better than previous workflows for Dnn development. 

## What Now?

Well I am well into development if this at the moment, which is why I have been able to include some screenshots. However I am hitting hurdles with Microsoft's new Project System. This is my first attempt at developing a VS project type and I don't have any in roads with microsoft and therefore any real support. So all of this means, I am hoping I can pull it off, but I'm not through the woods yet. The (very) dark, mystical woods, of VS project type development.

I'd love to hear what others think of this, would you use such a system? How could it be better?




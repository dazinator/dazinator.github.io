---
layout: post
comments: true
categories: ""
published: true
title: The beginners guide to ASP.NET 5 projects
---


## ASP.NET 5 stands for A Sea of Packages.NET 5 

If you have just created an ASP.NET 5 project, and then felt somewhat lost, let me try and bring you up to speed.

## NPM - it's an important citizen
NPM is now a first class citizen of an ASP.NET 5 project.
It's a package manager - the Node Package Manager to be precise. You may be thinking it stands for "Not another Package Manager" - it doesn't - I checked.

Stop here and do yourself a favour - if you aren't familiar with NPM - go get familiar with it now, you will be seeing a lot of it in your ASP.NET 5 projects in the days to come.

##

## A Sea of tools, mainly Package Managers!

Let me break it down for you.
These are the tools you need to get familiar:

- Visual Studio 2015 (hopefully goes without saying). I am using the community edition.
- NPM. This is the package manager for programs that run on NodeJs. The ASP.NET 5 project system is integrated with NPM.
- Bower. This is also a package manager. It is distributed as an NPM package, but Bower specialises in package management for website dependencies such as javascript files and css. By default, ASP.NET 5 projects are set up to use Bower (Bower is installed as a dependency via NPM) and therefore there is a corresponding Bower.json file in your project which lists the Bower packages that your website depends upon - such as Jquery etc.
- JSPM. This is an alternative package manager to Bower for managing your website dependencies. By default ASP.NET 5 projects *are not* set up to use JSPM (they use Bower) - however, in the walktrhough I will show how to switch to using JSPM because JSPM is deemed as the superior package manager by Aurelia due to it's additional loader capabilities. This just means in addition to managing packages during development, it also offers a javascript file which your application uses at runtime, to be able to resolve those javascript dependencies and load them into your application when needed. This loader has all kinds of nice features, like automatic transpiling of ES6 javascript for example.
- Gulp. ASP.NET 5 projects are setup to use Gulp by default. You will see a corresponding `gulpfile.js` in your project. Gulp itself is an NPM package. 

## That's a lot of Package Mangers
Before ASP.NET 5 projects, VS developers primarily used NuGet as the package manager. Now we have NuGet and NPM, as well as Bower or Jspm.
Here is my guidance.
For .NET libraries such as log4net - NuGet is the defacto package manager.
For tooling, some tools will be NodeJS based - in which case you will find them on NPM. Some tools will be NuGet based so use NuGet. Gulp is a useful tool that is NPM based. MSBuild tasks however, is NuGet based.
Bower is good at what it does (managing javascript packages), it just isn't as complete of a solution as Jspm which t


The Aurelia tutorials do a nice job of explaining why JSPM is However, Aurelia recommend JSPM as it also provides a `loader` for loading your javascript dependencies at runtime via a call to `system.import` and some nice features like transpiling those scripts on the fly so you can use ES6. It's basically a package manager *plus* a package loader at runtime - which results in a more complete system than using Bower alone, it's less work for you overall.

## Setup

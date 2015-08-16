---
layout: post
comments: true
categories: ""
published: true
title: Aurelia and ASP.NET 5 MVC
---

## Creating an ASP.NET 5 Project and using Aurelia.

It took me a while to get up and running with ASP.NET 5 and Aurelia. The first part was just to understand the various tooling involved.

## Tools?

Let me give you a quick run down of the tooling involved:

- Visual Studio 2015 (hopefully goes without saying). I am using the community edition.
- NPM. This is the package manager for programs that run on the Nodejs framework. New ASP.NET 5 projects are integrated with NPM - so there is no avoiding this tool.
- Bower. This is also a package manager. It is distributed as an NPM package, but Bower specialises in package management for website dependencies such as javascript files and css. By default, new ASP.NET projects have Bower installed as an NPM dependency, and a corresponding Bower.json file which lists the Bower packages that your website depends upon - such as Jquery etc.
- JSPM. This is an alternative package manager to Bower for managing website dependencies. By default ASP.NET 5 projects *are not* set up to use JSPM (they use Bower). Aurelia reccomend using JSPM as it also provides a standards based `loader` which is basically a javascript file that you include in your own web application, and then when you need to load any required javascript dependencies, you can do using a call to `system.import`. It's basically package management, and also a way for you to load things into your web application, all in one - which means it's less work for you overall.

## Setup


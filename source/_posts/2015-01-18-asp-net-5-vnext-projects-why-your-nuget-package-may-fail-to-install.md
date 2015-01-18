---
layout: post
published: false
title: "ASP.NET 5 (vNext) Projects - Why your NuGet Package may fail to install.. "
comments: true
---

## Are you the author of a NuGet package - don't assume it will work with ASP.NET 5 (vNext) projects.

Over the past year or so, I have authored [a number of NuGet packages](https://www.nuget.org/packages?q=darrell.tunnell) - because, well... I am just an all around great guy.

Recently, [I was contacted by someone](http://stackoverflow.com/questions/27762659/error-while-adding-nuget-package-to-asp-net-vnext-project#comment44383264_27762659) who was trying to use one of my NuGet packages with an ASP.NET vNext project (Preview release). Not something I have tried before - and this is where things get a little interesting.

## When NuGet packages are installed into an ASP.NET vNext project - powershell scripts included in the package, are not run.

As most NuGet package authors will already know, it's a [standard feature of NuGet](http://docs.nuget.org/docs/creating-packages/creating-and-publishing-a-package#Automatically_Running_PowerShell_Scripts_During_Package_Installation_and_Removal) that you can include powershell scripts within your NuGet package, that will then be executed when your package is installed (or uninstalled) into a visual studio project / solution. 

Many NuGet packages out there currently use this feature. For example, one of my packages uses an `Install.ps1` powershell script to ensure that a necessary `msi` is installed on to the developers machine - which is necessary for the package to work.

The EntityFramework NuGet package uses it to enable all of those nice `Code First` powershell commands such as `Enable-Migrations` etc within the Package Manager Console.

I could easily list plenty more examples of packages that use this feature of NuGet.

Well [David Fowler](http://forums.asp.net/members/davidfowl.aspx ) (who's on the ASP.NET team) - seems to suggest that [ASP.NET v5 does not support running the packages powershell scripts when you install a NuGet package into an ASP.NET v5 project.](http://forums.asp.net/t/2027698.aspx?Error+while+adding+NuGet+package+to+ASP+NET+vNext+project) 

I wanted to confirm that with him a second time - because `that's a huge problem for some of my NuGet packages`, but as you will see from that thread, I am still awaiting a secondary confirmation of this - although his first answer seems pretty clear cut.

## Surely this is documented somewhere - or perhaps ASP.NET 5 offers an alternative mechanism for running tasks on installation / uninstallation of a NuGet package?
I have tried to look for more information. At the moment all I have to go on is David Fowlers response. If your NuGet package requires custom tasks to be performed in an `init`, `install` or `uninstall` ps1 script - then be prepared that it may not be supported in ASP.NET vNext - and also be prepared for the fact that there may not be any workaround. If this turns out the be the case for some of my NuGet packages I'll be left with a slightly bitter taste in my mouth. 

## So where from here?
I am generally really excited about ASP.NET 5. I love what the team are doing. However I beleive that the ASP.NET team really should put some guidance out there to the NuGet community, so that NuGet package authors can gain an understanding of how their packages might have to change to work in the context of ASP.NET 5 projects. 

It could be that package authors will need to add proviso's to certain packages that **This package does not work with ASP.NET 5 projects** - which would be a massive failing in my estmation, of the ASP.NET team, and perhaps NuGet org for allowing such a situation to arise.

My hope is that David Fowler or someone from the ASP.NET team will offer a clarification, insight, or workaround for this issue - or put some information out that explains which NuGet features they do and don't support and what the ramifications of these decisions are, to NuGet package authors.
---
layout: post
published: true
title: "ASP.NET 5 (vNext) - Dropping support of NuGet packages with powershell scripts?"
comments: true
---

## Are you the author of a NuGet package - don't assume it will work with ASP.NET 5 (vNext) projects.

Over the past year or so, I have authored [a number of NuGet packages](https://www.nuget.org/packages?q=darrell.tunnell) - because, well... I am just an all around great guy.

Recently, I was contacted by someone who was trying to use one of my NuGet packages with an ASP.NET vNext project (Preview release). Not something I have tried before - and this is where things get a little interesting.

## The apparant problem with ASP.NET (vNext) and NuGet packages..

As most NuGet package authors will already know, it's a [standard feature of NuGet](http://docs.nuget.org/docs/creating-packages/creating-and-publishing-a-package#Automatically_Running_PowerShell_Scripts_During_Package_Installation_and_Removal) that you can include powershell scripts within your NuGet package, that will then be run when your package is installed (or uninstalled) into a visual studio project / solution. 

Many NuGet packages out there currently use this feature. For example, one of mine uses an `Install.ps1` powershell script to ensure that a necessary `msi` is installed on to the developers machine - which is necessary for the package to work.

The EntityFramework NuGet package uses it to enable all of those nice `Code First` powershell commands such as `Enable-Migrations` etc within the Package Manager Console.

I could easily list plenty more examples of packages that use this feature of NuGet.

Well [David Fowler](http://forums.asp.net/members/davidfowl.aspx ) (who's on the ASP.NET team) - seems to suggest that [ASP.NET v5 does not support running those powershell scripts when you install a NuGet package into the project.](http://forums.asp.net/t/2027698.aspx?Error+while+adding+NuGet+package+to+ASP+NET+vNext+project) 

I wanted to confirm that with him a second time - because `that's a huge problem for some of my NuGet packages`, but as you will see from that thread, I am still awaiting a response - although his first answer seems pretty clear cut.

## Surely ASP.NET 5 offers an alternative mechanism then?
I have tried to look for one. I have searched but it doesn't look like it. If your NuGet package requires custom tasks to be performed in an `init`, `install` or `uninstall` ps1 script - I have yet to hear a suggestion from the ASP.NET 5 team on how one should go about getting those tasks to be executed within an ASP.NET 5 project scenario.
 

## So where from here?
I am generally really excited about ASP.NET 5. I love what the team are doing. However I beleive that the ASP.NET team really should put some guidance out there to the NuGet community, so that NuGet package authors can gain an understanding of how their package installation experience is effected by this lack of support in ASP.NET 5 projects for standard NuGet features.. It could be that authors will need to add proviso's to certain packages that **This package does not work with ASP.NET 5 projects** - which would be a massive failing in my estmation, of the ASP.NET team. 

My hope is that they will do something to address this in the near future, or at the minimum, put some information up that explains any ramifications of their decisions to NuGet package authors with respect to ASP.NET v5 support.



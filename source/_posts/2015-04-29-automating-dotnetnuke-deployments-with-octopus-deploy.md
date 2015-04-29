---
layout: post
published: true
title: Automating DotNetNuke deployments with Octopus Deploy
comments: true
---

## Automating DotNetNuke Deployments using Octopus Deploy

Because I am an awesome dude, i'll share with you how I automate dotnetnuke delivery / deployments. This works. It takes some effort to get this set up though, but it will be well worth it in the end.

First i'll explain the process for automating the deployment of the DotNetNuke website itself. Then I'll explain how you can automate the deployment of modules / extensions on a continous basis.

## Preparation work

1. Set up a brand new DotNetNuke website, and go through the install wizard until you are greeted with an empty default dotnetnuke website.
2. Stop the website. Create a NuGet package containing the website folder.
3. Put that on your internal NuGet feed.
4. Go to the dotnetnuke database, and generate the create scripts (with data).
5. Create a new console application that uses dbup to run the above sql scripts when it is executed (as described [here](http://dbup.github.io/)). Remember to replace things like server name etc in the sql scripts with appropriate $variablename$. Dbup can substitute $variablename$ in the sql scripts with their actual values (which you can pass through from Octopus) before it executes them.
6. Add [OctoPack](http://docs.octopusdeploy.com/display/OD/Using+OctoPack) to your Console Application so that it is packaged up into a NuGet package. Put this NuGet package on your internal NuGet feed.

You should now be in this position:

1. You have a DotNetNuke website (the website content) as a NuGet package on your feed.
2. You have the DotNetNuke database (as it appeared after a vanilla installation) pacakged up as an executable (DbUp based) within a NuGet package on your feed.

Now that's done:

1 Create a project in Octopus to deploy a "DotNetNuke" website. For the deployment process you will need the NuGet packages prepared previously. The deployment process should:

1. Create a website in IIS using the website NuGet package.
2. Create the database by executing the executable within the Database NuGet package.

There are lot's of things to remember when deploying dotnetnuke. I won't go into detail but things like:

1. Granting full permission to the app pool identity that the website runs under to the website folder.
2. Updating the portalalias table with appropriate access url.

... and other things. The Dnn install process has been covered elsewhere so I won't go into any further detail here.

## Congratulations (partly)

You should now be in a postion where you can roll out a DotNetNuke website via Octopus.. BUT WHAT ABOUT THE MODULES I'M DEVELOPING!! - I hear you exclaim.

## Automating Module Deployments

1. When you build your module projects (via build server etc) you want them packaged as DotNetNuke install packages, inside a NuGet deployment package, which is then published to your NuGet feed. You can use [DnnPackager](https://github.com/dazinator/DnnPackager) for this (which is something I created).

2. Create a console application, that can take a set of zip files, copy them to a given directory, and then call the DotNetNuke url to install packages. It should wait for a response from DotNetNuke, and should re-check the directory to see if any zips are still present. 

1. Create a NuGet package containing the DotNetNuke website. This is literally just the website folder that you would typically set up within IIS.




